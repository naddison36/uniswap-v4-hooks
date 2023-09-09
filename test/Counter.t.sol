// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {FeeLibrary} from "@uniswap/v4-core/contracts/libraries/FeeLibrary.sol";
import {Pool} from "@uniswap/v4-core/contracts/libraries/Pool.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey, PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {Deployers} from "@uniswap/v4-core/test/foundry-tests/utils/Deployers.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";

import {TestPoolManager} from "./utils/TestPoolManager.sol";
import {CounterHook, CounterFactory} from "../src/hooks/CounterHook.sol";
import {GenericRouter, GenericRouterLibrary} from "../src/router/GenericRouterLibrary.sol";

contract CounterTest is Test, TestPoolManager, Deployers, GasSnapshot {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using GenericRouterLibrary for GenericRouter;

    CounterHook hook;
    PoolKey poolKey;

    function setUp() public {
        // creates the pool manager, test tokens and generic routers
        TestPoolManager.initialize();

        // Deploy the CounterHook factory
        CounterFactory factory = new CounterFactory();
        // Use the factory to create a new CounterHook contract
        hook = CounterHook(factory.mineDeploy(manager));

        // Create the pool
        poolKey = PoolKey(
            Currency.wrap(address(token0)),
            Currency.wrap(address(token1)),
            FeeLibrary.HOOK_SWAP_FEE_FLAG | FeeLibrary.HOOK_WITHDRAW_FEE_FLAG | uint24(3000),
            60,
            IHooks(hook)
        );
        manager.initialize(poolKey, SQRT_RATIO_1_1);

        // Provide liquidity over different ranges to the pool
        router.addLiquidity(routerCallback, manager, poolKey, address(this), -60, 60, 10 ether);
        router.addLiquidity(routerCallback, manager, poolKey, address(this), -120, 120, 10 ether);
        router.addLiquidity(
            routerCallback,
            manager,
            poolKey,
            address(this),
            TickMath.minUsableTick(60),
            TickMath.maxUsableTick(60),
            10 ether
        );
    }

    function testAddLiquidity() public {
        router.addLiquidity(routerCallback, manager, poolKey, address(this), -60, 60, 10 ether);
    }

    function testCounterHookFees() public {
        // Check the hook fee
        (Pool.Slot0 memory slot0,,,) = manager.pools(poolKey.toId());
        console.log("swap fee %s", slot0.hookSwapFee);
        assertEq(slot0.hookSwapFee, 0x55);
        assertEq(slot0.hookWithdrawFee, 0x33);

        assertEq(manager.hookFeesAccrued(address(hook), poolKey.currency0), 0);
        assertEq(manager.hookFeesAccrued(address(hook), poolKey.currency1), 0);
    }

    function testCounterSwap() public {
        assertEq(hook.beforeSwapCounter(), 100);
        assertEq(hook.afterSwapCounter(), 200);

        // Perform a test swap
        router.swap(routerCallback, manager, poolKey, address(this), address(this), poolKey.currency0, 1e18);

        assertEq(hook.beforeSwapCounter(), 101);
        assertEq(hook.afterSwapCounter(), 201);

        assertGt(manager.hookFeesAccrued(address(hook), poolKey.currency0), 0);
        assertEq(manager.hookFeesAccrued(address(hook), poolKey.currency1), 0);
    }

    function testCounterSwapFromPoolManager() public {
        // Perform a deposit to the pool manager
        router.deposit(manager, address(token1), address(this), address(this), 2e18);

        // The tester needs to approve the router to spend their tokens in the Pool Manager
        manager.setApprovalForAll(address(router), true);
        assertTrue(manager.isApprovedForAll(address(this), address(router)));

        // Perform a test swap
        router.managerSwap(routerCallback, manager, poolKey, address(this), address(this), poolKey.currency1, 2e18);

        // Revoke the tester's approval of the router as anyone can send calls to the router
        manager.setApprovalForAll(address(router), false);
    }

    function testDepositToken0() public {
        assertEq(manager.balanceOf(address(this), uint160(address(token0))), 0);
        assertEq(manager.balanceOf(address(this), uint160(address(token1))), 0);

        // Perform a deposit to the pool manager
        router.deposit(manager, address(token0), address(this), address(this), 1e18);

        // Check tester's balance has been updated
        assertEq(manager.balanceOf(address(this), uint160(address(token0))), 1e18);
        assertEq(manager.balanceOf(address(this), uint160(address(token1))), 0);
    }

    function testWithdrawToken0() public {
        // Perform a deposit to the pool manager
        router.deposit(manager, address(token0), address(this), address(this), 10e18);
        assertEq(manager.balanceOf(address(this), uint160(address(token0))), 10e18);
        assertEq(manager.balanceOf(address(this), uint160(address(token1))), 0);

        // The tester needs to approve the router to spend their tokens in the Pool Manager
        manager.setApprovalForAll(address(router), true);

        router.withdraw(manager, address(token0), address(this), 6e18);

        manager.setApprovalForAll(address(router), false);

        assertEq(manager.balanceOf(address(this), uint160(address(token0))), 4e18);
        assertEq(manager.balanceOf(address(this), uint160(address(token1))), 0);
    }

    function testFlashLoan() public {
        // Perform a flash loan
        bytes memory callbackData = abi.encodeWithSelector(token0.balanceOf.selector, router);
        router.flashLoan(address(token0), manager, address(token0), 1e6, callbackData);
    }
}
