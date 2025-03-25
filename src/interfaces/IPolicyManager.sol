// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPolicyManager {
    function validatePolicy(address user, bytes calldata userOp, uint256 policyId) external view returns (bool);
    function getPaymentMethod(uint256 policyId) external view returns (uint8);
}
