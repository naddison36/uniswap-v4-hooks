// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";

import {BaseFactory} from "./BaseFactory.sol";
import {MyHook} from "./MyHook.sol";

// import {console} from "forge-std/console.sol";

contract MyHookFactory is BaseFactory {
    constructor()
        BaseFactory(
            address(
                uint160(
                    Hooks.BEFORE_INITIALIZE_FLAG | Hooks.AFTER_INITIALIZE_FLAG | Hooks.BEFORE_MODIFY_POSITION_FLAG
                        | Hooks.AFTER_MODIFY_POSITION_FLAG | Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
                        | Hooks.BEFORE_DONATE_FLAG | Hooks.AFTER_DONATE_FLAG
                )
            )
        )
    {}

    function deploy(IPoolManager poolManager, bytes32 salt) public override returns (address) {
        return address(new MyHook{salt: salt}(poolManager));
    }

    function _hashBytecode(IPoolManager poolManager) internal pure override returns (bytes32 bytecodeHash) {
        bytecodeHash = keccak256(abi.encodePacked(type(MyHook).creationCode, abi.encode(poolManager)));
    }
}
