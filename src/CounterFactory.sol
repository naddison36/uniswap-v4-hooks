// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";

import {CounterHook} from "./CounterHook.sol";

contract CounterFactory {
    uint160 constant UNISWAP_FLAG_MASK = 0xff << 152;

    // uniswap hook addresses must have specific flags encoded in the address
    address targetPrefix = address(uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG));

    function deploy(IPoolManager poolManager) external returns (CounterHook) {
        // console.log("expected prefix %s", targetPrefix);
        for (uint256 i = 0; i < 1000; i++) {
            bytes32 salt = bytes32(i);
            address counterAddress = getPrecomputedHookAddress(poolManager, salt);

            if (isPrefix(counterAddress)) {
                // console.log("Found address in loop %s %s", i, counterAddress);
                return deploy(poolManager, salt);
            }
        }
    }

    function deploy(IPoolManager poolManager, bytes32 salt) public returns (CounterHook) {
        return new CounterHook{salt: salt}(poolManager);
    }

    function getPrecomputedHookAddress(IPoolManager poolManager, bytes32 salt) public view returns (address) {
        bytes32 bytecodeHash = keccak256(abi.encodePacked(type(CounterHook).creationCode, abi.encode(poolManager)));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash));
        return address(uint160(uint256(hash)));
    }

    function isPrefix(address _address) public view returns (bool) {
        address actualPrefix = address(uint160(_address) & UNISWAP_FLAG_MASK);
        // console.log("actual prefix   %s", actualPrefix);
        return actualPrefix == targetPrefix;
    }
}
