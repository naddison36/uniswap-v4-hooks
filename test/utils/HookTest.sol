// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {PoolManager} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {IERC20Minimal} from "@uniswap/v4-core/contracts/interfaces/external/IERC20Minimal.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolId.sol";

import {Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {TestERC20} from "@uniswap/v4-core/contracts/test/TestERC20.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";

import {GenericRouter} from "../../src/router/GenericRouter.sol";

/// @notice Contract to initialize some test helpers
/// @dev Minimal initialization. Inheriting contract should set up pools and provision liquidity
contract HookTest {
    PoolManager manager;
    TestERC20 token0;
    TestERC20 token1;
    GenericRouter router;

    uint160 public constant MIN_PRICE_LIMIT = TickMath.MIN_SQRT_RATIO + 1;
    uint160 public constant MAX_PRICE_LIMIT = TickMath.MAX_SQRT_RATIO - 1;
    bytes constant EmptyResults = hex"";

    function initHookTestEnv() public {
        uint256 amount = 2 ** 128;
        TestERC20 _tokenA = new TestERC20(amount);
        TestERC20 _tokenB = new TestERC20(amount);

        // pools alphabetically sort tokens by address
        // so align `token0` with `pool.token0` for consistency
        if (address(_tokenA) < address(_tokenB)) {
            token0 = _tokenA;
            token1 = _tokenB;
        } else {
            token0 = _tokenB;
            token1 = _tokenA;
        }

        manager = new PoolManager(500000);

        // Deploy a generic router
        router = new GenericRouter(manager);

        token0.approve(address(router), 2 ** 128);
        token1.approve(address(router), 2 ** 128);
    }

    function transferToPool(bytes memory callData, bytes memory resultData) external {
        (IERC20Minimal token, address sender, address receipient, bool zeroToken) =
            abi.decode(callData, (IERC20Minimal, address, address, bool));

        bytes[] memory results = abi.decode(resultData, (bytes[]));
        BalanceDelta delta = abi.decode(results[0], (BalanceDelta));

        uint128 amount = zeroToken ? uint128(delta.amount0()) : uint128(delta.amount1());

        token.transferFrom(sender, receipient, amount);
    }

    function swapTake(bytes memory callData, bytes memory resultData) external {
        (PoolManager poolManager, Currency currency, address receipient, bool zeroForOne) =
            abi.decode(callData, (PoolManager, Currency, address, bool));

        bytes[] memory results = abi.decode(resultData, (bytes[]));
        BalanceDelta delta = abi.decode(results[0], (BalanceDelta));

        uint128 takeAmount = zeroForOne ? uint128(-1 * delta.amount1()) : uint128(-1 * delta.amount0());

        poolManager.take(currency, receipient, takeAmount);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        public
        virtual
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
}
