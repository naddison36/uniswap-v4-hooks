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

    function beforeModifyPosition(address, PoolKey calldata, IPoolManager.ModifyPositionParams calldata)
        external
        override
        returns (bytes4)
    {
        beforeModifyCounter++;
        emit BeforeModify(beforeModifyCounter);

        return BaseHook.beforeModifyPosition.selector;
    }

    function afterModifyPosition(address, PoolKey calldata, IPoolManager.ModifyPositionParams calldata, BalanceDelta)
        external
        override
        returns (bytes4)
    {
        afterModifyCounter++;
        emit AfterModify(afterModifyCounter);

        return BaseHook.afterModifyPosition.selector;
    }

    function beforeSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata)
        external
        override
        returns (bytes4)
    {
        beforeSwapCounter++;
        emit BeforeSwap(beforeSwapCounter);

        return BaseHook.beforeSwap.selector;
    }

    function afterSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, BalanceDelta)
        external
        override
        returns (bytes4)
    {
        afterSwapCounter++;
        emit AfterSwap(afterSwapCounter);

        return BaseHook.afterSwap.selector;
    }
}
