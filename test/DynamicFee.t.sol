// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {FeeLibrary} from "@uniswap/v4-core/contracts/libraries/FeeLibrary.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey, PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {Deployers} from "@uniswap/v4-core/test/foundry-tests/utils/Deployers.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {Pool} from "@uniswap/v4-core/contracts/libraries/Pool.sol";

import {HookTest} from "./utils/HookTest.sol";
import {DynamicFeeHook, DynamicFeeFactory} from "../src/DynamicFeeFactory.sol";
import {Call, CallType, GenericRouter} from "../src/GenericRouter.sol";

contract DynamicFeeTest is HookTest, Deployers, GasSnapshot {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    DynamicFeeHook hook;
    PoolKey poolKey;
    PoolId poolId;
    GenericRouter router;

    function setUp() public {
        // creates the pool manager, test tokens, and other utility routers
        HookTest.initHookTestEnv();

        router = new GenericRouter(manager);

        token0.approve(address(router), 2 ** 128);
        token1.approve(address(router), 2 ** 128);
        console.log("token0 allowance to router %s", token0.allowance(address(this), address(router)));

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
        poolId = poolKey.toId();
        manager.initialize(poolKey, SQRT_RATIO_1_1);

        // Provide liquidity to the pool
        modifyPositionRouter.modifyPosition(poolKey, IPoolManager.ModifyPositionParams(-60, 60, 10 ether));
        modifyPositionRouter.modifyPosition(poolKey, IPoolManager.ModifyPositionParams(-120, 120, 10 ether));
        modifyPositionRouter.modifyPosition(
            poolKey, IPoolManager.ModifyPositionParams(TickMath.minUsableTick(60), TickMath.maxUsableTick(60), 10 ether)
        );
    }

    function testHookFee() public {
        // Check the hook fee
        (Pool.Slot0 memory slot0,,,) = manager.pools(poolKey.toId());
        // assertEq(slot0.hookSwapFee, FeeLibrary.DYNAMIC_FEE_FLAG);
        assertEq(slot0.hookWithdrawFee, 0);

        assertEq(manager.hookFeesAccrued(address(hook), poolKey.currency0), 0);
        assertEq(manager.hookFeesAccrued(address(hook), poolKey.currency1), 0);
    }

    function testSwapSettleTake() public {
        Call[] memory calls = new Call[](4);

        // Swap 100 0 tokens for 1 tokens
        IPoolManager.SwapParams memory params =
            IPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: MIN_PRICE_LIMIT});
        bytes memory swapCallData = abi.encodeWithSelector(manager.swap.selector, poolKey, params);
        calls[0] = Call(address(manager), CallType.Call, 0, swapCallData);

        bytes memory transferCallData =
            abi.encodeWithSelector(token0.transferFrom.selector, address(this), address(manager), 100);
        calls[1] = Call(address(token0), CallType.Call, 0, transferCallData);

        bytes memory settleCallData = abi.encodeWithSelector(manager.settle.selector, poolKey.currency0);
        calls[2] = Call(address(manager), CallType.Call, 0, settleCallData);

        bytes memory takeCallData = abi.encodeWithSelector(manager.take.selector, poolKey.currency1, address(this), 98);
        calls[3] = Call(address(manager), CallType.Call, 0, takeCallData);

        bytes[] memory results = router.process(calls);

        // Check settle result
        assertEq(abi.decode(results[2], (uint256)), 100);

        // assertGt(manager.hookFeesAccrued(address(hook), poolKey.currency0), 0);
        // assertEq(manager.hookFeesAccrued(address(hook), poolKey.currency1), 0);
    }
}
