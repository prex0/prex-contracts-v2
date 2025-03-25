// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct SignedOrder {
    address dispatcher;
    uint256 methodId;
    bytes order;
    bytes signature;
    bytes appSig;
}

struct OrderHeader {
    address user;
    uint256 policyId;
    address[] tokens;
}

struct OrderReceipt {
    address dispatcher;
    bytes32 orderHash;
    uint256 points;
}

interface IOrderHandler {
    function execute(address user, SignedOrder calldata order)
        external
        returns (OrderHeader memory, OrderReceipt memory);
}
