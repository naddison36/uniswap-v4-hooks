// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {Pool} from "@uniswap/v4-core/contracts/libraries/Pool.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey, PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {Deployers} from "@uniswap/v4-core/test/foundry-tests/utils/Deployers.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {HookTest} from "./utils/HookTest.sol";
import {CounterHook, CounterFactory} from "../src/CounterFactory.sol";

contract CounterTest is HookTest, Deployers, GasSnapshot {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    CounterHook hook;
    PoolKey poolKey;

    function setUp() public {
        // creates the pool manager, test tokens, and other utility routers
        HookTest.initHookTestEnv();

        // Deploy the CounterHook factory
        CounterFactory factory = new CounterFactory();
        // Use the factory to create a new CounterHook contract
        hook = CounterHook(factory.mineDeploy(manager));

        // Create the pool
        poolKey = PoolKey(currency0, currency1, 3000, 60, IHooks(hook));
        manager.initialize(poolKey, SQRT_RATIO_1_1);

        // Provide liquidity over different ranges to the pool
        addLiquidity(poolKey, -60, 60, 10 ether);
        addLiquidity(poolKey, -120, 120, 10 ether);
        addLiquidity(poolKey, TickMath.minUsableTick(60), TickMath.maxUsableTick(60), 10 ether);
    }

    function testCounterHookFee() public {
        // Check the hook fee
        (Pool.Slot0 memory slot0,,,) = manager.pools(poolKey.toId());
        // assertEq(slot0.hookSwapFee, 3000);
        assertEq(slot0.hookWithdrawFee, 0);

        assertEq(manager.hookFeesAccrued(address(hook), poolKey.currency0), 0);
        assertEq(manager.hookFeesAccrued(address(hook), poolKey.currency1), 0);
    }

    function testCounterHooks() public {
        assertEq(hook.beforeSwapCounter(), 100);
        assertEq(hook.afterSwapCounter(), 200);

        // Perform a test swap
        swap(poolKey, token0, 100);

        assertEq(hook.beforeSwapCounter(), 101);
        assertEq(hook.afterSwapCounter(), 201);

        // assertGt(manager.hookFeesAccrued(address(hook), poolKey.currency0), 0);
        // assertGt(manager.hookFeesAccrued(address(hook), poolKey.currency1), 0);
    }
}
