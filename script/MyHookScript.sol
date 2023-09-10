// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Script.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {TestERC20} from "@uniswap/v4-core/contracts/test/TestERC20.sol";

import {MyHookFactory} from "../src/hooks/MyHook.sol";
import {TestPoolManager} from "../test/utils/TestPoolManager.sol";

/// @notice Forge script for deploying v4 & hooks to **anvil**
/// @dev This script only works on an anvil RPC because v4 exceeds bytecode limits
contract MyHookScript is Script, TestPoolManager {
    using CurrencyLibrary for Currency;

    PoolKey poolKey;
    uint256 privateKey;
    address signerAddr;

    function setUp() public {
        privateKey = vm.envUint("PRIVATE_KEY");
        signerAddr = vm.addr(privateKey);
        vm.startBroadcast(privateKey);

        TestPoolManager.initialize();

        // Deploy the hook
        MyHookFactory factory = new MyHookFactory();

        // Any changes to the MyHook contract will mean a different salt will be needed
        // so just starting from 0 in this script
        IHooks hook = IHooks(factory.mineDeploy(manager, 0));
        console.log("Deployed hook to address %s", address(hook));

        // Derive the key for the new pool
        poolKey = PoolKey(Currency.wrap(address(token0)), Currency.wrap(address(token1)), 3000, 60, hook);
        // Create the pool in the Uniswap Pool Manager
        manager.initialize(poolKey, SQRT_RATIO_1_TO_1);

        // Provide liquidity to the pool
        caller.addLiquidity(poolKey, signerAddr, -60, 60, 10e18);
        caller.addLiquidity(poolKey, signerAddr, -120, 120, 20e18);
        caller.addLiquidity(poolKey, signerAddr, TickMath.minUsableTick(60), TickMath.maxUsableTick(60), 30e18);

        vm.stopBroadcast();
    }

    function run() public {
        vm.startBroadcast(privateKey);

        // Perform a test swap
        caller.swap(poolKey, signerAddr, signerAddr, poolKey.currency0, 1e18);
        console.log("swapped token 0 for token 1");

        // Remove liquidity from the pool
        caller.removeLiquidity(poolKey, signerAddr, -60, 60, 4e18);
        console.log("removed liquidity");

        // Deposit token 0 to the pool manager
        // caller.deposit(address(token0), signerAddr, signerAddr, 6e18);

        vm.stopBroadcast();
    }
}
