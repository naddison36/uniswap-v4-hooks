// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {GenericRouterLibrary} from "./GenericRouterLibrary.sol";

/// @dev I can't work out how to deploy library contracts using forge scripting
/// so I'll deploy the callback functions in its own contract
contract RouterCallbacks {
    function addLiquidityCallback(bytes memory callData, bytes memory resultData) external {
        GenericRouterLibrary.addLiquidityCallback(callData, resultData);
    }

    function swapCallback(bytes memory callData, bytes memory resultData) external {
        GenericRouterLibrary.swapCallback(callData, resultData);
    }
}
