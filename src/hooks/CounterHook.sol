// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {IHookFeeManager} from "@uniswap/v4-core/contracts/interfaces/IHookFeeManager.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey, PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";

import {BaseFactory} from "../BaseFactory.sol";

contract CounterHook is BaseHook, IHookFeeManager {
    using PoolIdLibrary for PoolKey;

    uint256 public beforeSwapCounter = 100;
    uint256 public afterSwapCounter = 200;
    uint256 public beforeModifyCounter = 300;
    uint256 public afterModifyCounter = 400;

    event BeforeSwap(uint256 counter);
    event AfterSwap(uint256 counter);
    event BeforeModify(uint256 counter);
    event AfterModify(uint256 counter);

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return Hooks.Calls({
            beforeInitialize: false,
            afterInitialize: false,
            beforeModifyPosition: true,
            afterModifyPosition: true,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false
        });
    }

    /// @notice The interface for setting a fee on swap or fee on withdraw to the hook
    /// @dev This callback is only made if the Fee.HOOK_SWAP_FEE_FLAG or Fee.HOOK_WITHDRAW_FEE_FLAG in set in the pool's key.fee.
    function getHookFees(PoolKey calldata) external pure returns (uint24 fee) {
        // Swap fee is upper bits.
        // 20% fee as 85 = hex55 which is 5 in both directions. 1/5 = 20%
        // Withdraw fee is lower bits
        // 33% fee as 51 = hex33 which is 3 in both directions. 1/3 = 33%
        fee = 0x5533;
    }

    function getHookWithdrawFee(PoolKey calldata key) external view returns (uint8 fee) {}

    function beforeModifyPosition(
        address sender,
        PoolKey calldata,
        IPoolManager.ModifyPositionParams calldata,
        bytes calldata
    ) external override returns (bytes4 selector) {
        beforeModifyCounter++;
        emit BeforeModify(beforeModifyCounter);

        selector = BaseHook.beforeModifyPosition.selector;
    }

    function afterModifyPosition(
        address sender,
        PoolKey calldata,
        IPoolManager.ModifyPositionParams calldata,
        BalanceDelta,
        bytes calldata
    ) external override returns (bytes4 selector) {
        afterModifyCounter++;
        emit AfterModify(afterModifyCounter);

        selector = BaseHook.afterModifyPosition.selector;
    }

    function beforeSwap(address sender, PoolKey calldata, IPoolManager.SwapParams calldata, bytes calldata)
        external
        override
        returns (bytes4 selector)
    {
        beforeSwapCounter++;
        emit BeforeSwap(beforeSwapCounter);

        selector = BaseHook.beforeSwap.selector;
    }

    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) external override returns (bytes4 selector) {
        afterSwapCounter++;
        emit AfterSwap(afterSwapCounter);

        selector = BaseHook.afterSwap.selector;
    }
}

contract CounterFactory is BaseFactory {
    constructor()
        BaseFactory(
            address(
                uint160(
                    Hooks.BEFORE_MODIFY_POSITION_FLAG | Hooks.AFTER_MODIFY_POSITION_FLAG | Hooks.BEFORE_SWAP_FLAG
                        | Hooks.AFTER_SWAP_FLAG
                )
            )
        )
    {}

    function deploy(IPoolManager poolManager, bytes32 salt) public override returns (address) {
        return address(new CounterHook{salt: salt}(poolManager));
    }

    function _hashBytecode(IPoolManager poolManager) internal pure override returns (bytes32 bytecodeHash) {
        bytecodeHash = keccak256(abi.encodePacked(type(CounterHook).creationCode, abi.encode(poolManager)));
    }
}
