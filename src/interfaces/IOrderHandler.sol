// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct SignedOrder {
    address dispatcher;
    uint256 methodId;
    bytes order;
    bytes signature;
    bytes appSig;
}

struct OrderReceipt {
    address user;
    uint256 policyId;
    address[] tokens;
    uint256 points;
}

interface IOrderHandler {
    function execute(address user, SignedOrder calldata order) external returns (OrderReceipt memory);
}
