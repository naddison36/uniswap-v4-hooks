// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ILockCallback} from "@uniswap/v4-core/contracts//interfaces/callback/ILockCallback.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {UniswapV4RouterLibrary} from "./UniswapV4RouterLibrary.sol";

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

contract UniswapV4Router is ILockCallback {
    IPoolManager public immutable manager;

    constructor(IPoolManager _manager) {
        manager = _manager;
    }

    function process(Call[] calldata calls) external payable returns (bytes[] memory results) {
        // encode the calls array into bytes
        bytes memory encodedCalls = abi.encode(calls);
        // Call lock on the PoolManagr
        bytes memory resultsData = manager.lock(encodedCalls);
        // decode the results to a bytes array
        results = abi.decode(resultsData, (bytes[]));
    }

    function lockAcquired(bytes calldata encodedCalls) external returns (bytes memory) {
        require(msg.sender == address(manager));

        // Decode the calls array from bytes
        Call[] memory calls = abi.decode(encodedCalls, (Call[]));

        bytes[] memory results = new bytes[](calls.length);

        for (uint256 i = 0; i < calls.length; ++i) {
            Call memory call = calls[i];

            bytes memory callData;
            if (call.results) {
                // decode the selector so we can re-encode the call with results data
                bytes4 selector = bytes4(call.data);
                // remove the selector from the in memory call data
                bytes memory dataNoSelector = UniswapV4RouterLibrary.removeSelector(call.data);
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
                results[i] = Address.functionDelegateCall(call.target, callData);
            } else {
                results[i] = Address.functionCallWithValue(call.target, callData, call.value);
            }
        }

        // Encode the results array into bytes
        // so we are flattening an array of bytes down to just bytes
        return abi.encode(results);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] memory, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
}
