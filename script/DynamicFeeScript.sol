// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Script.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {PoolManager} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {FeeLibrary} from "@uniswap/v4-core/contracts/libraries/FeeLibrary.sol";
import {Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolId.sol";

import {PoolModifyPositionTest} from "@uniswap/v4-core/contracts/test/PoolModifyPositionTest.sol";
import {TestERC20} from "@uniswap/v4-core/contracts/test/TestERC20.sol";

import {DynamicFeeHook, DynamicFeeFactory} from "../src/DynamicFeeFactory.sol";
import {Call, CallType, GenericRouter} from "../src/router/GenericRouter.sol";

/// @notice Forge script for deploying v4 & hooks to **anvil**
/// @dev This script only works on an anvil RPC because v4 exceeds bytecode limits
contract DynamicFeeScript is Script {
    PoolManager poolManager;
    PoolModifyPositionTest modifyPositionRouter;
    TestERC20 token0;
    TestERC20 token1;
    GenericRouter router;

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

        // Helpers for interacting with the pool
        modifyPositionRouter = new PoolModifyPositionTest(IPoolManager(address(poolManager)));
        token0.approve(address(modifyPositionRouter), approvalAmount);
        token1.approve(address(modifyPositionRouter), approvalAmount);

        // Deploy the test routers
        router = new GenericRouter(poolManager);

        // Approve the router to transfer test tokens
        token0.approve(address(router), approvalAmount);
        token1.approve(address(router), approvalAmount);

        // Deploy the hook
        DynamicFeeFactory factory = new DynamicFeeFactory();

        // If the PoolManager address is 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0,
        // the first salt from 0 to get the required address perfix is 65.
        // Any changes to the DynamicFee contract will mean a different salt will be needed
        IHooks hook = IHooks(factory.mineDeploy(poolManager, 65));
        console.log("Deployed hook to address %s", address(hook));

        // Derive the key for the new pool
        poolKey = PoolKey(
            Currency.wrap(address(token0)), Currency.wrap(address(token1)), FeeLibrary.DYNAMIC_FEE_FLAG, 60, hook
        );
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

        Call[] memory calls = new Call[](4);

        // Swap 100 0 tokens for 1 tokens
        IPoolManager.SwapParams memory params =
            IPoolManager.SwapParams({zeroForOne: true, amountSpecified: 100, sqrtPriceLimitX96: MIN_PRICE_LIMIT});
        calls[0] = Call({
            target: address(poolManager),
            callType: CallType.Call,
            results: false,
            value: 0,
            data: abi.encodeWithSelector(poolManager.swap.selector, poolKey, params)
        });
        // Transfer token0 from test contract to Pool Manager
        calls[1] = Call({
            target: address(token0),
            callType: CallType.Call,
            results: false,
            value: 0,
            data: abi.encodeWithSelector(token0.transferFrom.selector, signerAddr, address(poolManager), 100)
        });
        calls[2] = Call({
            target: address(poolManager),
            callType: CallType.Call,
            results: false,
            value: 0,
            data: abi.encodeWithSelector(poolManager.settle.selector, poolKey.currency0)
        });
        calls[3] = Call({
            target: address(poolManager),
            callType: CallType.Call,
            results: false,
            value: 0,
            data: abi.encodeWithSelector(poolManager.take.selector, poolKey.currency1, address(this), 98)
        });
        bytes[] memory results = router.process(calls);

        vm.stopBroadcast();
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
}
