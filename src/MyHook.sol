// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey, PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";

contract MyHook is BaseHook {
    using PoolIdLibrary for PoolKey;

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
        // insert hook logic here

        return BaseHook.beforeModifyPosition.selector;
    }

    function afterModifyPosition(address, PoolKey calldata, IPoolManager.ModifyPositionParams calldata, BalanceDelta)
        external
        override
        returns (bytes4)
    {
        // insert hook logic here

        return BaseHook.afterModifyPosition.selector;
    }

    function beforeSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata)
        external
        override
        returns (bytes4)
    {
        // insert hook logic here

        return BaseHook.beforeSwap.selector;
    }

    function afterSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, BalanceDelta)
        external
        override
        returns (bytes4)
    {
        // insert hook logic here

        return BaseHook.afterSwap.selector;
    }
}
