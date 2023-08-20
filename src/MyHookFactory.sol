// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";

import {MyHook} from "./MyHook.sol";

// import {console} from "forge-std/console.sol";

contract MyHookFactory {
    uint160 public constant UNISWAP_FLAG_MASK = 0xff << 152;

    // Uniswap hook contracts must have specific flags encoded in the first byte of their address
    address public constant TargetPrefix = address(
        uint160(
            Hooks.BEFORE_MODIFY_POSITION_FLAG | Hooks.AFTER_MODIFY_POSITION_FLAG | Hooks.BEFORE_SWAP_FLAG
                | Hooks.AFTER_SWAP_FLAG
        )
    );

    function deploy(IPoolManager poolManager, bytes32 salt) public returns (MyHook) {
        return new MyHook{salt: salt}(poolManager);
    }

    function mineDeploy(IPoolManager poolManager, uint256 startSalt) public returns (MyHook) {
        uint256 endSalt = uint256(startSalt) + 1000;
        for (uint256 i = startSalt; i < endSalt; ++i) {
            bytes32 salt = bytes32(i);
            address hookAddress = computeHookAddress(poolManager, salt);
            // console.log("Testing address in loop %s %s", i, hookAddress);

            if (isPrefix(hookAddress)) {
                // console.log("Found address in loop %s %s", i, hookAddress);
                return deploy(poolManager, salt);
            }
        }
    }

    function mineDeploy(IPoolManager poolManager) external returns (MyHook) {
        return mineDeploy(poolManager, 0);
    }

    function computeHookAddress(IPoolManager poolManager, bytes32 salt) public view returns (address) {
        bytes32 bytecodeHash = keccak256(abi.encodePacked(type(MyHook).creationCode, abi.encode(poolManager)));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash));
        return address(uint160(uint256(hash)));
    }

    function isPrefix(address _address) public pure returns (bool) {
        address actualPrefix = address(uint160(_address) & UNISWAP_FLAG_MASK);
        // console.log("actual prefix   %s", actualPrefix);
        return actualPrefix == TargetPrefix;
    }
}
