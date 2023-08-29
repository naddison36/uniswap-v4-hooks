// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IDynamicFeeManager} from "@uniswap/v4-core/contracts/interfaces/IDynamicFeeManager.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {PoolKey, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";

import {BaseFactory} from "../BaseFactory.sol";

contract DynamicFeeHook is BaseHook, IDynamicFeeManager {
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

    function getFee(PoolKey calldata key) external returns (uint24 fee) {
        // insert hook logic here
        fee = 3000;
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
}

contract DynamicFeeFactory is BaseFactory {
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
        return address(new DynamicFeeHook{salt: salt}(poolManager));
    }

    function _hashBytecode(IPoolManager poolManager) internal pure override returns (bytes32 bytecodeHash) {
        bytecodeHash = keccak256(abi.encodePacked(type(DynamicFeeHook).creationCode, abi.encode(poolManager)));
    }
}
