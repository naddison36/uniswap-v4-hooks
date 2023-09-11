// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console} from "forge-std/console.sol";
import "forge-std/Script.sol";

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {PoolManager} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {FeeLibrary} from "@uniswap/v4-core/contracts/libraries/FeeLibrary.sol";
import {Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolId.sol";

import {DynamicFeeFactory} from "../src/hooks/DynamicFeeHook.sol";
import {CallType, UniswapV4Router} from "../src/router/UniswapV4Router.sol";
import {FlashLoanLogic} from "../src/FlashLoanLogic.sol";
import {TestPoolManager} from "../test/utils/TestPoolManager.sol";

/// @notice Forge script for deploying v4 & hooks to **anvil**
/// @dev This script only works on an anvil RPC because v4 exceeds bytecode limits
contract DynamicFeeScript is Script, TestPoolManager {
    PoolKey poolKey;
    uint256 privateKey;
    address signerAddr;

    function setUp() public {
        privateKey = vm.envUint("PRIVATE_KEY");
        signerAddr = vm.addr(privateKey);
        console.log("signer %s", signerAddr);
        console.log("script %s", address(this));
        vm.startBroadcast(privateKey);

        TestPoolManager.initialize();

        // Deploy the hook
        DynamicFeeFactory factory = new DynamicFeeFactory();
        console.log("Deployed hook factory to address %s", address(factory));

        // If the PoolManager address is 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0,
        // the first salt from 0 to get the required address perfix is 1210.
        // Any changes to the DynamicFee contract will mean a different salt will be needed
        IHooks hook = IHooks(factory.mineDeploy(manager, 1210));
        console.log("Deployed hook to address %s", address(hook));

        // Derive the key for the new pool
        poolKey = PoolKey(
            Currency.wrap(address(token0)), Currency.wrap(address(token1)), FeeLibrary.DYNAMIC_FEE_FLAG, 60, hook
        );
        // Create the pool in the Uniswap Pool Manager
        manager.initialize(poolKey, SQRT_RATIO_1_TO_1);

        console.log("currency0 %s", Currency.unwrap(poolKey.currency0));
        console.log("currency1 %s", Currency.unwrap(poolKey.currency1));

        // Provide liquidity to the pool
        caller.addLiquidity(poolKey, signerAddr, -60, 60, 10e18);
        caller.addLiquidity(poolKey, signerAddr, -120, 120, 20e18);
        caller.addLiquidity(poolKey, signerAddr, TickMath.minUsableTick(60), TickMath.maxUsableTick(60), 30e18);

        vm.stopBroadcast();
    }

    function run() public {
        vm.startBroadcast(privateKey);

        // Perform a test swap
        caller.swap(poolKey, signerAddr, signerAddr, poolKey.currency0, 1e18);
        console.log("swapped token 0 for token 1");

        // Remove liquidity from the pool
        caller.removeLiquidity(poolKey, signerAddr, -60, 60, 4e18);
        console.log("removed liquidity");

        // Deposit token 0 to the pool manager
        caller.deposit(address(token0), signerAddr, signerAddr, 6e18);

        // Withdraw token 0 to the pool manager
        manager.setApprovalForAll(address(caller), true);
        caller.withdraw(address(token0), signerAddr, 4e18);

        // Perform a flash loan
        // Deploy flash loan logic contract that will be delegated to
        FlashLoanLogic flashLoanLogic = new FlashLoanLogic();
        uint256 amount = 10000000e6; // 10 million for a 6 deicmal token
        bytes memory callbackData =
            abi.encodeWithSelector(FlashLoanLogic.flashLoanCallback.selector, address(token0), amount);
        caller.flashLoan(address(token0), amount, address(flashLoanLogic), CallType.Delegate, callbackData);

        // Swap from token 0 in the Pool Manager to token 1 in the Pool Manager
        caller.swapManagerTokens(poolKey, poolKey.currency0, 2e18, signerAddr);
        console.log("swapped token 0 for token 1 in the Pool Manager ");

        vm.stopBroadcast();
    }
}
