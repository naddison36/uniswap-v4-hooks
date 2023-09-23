// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey, PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";
import {FeeLibrary} from "@uniswap/v4-core/contracts/libraries/FeeLibrary.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {BaseFactory} from "../BaseFactory.sol";

contract HookCoin is BaseHook, ERC20, Initializable {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    uint160 public constant SQRT_RATIO_1_TO_1 = 79228162514264337593543950336;
    bytes4 private constant DEPOSIT_SELECTOR = bytes4(keccak256(bytes("deposit(uint256)")));
    bytes4 private constant WITHDRAW_SELECTOR = bytes4(keccak256(bytes("withdraw(address,uint256)")));
    uint24 public SWAP_FEE = 500; // 0.05% or 5 bps

    // TODO change to immutable set in constructor
    int24 public constant tickLower = -10;
    int24 public constant tickUpper = 10;

    PoolKey public poolKey;

    ////////////////////////////////////////////////////////////////
    //                      Setup
    ////////////////////////////////////////////////////////////////

    constructor(IPoolManager _poolManager, string memory name, string memory symbol)
        BaseHook(_poolManager)
        ERC20(name, symbol)
    {
        // Create the pool key for the HookCoin/ETH pool
        poolKey = PoolKey(
            Currency.wrap(address(this)),
            CurrencyLibrary.NATIVE,
            FeeLibrary.HOOK_SWAP_FEE_FLAG | FeeLibrary.HOOK_WITHDRAW_FEE_FLAG | SWAP_FEE,
            tickUpper,
            IHooks(address(this))
        );
    }

    function initialize() external initializer {
        poolManager.initialize(poolKey, SQRT_RATIO_1_TO_1, "");
    }

    ////////////////////////////////////////////////////////////////
    //                      Deposit
    ////////////////////////////////////////////////////////////////

    // deposit takes ETH and mints twice the amount HookCoin tokens
    // the ETH and half the minted HookCoins is deposited into the Uniswap pool
    // the other half of the minted HookCoins is sent to the caller
    function deposit(address _recipient) external payable {
        _deposit(_recipient);
    }

    function deposit() external payable {
        _deposit(msg.sender);
    }

    function _deposit(address _recipient) internal {
        // mint the same amount of ETH to send to the pool
        _mint(address(this), msg.value);

        // Acquire lock can call the deposit callback
        poolManager.lock(abi.encodeWithSelector(DEPOSIT_SELECTOR, msg.value));

        // mint the same amount of ETH to the sender
        _mint(_recipient, msg.value);
    }

    function _depositCallback(bytes calldata data) internal {
        uint256 amount = abi.decode(data, (uint256));

        IPoolManager.ModifyPositionParams memory params =
            IPoolManager.ModifyPositionParams(tickLower, tickUpper, int256(amount));

        BalanceDelta delta = poolManager.modifyPosition(poolKey, params, "");

        // transfer the minted HookCoin tokens to the pool manager
        _transfer(address(this), address(poolManager), uint128(delta.amount0()));
        // Settle the HookCoin tokens
        poolManager.settle(Currency.wrap(address(this)));

        // transfer ETH to the pool manager
        CurrencyLibrary.NATIVE.transfer(address(poolManager), uint128(delta.amount1()));
        // Settle the ETH
        poolManager.settle(CurrencyLibrary.NATIVE);
    }

    ////////////////////////////////////////////////////////////////
    //                      Withdraw
    ////////////////////////////////////////////////////////////////

    function withdraw(address _recipient, uint256 amount) external {
        _withdraw(msg.sender, _recipient, amount);
    }

    function _withdraw(address _owner, address _recipient, uint256 _amount) internal {
        // burn the owner's HookCoin tokens
        _burn(_owner, msg.value);

        // Acquire lock can call the deposit callback
        poolManager.lock(abi.encodeWithSelector(WITHDRAW_SELECTOR, _recipient, msg.value));

        // Burn the HookCoin tokens received from the pool
        _burn(address(this), msg.value);
    }

    function _withdrawCallback(bytes calldata data) internal {
        (address recipient, uint256 amount) = abi.decode(data, (address, uint256));

        IPoolManager.ModifyPositionParams memory params =
            IPoolManager.ModifyPositionParams(tickLower, tickUpper, -1 * int256(amount));

        poolManager.modifyPosition(poolKey, params, "");

        // Tak the HookCoin tokens from the pool manager
        poolManager.take(Currency.wrap(address(this)), address(this), amount);
        // Transfer the ETH to the recipient
        poolManager.take(CurrencyLibrary.NATIVE, recipient, amount);
    }

    ////////////////////////////////////////////////////////////////
    //                  Pool Manager Callback
    ////////////////////////////////////////////////////////////////

    function lockAcquired(bytes calldata data) external override poolManagerOnly returns (bytes memory) {
        bytes4 selector = bytes4(data);
        if (selector == DEPOSIT_SELECTOR) {
            _depositCallback(data);
        } else if (selector == WITHDRAW_SELECTOR) {
            _withdrawCallback(data);
        } else {
            revert("invalid callback");
        }
    }

    ////////////////////////////////////////////////////////////////
    //                      Hooks overrides
    ////////////////////////////////////////////////////////////////

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return Hooks.Calls({
            beforeInitialize: true,
            afterInitialize: false,
            beforeModifyPosition: false,
            afterModifyPosition: false,
            beforeSwap: false,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false
        });
    }

    function beforeInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96, bytes calldata data)
        external
        override
        returns (bytes4 selector)
    {
        require(totalSupply() == 0, "must have zero supply");

        selector = BaseHook.beforeInitialize.selector;
    }
}

contract HookCoinFactory is BaseFactory {
    constructor() BaseFactory(address(uint160(Hooks.BEFORE_INITIALIZE_FLAG))) {}

    function deploy(IPoolManager poolManager, bytes32 salt) public override returns (address) {
        return address(new HookCoin{salt: salt}(poolManager, "HookCoin", "HC"));
    }

    function _hashBytecode(IPoolManager poolManager) internal pure override returns (bytes32 bytecodeHash) {
        bytecodeHash = keccak256(abi.encodePacked(type(HookCoin).creationCode, abi.encode(poolManager)));
    }
}
