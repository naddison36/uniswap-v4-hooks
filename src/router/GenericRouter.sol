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
    address target; // contract to be called, or account if no data
    CallType callType;
    bool results; // include the the latest call results
    uint256 value; // Ether value
    bytes data; // call data
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

            bytes memory callData;
            if (call.results) {
                // decode the selector so we can re-encode the call with results data
                bytes4 selector = bytes4(call.data);
                // remove the selector from the in memory call data
                bytes memory dataNoSelector = removeSelector(call.data);
                // decode the param and ignore the result
                (bytes memory decodedCallData,) = abi.decode(dataNoSelector, (bytes, bytes));
                // encode the current results data into bytes
                bytes memory resultsData = abi.encode(results);
                // re-encode the call data with the latest results data
                callData = abi.encodeWithSelector(selector, decodedCallData, resultsData);
            } else {
                callData = call.data;
            }

            if (call.callType == CallType.Delegate) {
                (success, results[i]) = call.target.delegatecall(callData);
            } else {
                (success, results[i]) = call.target.call{value: call.value}(callData);
            }

            if (success == false) {
                console.log("call failed");
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

    function removeSelector(bytes memory data) public pure returns (bytes memory remainingData) {
        require(data.length >= 4, "no selector");

        remainingData = new bytes(data.length - 4);
        for (uint256 i = 0; i < remainingData.length; ++i) {
            remainingData[i] = data[i + 4];
        }
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
