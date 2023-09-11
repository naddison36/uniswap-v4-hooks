// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract FlashLoanLogic {
    function flashLoanCallback(address token, uint256 amount) external {
        // do something with the loan
    }
    function flashLoansCallback(address[] memory tokens, uint256[] memory amounts) external {
        // do something with mutiple flash loan
    }
}
