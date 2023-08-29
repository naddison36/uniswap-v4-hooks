// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console} from "forge-std/console.sol";

import {PoolManager} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {TestERC20} from "@uniswap/v4-core/contracts/test/TestERC20.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";

import {GenericRouter} from "../../src/router/GenericRouterLibrary.sol";
import {RouterCallbacks} from "../../src/router/RouterCallbacks.sol";

/// @notice Deploys a pool manager, test tokens and a generic router.
/// @dev Minimal initialization. Inheriting contract should set up pools and provision liquidity
contract TestPoolManager {
    PoolManager manager;
    TestERC20 token0;
    TestERC20 token1;
    GenericRouter router;
    address routerCallback;

    uint160 public constant MIN_PRICE_LIMIT = TickMath.MIN_SQRT_RATIO + 1;
    uint160 public constant MAX_PRICE_LIMIT = TickMath.MAX_SQRT_RATIO - 1;
    bytes constant EmptyResults = hex"";
    uint256 constant MaxAmount = type(uint128).max;

    function initialize() public {
        TestERC20 _tokenA = new TestERC20(MaxAmount);
        TestERC20 _tokenB = new TestERC20(MaxAmount);

        // pools alphabetically sort tokens by address
        // so align `token0` with `pool.token0` for consistency
        if (address(_tokenA) < address(_tokenB)) {
            token0 = _tokenA;
            token1 = _tokenB;
        } else {
            token0 = _tokenB;
            token1 = _tokenA;
        }
        console.log("token0 %s", address(token0));
        console.log("token1 %s", address(token1));

        manager = new PoolManager(500000);
        console.log("pool manager %s", address(manager));

        // Deploy a generic router
        router = new GenericRouter(manager);
        console.log("router %s", address(router));
        routerCallback = address(new RouterCallbacks());

        token0.approve(address(router), MaxAmount);
        token1.approve(address(router), MaxAmount);
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
