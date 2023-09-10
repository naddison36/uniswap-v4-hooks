// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";

import {CallType, UniswapV4Router} from "../../src/router/UniswapV4Router.sol";
import {UniswapV4RouterLibrary} from "../../src/router/UniswapV4RouterLibrary.sol";

contract UniswapV4Caller {
    using UniswapV4RouterLibrary for UniswapV4Router;

    UniswapV4Router public immutable router;
    IPoolManager public immutable manager;

    constructor(UniswapV4Router _router, IPoolManager _manager) {
        router = _router;
        manager = _manager;
    }

    function addLiquidity(
        PoolKey memory poolKey,
        address sender,
        int24 tickLower,
        int24 tickUpper,
        int256 liquidityAmount
    ) external returns (bytes[] memory results) {
        results = router.addLiquidity(address(this), manager, poolKey, sender, tickLower, tickUpper, liquidityAmount);
    }

    function addLiquidityCallback(bytes memory callData, bytes memory resultData) external {
        UniswapV4RouterLibrary.addLiquidityCallback(callData, resultData);
    }

    function removeLiquidity(
        PoolKey memory poolKey,
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        int256 liquidityAmount
    ) external returns (bytes[] memory results) {
        results =
            router.removeLiquidity(address(this), manager, poolKey, recipient, tickLower, tickUpper, liquidityAmount);
    }

    function removeLiquidityCallback(bytes memory callData, bytes memory resultData) external {
        UniswapV4RouterLibrary.removeLiquidityCallback(callData, resultData);
    }

    function swap(PoolKey memory poolKey, address swapper, address recipient, Currency fromCurrency, int256 swapAmount)
        external
        returns (bytes[] memory results)
    {
        results = router.swap(address(this), manager, poolKey, swapper, recipient, fromCurrency, swapAmount);
    }

    function swapCallback(bytes memory callData, bytes memory resultData) external {
        UniswapV4RouterLibrary.swapCallback(callData, resultData);
    }

    function managerSwap(
        PoolKey memory poolKey,
        address swapper,
        address recipient,
        Currency fromCurrency,
        int256 swapAmount
    ) external returns (bytes[] memory results) {
        results = router.managerSwap(address(this), manager, poolKey, swapper, recipient, fromCurrency, swapAmount);
    }

    function managerSwapCallback(bytes memory callData, bytes memory resultData) external {
        UniswapV4RouterLibrary.managerSwapCallback(callData, resultData);
    }

    function deposit(address token, address sender, address recipient, uint256 amount)
        external
        returns (bytes[] memory results)
    {
        results = router.deposit(manager, token, sender, recipient, amount);
    }

    function withdraw(address token, address owner, address recipient, uint256 amount)
        external
        returns (bytes[] memory results)
    {
        results = router.withdraw(manager, token, owner, recipient, amount);
    }

    function flashLoan(
        address token,
        uint256 amount,
        address callbackTarget,
        CallType callbackType,
        bytes calldata callbackData
    ) external returns (bytes[] memory results) {
        results = router.flashLoan(manager, token, amount, callbackTarget, callbackType, callbackData);
    }
}
