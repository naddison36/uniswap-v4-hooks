// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ILockCallback} from "@uniswap/v4-core/contracts//interfaces/callback/ILockCallback.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";

import {console} from "forge-std/console.sol";

enum CallType {
    Call,
    Delegate
}

struct Call {
    address target;
    CallType callType;
    uint256 value;
    bytes data;
}

contract GenericRouter is ILockCallback {
    IPoolManager public immutable manager;

    constructor(IPoolManager _manager) {
        manager = _manager;
    }

    function process(Call[] calldata calls) external payable returns (bytes[] memory results) {
        results = abi.decode(manager.lock(abi.encode(calls)), (bytes[]));
    }

    function lockAcquired(bytes calldata rawData) external returns (bytes memory) {
        require(msg.sender == address(manager));

        Call[] memory calls = abi.decode(rawData, (Call[]));

        bytes[] memory results = new bytes[](calls.length);

        bool success;
        for (uint256 i = 0; i < calls.length; ++i) {
            Call memory call = calls[i];

            if (call.callType == CallType.Delegate) {
                (success, results[i]) = call.target.delegatecall(abi.encodeWithSelector(bytes4(call.data), results));
            } else {
                (success, results[i]) = call.target.call{value: call.value}(call.data);
            }
            if (success == false) {
                assembly {
                    let ptr := mload(0x40)
                    let size := returndatasize()
                    returndatacopy(ptr, 0, size)
                    revert(ptr, size)
                }
            }
        }

        return abi.encode(results);
    }
}
