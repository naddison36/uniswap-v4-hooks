// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Script.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {PoolManager} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolModifyPositionTest} from "@uniswap/v4-core/contracts/test/PoolModifyPositionTest.sol";
import {PoolSwapTest} from "@uniswap/v4-core/contracts/test/PoolSwapTest.sol";
import {PoolDonateTest} from "@uniswap/v4-core/contracts/test/PoolDonateTest.sol";

import {CounterHook, CounterFactory} from "../src/CounterFactory.sol";

/// @notice Forge script for deploying v4 & hooks to **anvil**
/// @dev This script only works on an anvil RPC because v4 exceeds bytecode limits
/// @dev and we also need vm.etch() to deploy the hook to the proper address
contract CounterScript is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();
        PoolManager poolManager = new PoolManager(500000);

        vm.broadcast();
        CounterFactory counterFactory = new CounterFactory();
        IHooks hook = counterFactory.deploy(poolManager);

        vm.startBroadcast();
        // Helpers for interacting with the pool
        new PoolModifyPositionTest(IPoolManager(address(poolManager)));
        new PoolSwapTest(IPoolManager(address(poolManager)));
        new PoolDonateTest(IPoolManager(address(poolManager)));
        vm.stopBroadcast();
    }
}
