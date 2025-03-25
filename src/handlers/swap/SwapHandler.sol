// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../interfaces/IOrderHandler.sol";

contract SwapHandler is IOrderHandler {
    function execute(address _facilitator, SignedOrder calldata order)
        external
        returns (OrderHeader memory, OrderReceipt memory)
    {
        // TODO: Implement swap logic
    }
}
