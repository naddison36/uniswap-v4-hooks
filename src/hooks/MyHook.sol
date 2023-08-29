// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {IHookFeeManager} from "@uniswap/v4-core/contracts/interfaces/IHookFeeManager.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey, PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";

import {BaseFactory} from "../BaseFactory.sol";

contract MyHook is BaseHook, IHookFeeManager {
    using PoolIdLibrary for PoolKey;

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return Hooks.Calls({
            beforeInitialize: true,
            afterInitialize: true,
            beforeModifyPosition: true,
            afterModifyPosition: true,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: true,
            afterDonate: true
        });
    }

    function beforeInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96)
        external
        override
        returns (bytes4 selector)
    {
        // insert hook logic here

        selector = BaseHook.beforeInitialize.selector;
    }

    function afterInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96, int24 tick)
        external
        override
        returns (bytes4 selector)
    {
        // insert hook logic here

        selector = BaseHook.afterInitialize.selector;
    }

    function beforeModifyPosition(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyPositionParams calldata params
    ) external override returns (bytes4 selector) {
        // insert hook logic here

        selector = BaseHook.beforeModifyPosition.selector;
    }

    function afterModifyPosition(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyPositionParams calldata params,
        BalanceDelta delta
    ) external override returns (bytes4 selector) {
        // insert hook logic here

        selector = BaseHook.afterModifyPosition.selector;
    }

    function beforeSwap(address sender, PoolKey calldata key, IPoolManager.SwapParams calldata params)
        external
        override
        returns (bytes4 selector)
    {
        // insert hook logic here

        selector = BaseHook.beforeSwap.selector;
    }

    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta
    ) external override returns (bytes4 selector) {
        // insert hook logic here

        selector = BaseHook.afterSwap.selector;
    }

    function beforeDonate(address sender, PoolKey calldata key, uint256 amount0, uint256 amount1)
        external
        override
        returns (bytes4 selector)
    {
        // insert hook logic here

        selector = BaseHook.beforeDonate.selector;
    }

    function afterDonate(address sender, PoolKey calldata key, uint256 amount0, uint256 amount1)
        external
        override
        returns (bytes4 selector)
    {
        // insert hook logic here

        selector = BaseHook.afterDonate.selector;
    }

    function getHookSwapFee(PoolKey calldata key) external view returns (uint8 fee) {
        fee = 0;
    }

    function getHookWithdrawFee(PoolKey calldata key) external view returns (uint8 fee) {
        fee = 0;
    }
}

contract MyHookFactory is BaseFactory {
    constructor()
        BaseFactory(
            address(
                uint160(
                    Hooks.BEFORE_INITIALIZE_FLAG | Hooks.AFTER_INITIALIZE_FLAG | Hooks.BEFORE_MODIFY_POSITION_FLAG
                        | Hooks.AFTER_MODIFY_POSITION_FLAG | Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
                        | Hooks.BEFORE_DONATE_FLAG | Hooks.AFTER_DONATE_FLAG
                )
            )
        )
    {}

    function deploy(IPoolManager poolManager, bytes32 salt) public override returns (address) {
        return address(new MyHook{salt: salt}(poolManager));
    }

    function _hashBytecode(IPoolManager poolManager) internal pure override returns (bytes32 bytecodeHash) {
        bytecodeHash = keccak256(abi.encodePacked(type(MyHook).creationCode, abi.encode(poolManager)));
    }
}
