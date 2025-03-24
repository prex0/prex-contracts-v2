// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct OrderHeader {
    address user;
    uint256 policyId;
    uint256 nonce;
    uint256 deadline;
    address[] tokens;
}

struct OrderReceipt {
    address dispatcher;
    bytes32 orderHash;
    uint256 points;
}

interface IOrderHandler {
    function execute(
        address user,
        bytes calldata order,
        bytes calldata signature
    ) external returns (OrderHeader memory, OrderReceipt memory);
}