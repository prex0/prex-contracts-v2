// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IPolicyManager {
    function depositCredit(uint256 appId, uint256 amount) external;
}
