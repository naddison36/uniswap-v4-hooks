// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Script.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {PoolManager} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolId.sol";

import {PoolModifyPositionTest} from "@uniswap/v4-core/contracts/test/PoolModifyPositionTest.sol";
import {PoolSwapTest} from "@uniswap/v4-core/contracts/test/PoolSwapTest.sol";
import {PoolDonateTest} from "@uniswap/v4-core/contracts/test/PoolDonateTest.sol";
import {TestERC20} from "@uniswap/v4-core/contracts/test/TestERC20.sol";

import {MyHook, MyHookFactory} from "../src/MyHookFactory.sol";

/// @notice Forge script for deploying v4 & hooks to **anvil**
/// @dev This script only works on an anvil RPC because v4 exceeds bytecode limits
contract MyHookScript is Script {
    using CurrencyLibrary for Currency;

    PoolManager poolManager;
    PoolModifyPositionTest modifyPositionRouter;
    PoolSwapTest swapRouter;
    PoolDonateTest donateRouter;
    TestERC20 token0;
    TestERC20 token1;

    PoolKey poolKey;
    uint256 privateKey;
    address signerAddr;

    uint160 public constant SQRT_RATIO_1_1 = 79228162514264337593543950336;
    uint160 public constant MIN_PRICE_LIMIT = TickMath.MIN_SQRT_RATIO + 1;
    uint160 public constant MAX_PRICE_LIMIT = TickMath.MAX_SQRT_RATIO - 1;

    function setUp() public {
        privateKey = vm.envUint("PRIVATE_KEY");
        signerAddr = vm.addr(privateKey);
        vm.startBroadcast(privateKey);

        uint256 approvalAmount = 2 ** 128;
        // Deploy test tokens
        deployTestTokens(approvalAmount);

        // Deploy a new Uniswap Pool Manager
        poolManager = new PoolManager(500000);

        // Deploy the test routers
        deployTestHelpers(approvalAmount);

        // Deploy the hook
        MyHookFactory factory = new MyHookFactory();

        // If the PoolManager address is 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0,
        // the first salt from 0 to get the required address perfix is 138.
        // Any changes to the DynamicFee contract will mean a different salt will be needed
        // so just starting from 0 in this script
        IHooks hook = IHooks(factory.mineDeploy(poolManager, 0));
        console.log("Deployed hook to address %s", address(hook));

        // Derive the key for the new pool
        poolKey = PoolKey(Currency.wrap(address(token0)), Currency.wrap(address(token1)), 3000, 60, hook);
        // Create the pool in the Uniswap Pool Manager
        poolManager.initialize(poolKey, SQRT_RATIO_1_1);

        // Provide liquidity to the pool
        modifyPositionRouter.modifyPosition(poolKey, IPoolManager.ModifyPositionParams(-60, 60, 10 ether));
        modifyPositionRouter.modifyPosition(poolKey, IPoolManager.ModifyPositionParams(-120, 120, 10 ether));
        modifyPositionRouter.modifyPosition(
            poolKey, IPoolManager.ModifyPositionParams(TickMath.minUsableTick(60), TickMath.maxUsableTick(60), 10 ether)
        );

        vm.stopBroadcast();
    }

    function run() public {
        vm.startBroadcast(privateKey);

        // Perform a test swap
        int256 amount = 100;
        bool zeroForOne = true;
        swap(poolKey, amount, zeroForOne);

        vm.stopBroadcast();
    }

    function swap(PoolKey memory key, int256 amountSpecified, bool zeroForOne) internal {
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: amountSpecified,
            sqrtPriceLimitX96: zeroForOne ? MIN_PRICE_LIMIT : MAX_PRICE_LIMIT // unlimited impact
        });

        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({withdrawTokens: true, settleUsingTransfer: true});

        swapRouter.swap(key, params, testSettings);
    }

    function deployTestTokens(uint256 amount) public {
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
    }

    function deployTestHelpers(uint256 amount) public {
        // Helpers for interacting with the pool
        modifyPositionRouter = new PoolModifyPositionTest(IPoolManager(address(poolManager)));
        swapRouter = new PoolSwapTest(IPoolManager(address(poolManager)));
        donateRouter = new PoolDonateTest(IPoolManager(address(poolManager)));

        // Approve for liquidity provision
        token0.approve(address(modifyPositionRouter), amount);
        token1.approve(address(modifyPositionRouter), amount);

        // Approve for swapping
        token0.approve(address(swapRouter), amount);
        token1.approve(address(swapRouter), amount);
    }
}
