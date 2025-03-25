// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../interfaces/IOrderHandler.sol";

contract BuyPrexPointHandler is IOrderHandler {
    function execute(address _facilitator, SignedOrder calldata order) external returns (OrderReceipt memory) {
        // TODO: Implement buy prex point logic
    }
}
