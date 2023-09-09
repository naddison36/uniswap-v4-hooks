// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC20Minimal} from "@uniswap/v4-core/contracts/interfaces/external/IERC20Minimal.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/contracts/types/Currency.sol";

/// @dev I can't work out how to deploy library contracts using forge scripting
/// so I'll deploy the callback functions in its own contract
contract RouterCallbacks {
    using CurrencyLibrary for Currency;

    function addLiquidityCallback(bytes memory callData, bytes memory resultData) external {
        (IERC20Minimal token, address sender, address recipient, bool zeroToken) =
            abi.decode(callData, (IERC20Minimal, address, address, bool));

        bytes[] memory results = abi.decode(resultData, (bytes[]));
        BalanceDelta delta = abi.decode(results[0], (BalanceDelta));

        uint128 amount = zeroToken ? uint128(delta.amount0()) : uint128(delta.amount1());

        require(token.transferFrom(sender, recipient, amount), "transfer failed");
    }

    function swapCallback(bytes memory callData, bytes memory resultData) external {
        (IPoolManager poolManager, Currency currency, address recipient, bool zeroForOne) =
            abi.decode(callData, (IPoolManager, Currency, address, bool));

        bytes[] memory results = abi.decode(resultData, (bytes[]));
        BalanceDelta delta = abi.decode(results[0], (BalanceDelta));

        uint128 takeAmount = zeroForOne ? uint128(-1 * delta.amount1()) : uint128(-1 * delta.amount0());

        poolManager.take(currency, recipient, takeAmount);
    }

    function managerSwapCallback(bytes memory callData, bytes memory resultData) external {
        (IPoolManager poolManager, Currency currency, address router, address recipient, bool zeroForOne) =
            abi.decode(callData, (IPoolManager, Currency, address, address, bool));

        bytes[] memory results = abi.decode(resultData, (bytes[]));
        BalanceDelta delta = abi.decode(results[0], (BalanceDelta));

        uint128 takeAmount = zeroForOne ? uint128(-1 * delta.amount1()) : uint128(-1 * delta.amount0());

        poolManager.take(currency, recipient, takeAmount);
        // poolManager.safeTransferFrom(router, recipient, uint160(Currency.unwrap(currency)), takeAmount, "");
    }

    function removeLiquidityCallback(bytes memory callData, bytes memory resultData) external {
        (IPoolManager poolManager, Currency currency0, Currency currency1, address recipient) =
            abi.decode(callData, (IPoolManager, Currency, Currency, address));

        bytes[] memory results = abi.decode(resultData, (bytes[]));
        BalanceDelta delta = abi.decode(results[0], (BalanceDelta));

        poolManager.take(currency0, recipient, uint128(-1 * delta.amount0()));
        poolManager.take(currency1, recipient, uint128(-1 * delta.amount1()));
    }
}
