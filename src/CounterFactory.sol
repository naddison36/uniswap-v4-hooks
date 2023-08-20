// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";

import {CounterHook} from "./CounterHook.sol";

// import {console} from "forge-std/console.sol";

contract CounterFactory {
    uint160 public constant UNISWAP_FLAG_MASK = 0xff << 152;

    // uniswap hook addresses must have specific flags encoded in the address
    address public constant TargetPrefix = address(uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG));

    function deploy(IPoolManager poolManager, bytes32 salt) public returns (CounterHook) {
        return new CounterHook{salt: salt}(poolManager);
    }

    function mineDeploy(IPoolManager poolManager, uint256 startSalt) public returns (CounterHook) {
        uint256 endSalt = uint256(startSalt) + 1000;
        for (uint256 i = startSalt; i < endSalt; ++i) {
            bytes32 salt = bytes32(i);
            address counterAddress = getPrecomputedHookAddress(poolManager, salt);
            // console.log("Testing address in loop %s %s", i, counterAddress);

            if (isPrefix(counterAddress)) {
                // console.log("Found address in loop %s %s", i, counterAddress);
                return deploy(poolManager, salt);
            }
        }
    }

    function mineDeploy(IPoolManager poolManager) external returns (CounterHook) {
        return mineDeploy(poolManager, 0);
    }

    function deploy(IPoolManager poolManager) external returns (CounterHook) {
        // If Counter.s.sol script is executed against a new Anvil node,
        // the PoolManager address will be 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
        // The first salt from 0 to get the before and after swap flags is 745
        // so starting from that to not burn up too much gas
        for (uint256 i = 745; i < 1000; i++) {
            bytes32 salt = bytes32(i);
            address counterAddress = getPrecomputedHookAddress(poolManager, salt);
            // console.log("Testing address in loop %s %s", i, counterAddress);

            if (isPrefix(counterAddress)) {
                // console.log("Found address in loop %s %s", i, counterAddress);
                return deploy(poolManager, salt);
            }
        }
    }

    function getPrecomputedHookAddress(IPoolManager poolManager, bytes32 salt) public view returns (address) {
        bytes32 bytecodeHash = keccak256(abi.encodePacked(type(CounterHook).creationCode, abi.encode(poolManager)));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash));
        return address(uint160(uint256(hash)));
    }

    function isPrefix(address _address) public pure returns (bool) {
        address actualPrefix = address(uint160(_address) & UNISWAP_FLAG_MASK);
        // console.log("actual prefix   %s", actualPrefix);
        return actualPrefix == TargetPrefix;
    }
}
