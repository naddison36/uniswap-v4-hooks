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
import {DynamicFeeHook, DynamicFeeFactory} from "../src/hooks/DynamicFeeHook.sol";

contract DynamicFeeTest is Test, TestPoolManager, Deployers, GasSnapshot {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

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
        caller.addLiquidity(poolKey, address(this), -60, 60, 10 ether);
        caller.addLiquidity(poolKey, address(this), -120, 120, 10 ether);
        caller.addLiquidity(poolKey, address(this), TickMath.minUsableTick(60), TickMath.maxUsableTick(60), 10 ether);
    }

    function testDepositToken0() public {
        caller.deposit(address(token0), address(this), address(this), 1e18);
    }

    function testDepositToken1() public {
        caller.deposit(address(token1), address(this), address(this), 1e18);
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
        bytes[] memory results = caller.swap(poolKey, address(this), address(this), poolKey.currency0, 100);

        // Check settle result
        BalanceDelta delta = abi.decode(results[0], (BalanceDelta));
        assertEq(delta.amount0(), 100);
        assertEq(delta.amount1(), -98);

        // assertGt(manager.hookFeesAccrued(address(hook), poolKey.currency0), 0);
        // assertEq(manager.hookFeesAccrued(address(hook), poolKey.currency1), 0);
    }

    function testSwap1_0() public {
        // Swap token1 for token0
        bytes[] memory results = caller.swap(poolKey, address(this), address(this), poolKey.currency1, 100);

        // Check settle result
        BalanceDelta delta = abi.decode(results[0], (BalanceDelta));
        assertEq(delta.amount0(), -98);
        assertEq(delta.amount1(), 100);
    }

    function testImbalancedAdd() public {
        caller.addLiquidity(poolKey, address(this), -60, 0, 10 ether);
        caller.addLiquidity(poolKey, address(this), 0, 120, 10 ether);
        caller.addLiquidity(poolKey, address(this), 60, 180, 10 ether);
    }

    function testSwap1_0_tilt0() public {
        caller.addLiquidity(poolKey, address(this), 0, 60, 10 ether);

        // Swap token1 for token0
        bytes[] memory results = caller.swap(poolKey, address(this), address(this), poolKey.currency1, 100);

        // Check settle result
        BalanceDelta delta = abi.decode(results[0], (BalanceDelta));
        assertEq(delta.amount0(), -98);
        assertEq(delta.amount1(), 100);
    }
}
