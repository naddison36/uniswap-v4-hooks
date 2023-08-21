// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey, PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";

contract CounterHook is BaseHook {
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

    function beforeModifyPosition(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyPositionParams calldata params
    ) external override returns (bytes4 selector) {
        beforeModifyCounter++;
        emit BeforeModify(beforeModifyCounter);

        selector = BaseHook.beforeModifyPosition.selector;
    }

    function afterModifyPosition(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyPositionParams calldata params,
        BalanceDelta delta
    ) external override returns (bytes4 selector) {
        afterModifyCounter++;
        emit AfterModify(afterModifyCounter);

        selector = BaseHook.afterModifyPosition.selector;
    }

    function beforeSwap(address sender, PoolKey calldata key, IPoolManager.SwapParams calldata params)
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
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta
    ) external override returns (bytes4 selector) {
        afterSwapCounter++;
        emit AfterSwap(afterSwapCounter);

        selector = BaseHook.afterSwap.selector;
    }
}
