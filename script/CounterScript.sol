// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console} from "forge-std/console.sol";
import "forge-std/Script.sol";

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {PoolManager} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {FeeLibrary} from "@uniswap/v4-core/contracts/libraries/FeeLibrary.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolId.sol";

import {CounterHook, CounterFactory} from "../src/hooks/CounterHook.sol";
import {GenericRouter, GenericRouterLibrary} from "../src/router/GenericRouterLibrary.sol";
import {TestPoolManager} from "../test/utils/TestPoolManager.sol";

/// @notice Forge script for deploying v4 & hooks to **anvil**
/// @dev This script only works on an anvil RPC because v4 exceeds bytecode limits
contract CounterScript is Script, TestPoolManager {
    using GenericRouterLibrary for GenericRouter;

    PoolKey poolKey;
    uint256 privateKey;
    address signerAddr;

    function setUp() public {
        privateKey = vm.envUint("PRIVATE_KEY");
        signerAddr = vm.addr(privateKey);
        console.log("signer %s", signerAddr);
        console.log("script %s", address(this));
        vm.startBroadcast(privateKey);

        TestPoolManager.initialize();

        // Deploy the hook
        CounterFactory factory = new CounterFactory();

        // Deploy has to mine a salt to match the Uniswap hook flags so can use a lot of gas
        // If this counter script is executed against a new Anvil node,
        // the PoolManager address will be 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9.
        // The first salt from 0 to get the required address perfix is 471
        // so starting from that to not burn up too much gas.
        IHooks hook = IHooks(factory.mineDeploy(manager, 471));
        console.log("Deployed hook to address %s", address(hook));

        // Derive the key for the new pool
        poolKey = PoolKey(
            Currency.wrap(address(token0)),
            Currency.wrap(address(token1)),
            FeeLibrary.HOOK_SWAP_FEE_FLAG | FeeLibrary.HOOK_WITHDRAW_FEE_FLAG | 3000,
            60,
            hook
        );
        // Create the pool in the Uniswap Pool Manager
        manager.initialize(poolKey, SQRT_RATIO_1_TO_1);

        console.log("currency0 %s", Currency.unwrap(poolKey.currency0));
        console.log("currency1 %s", Currency.unwrap(poolKey.currency1));

        // Provide liquidity to the pool
        router.addLiquidity(routerCallback, manager, poolKey, signerAddr, -60, 60, 10 ether);
        router.addLiquidity(routerCallback, manager, poolKey, signerAddr, -120, 120, 10 ether);
        router.addLiquidity(
            routerCallback,
            manager,
            poolKey,
            signerAddr,
            TickMath.minUsableTick(60),
            TickMath.maxUsableTick(60),
            10 ether
        );

        vm.stopBroadcast();
    }

    function run() public {
        vm.startBroadcast(privateKey);

        // Perform a test swap
        router.swap(routerCallback, manager, poolKey, signerAddr, signerAddr, poolKey.currency0, 1e18);

        vm.stopBroadcast();
    }
}
