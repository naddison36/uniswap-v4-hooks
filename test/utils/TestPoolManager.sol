// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {PoolManager} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {TestERC20} from "@uniswap/v4-core/contracts/test/TestERC20.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";

import {GenericRouter, GenericRouterLibrary} from "../../src/router/GenericRouterLibrary.sol";

/// @notice Deploys a pool manager, test tokens and a generic router.
/// @dev Minimal initialization. Inheriting contract should set up pools and provision liquidity
contract TestPoolManager {
    PoolManager manager;
    TestERC20 token0;
    TestERC20 token1;
    GenericRouter router;

    uint160 public constant MIN_PRICE_LIMIT = TickMath.MIN_SQRT_RATIO + 1;
    uint160 public constant MAX_PRICE_LIMIT = TickMath.MAX_SQRT_RATIO - 1;
    bytes constant EmptyResults = hex"";

    function initialize() public {
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

    // Needed by the GenericRouter to delegate call to when using the GenericRouterLibrary functions
    function transferToPool(bytes memory callData, bytes memory resultData) external {
        GenericRouterLibrary.transferToPool(callData, resultData);
    }

    // Needed by the GenericRouter to delegate call to when using the GenericRouterLibrary functions
    function swapTake(bytes memory callData, bytes memory resultData) external {
        GenericRouterLibrary.swapTake(callData, resultData);
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
