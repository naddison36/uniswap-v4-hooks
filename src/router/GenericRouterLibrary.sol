// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console} from "forge-std/console.sol";

import {IERC20Minimal} from "@uniswap/v4-core/contracts/interfaces/external/IERC20Minimal.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolId.sol";

import {Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";

import {Call, CallType, GenericRouter} from "../../src/router/GenericRouter.sol";

library GenericRouterLibrary {
    uint160 public constant MIN_PRICE_LIMIT = TickMath.MIN_SQRT_RATIO + 1;
    uint160 public constant MAX_PRICE_LIMIT = TickMath.MAX_SQRT_RATIO - 1;
    bytes constant EmptyResults = hex"";

    function addLiquidity(
        GenericRouter router,
        address routerCallback,
        IPoolManager manager,
        PoolKey memory poolKey,
        address sender,
        int24 tickLower,
        int24 tickUpper,
        int256 liquidityAmount
    ) internal returns (bytes[] memory results) {
        Call[] memory calls = new Call[](5);

        // Add liquidity to the pool
        IPoolManager.ModifyPositionParams memory modifyPositionParams =
            IPoolManager.ModifyPositionParams(tickLower, tickUpper, liquidityAmount);
        calls[0] = Call({
            target: address(manager),
            callType: CallType.Call,
            results: false,
            value: 0,
            data: abi.encodeWithSelector(manager.modifyPosition.selector, poolKey, modifyPositionParams)
        });

        // Transfer token0 to Pool Manager
        bytes memory paramData = abi.encode(Currency.unwrap(poolKey.currency0), sender, address(manager), true);
        calls[1] = Call({
            target: routerCallback,
            callType: CallType.Delegate,
            results: true,
            value: 0,
            data: abi.encodeWithSelector(GenericRouterLibrary.addLiquidityCallback.selector, paramData, EmptyResults)
        });

        // Settle token0
        calls[2] = Call({
            target: address(manager),
            callType: CallType.Call,
            results: false,
            value: 0,
            data: abi.encodeWithSelector(manager.settle.selector, poolKey.currency0)
        });

        // Transfer token1 to Pool Manager
        paramData = abi.encode(Currency.unwrap(poolKey.currency1), sender, address(manager), false);
        calls[3] = Call({
            target: routerCallback,
            callType: CallType.Delegate,
            results: true,
            value: 0,
            data: abi.encodeWithSelector(GenericRouterLibrary.addLiquidityCallback.selector, paramData, EmptyResults)
        });

        // Settle token1
        calls[4] = Call({
            target: address(manager),
            callType: CallType.Call,
            results: false,
            value: 0,
            data: abi.encodeWithSelector(manager.settle.selector, poolKey.currency1)
        });

        results = router.process(calls);
    }

    function addLiquidityCallback(bytes memory callData, bytes memory resultData) external {
        (IERC20Minimal token, address sender, address receipient, bool zeroToken) =
            abi.decode(callData, (IERC20Minimal, address, address, bool));

        bytes[] memory results = abi.decode(resultData, (bytes[]));
        BalanceDelta delta = abi.decode(results[0], (BalanceDelta));

        uint128 amount = zeroToken ? uint128(delta.amount0()) : uint128(delta.amount1());

        require(token.transferFrom(sender, receipient, amount), "transfer failed");
    }

    function swap(
        GenericRouter router,
        address routerCallback,
        IPoolManager manager,
        PoolKey memory poolKey,
        address swapper,
        address recipient,
        Currency fromCurrency,
        int256 swapAmount
    ) internal returns (bytes[] memory results) {
        Call[] memory calls = new Call[](4);

        bool zeroForOne = fromCurrency == poolKey.currency0;
        Currency toCurrency = zeroForOne ? poolKey.currency1 : poolKey.currency0;

        // Swap
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: swapAmount,
            sqrtPriceLimitX96: zeroForOne ? MIN_PRICE_LIMIT : MAX_PRICE_LIMIT
        });
        calls[0] = Call({
            target: address(manager),
            callType: CallType.Call,
            results: false,
            value: 0,
            data: abi.encodeWithSelector(manager.swap.selector, poolKey, params)
        });

        // Transfer fromToken to Pool Manager
        calls[1] = Call({
            target: Currency.unwrap(fromCurrency),
            callType: CallType.Call,
            results: false,
            value: 0,
            data: abi.encodeWithSelector(IERC20Minimal.transferFrom.selector, swapper, address(manager), swapAmount)
        });

        // Settle fromToken
        calls[2] = Call({
            target: address(manager),
            callType: CallType.Call,
            results: false,
            value: 0,
            data: abi.encodeWithSelector(manager.settle.selector, fromCurrency)
        });

        // Take toToken using a delegated call back to swapTake on this contract
        bytes memory callData = abi.encode(manager, toCurrency, recipient, zeroForOne);
        bytes memory swapTakeData =
            abi.encodeWithSelector(GenericRouterLibrary.swapCallback.selector, callData, EmptyResults);
        calls[3] =
            Call({target: routerCallback, callType: CallType.Delegate, results: true, value: 0, data: swapTakeData});

        results = router.process(calls);
    }

    function swapCallback(bytes memory callData, bytes memory resultData) external {
        (IPoolManager poolManager, Currency currency, address receipient, bool zeroForOne) =
            abi.decode(callData, (IPoolManager, Currency, address, bool));

        bytes[] memory results = abi.decode(resultData, (bytes[]));
        BalanceDelta delta = abi.decode(results[0], (BalanceDelta));

        uint128 takeAmount = zeroForOne ? uint128(-1 * delta.amount1()) : uint128(-1 * delta.amount0());

        poolManager.take(currency, receipient, takeAmount);
    }

    function mint(GenericRouter router, IPoolManager manager, Currency currency, uint256 mintAmount)
        internal
        returns (bytes[] memory results)
    {
        Call[] memory calls = new Call[](3);

        // Router transfers token0 from this test contract to Pool Manager
        calls[0] = Call({
            target: Currency.unwrap(currency),
            callType: CallType.Call,
            results: false,
            value: 0,
            data: abi.encodeWithSelector(IERC20Minimal.transferFrom.selector, address(this), address(manager), mintAmount)
        });

        // Mint token1 to the router
        calls[1] = Call({
            target: address(manager),
            callType: CallType.Call,
            results: false,
            value: 0,
            data: abi.encodeWithSelector(manager.mint.selector, currency, address(this), mintAmount)
        });

        // Settle token1 in the Pool Manager
        calls[2] = Call({
            target: address(manager),
            callType: CallType.Call,
            results: false,
            value: 0,
            data: abi.encodeWithSelector(manager.settle.selector, currency)
        });

        results = router.process(calls);
    }
}
