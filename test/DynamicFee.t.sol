// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {FeeLibrary} from "@uniswap/v4-core/contracts/libraries/FeeLibrary.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {PoolKey, PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {Deployers} from "@uniswap/v4-core/test/foundry-tests/utils/Deployers.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {Pool} from "@uniswap/v4-core/contracts/libraries/Pool.sol";

import {TestPoolManager} from "./utils/TestPoolManager.sol";
import {DynamicFeeHook, DynamicFeeFactory} from "../src/DynamicFeeFactory.sol";
import {GenericRouter, GenericRouterLibrary} from "../src/router/GenericRouterLibrary.sol";

contract DynamicFeeTest is Test, TestPoolManager, Deployers, GasSnapshot {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using GenericRouterLibrary for GenericRouter;

    DynamicFeeHook hook;
    PoolKey poolKey;

    function setUp() public {
        // creates the pool manager, test tokens and generic routers
        TestPoolManager.initialize();

        // Deploy the factory contract
        DynamicFeeFactory factory = new DynamicFeeFactory();
        // Use the factory to create a new hook contract
        hook = DynamicFeeHook(factory.mineDeploy(manager));

        // Create the pool
        poolKey = PoolKey(
            Currency.wrap(address(token0)),
            Currency.wrap(address(token1)),
            FeeLibrary.DYNAMIC_FEE_FLAG,
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

    function testMintPoolManager() public {
        uint256 mintAmount = 100;

        router.mint(manager, poolKey.currency1, mintAmount);
    }

    function testHookFee() public {
        // Check the hook fee
        (Pool.Slot0 memory slot0,,,) = manager.pools(poolKey.toId());
        // assertEq(slot0.hookSwapFee, FeeLibrary.DYNAMIC_FEE_FLAG);
        assertEq(slot0.hookWithdrawFee, 0);

        assertEq(manager.hookFeesAccrued(address(hook), poolKey.currency0), 0);
        assertEq(manager.hookFeesAccrued(address(hook), poolKey.currency1), 0);
    }

    function testSwap0_1() public {
        // Swap token0 for token1
        bytes[] memory results =
            router.swap(routerCallback, manager, poolKey, address(this), address(this), poolKey.currency0, 100);

        // Check settle result
        BalanceDelta delta = abi.decode(results[0], (BalanceDelta));
        assertEq(delta.amount0(), 100);
        assertEq(delta.amount1(), -98);

        // assertGt(manager.hookFeesAccrued(address(hook), poolKey.currency0), 0);
        // assertEq(manager.hookFeesAccrued(address(hook), poolKey.currency1), 0);
    }

    function testSwap1_0() public {
        // Swap token1 for token0
        bytes[] memory results =
            router.swap(routerCallback, manager, poolKey, address(this), address(this), poolKey.currency1, 100);

        // Check settle result
        BalanceDelta delta = abi.decode(results[0], (BalanceDelta));
        assertEq(delta.amount0(), -98);
        assertEq(delta.amount1(), 100);
    }

    function testImbalancedAdd() public {
        router.addLiquidity(routerCallback, manager, poolKey, address(this), -60, 0, 10 ether);
        router.addLiquidity(routerCallback, manager, poolKey, address(this), 0, 120, 10 ether);
        router.addLiquidity(routerCallback, manager, poolKey, address(this), 60, 180, 10 ether);
    }

    function testSwap1_0_tilt0() public {
        router.addLiquidity(routerCallback, manager, poolKey, address(this), 0, 60, 10 ether);

        // Swap token1 for token0
        bytes[] memory results =
            router.swap(routerCallback, manager, poolKey, address(this), address(this), poolKey.currency1, 100);

        // Check settle result
        BalanceDelta delta = abi.decode(results[0], (BalanceDelta));
        // assertEq(delta.amount0(), -98);
        // assertEq(delta.amount1(), 100);
    }
}
