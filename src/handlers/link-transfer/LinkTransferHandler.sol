// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../interfaces/IOrderHandler.sol";
import "./LinkTransferRequest.sol";
import "./LinkTransferRequestDispatcher.sol";

contract CreateLinkTransferHandler is IOrderHandler, LinkTransferRequestDispatcher {
    error InvalidMethodId();

    constructor(address _permit2) LinkTransferRequestDispatcher(_permit2) {}

    function execute(address _facilitator, SignedOrder calldata order)
        external
        returns (OrderHeader memory, OrderReceipt memory)
    {
        if (order.methodId == 1) {
            LinkTransferRequest memory request = abi.decode(order.order, (LinkTransferRequest));

            return createRequest(request, order.signature);
        } else if (order.methodId == 2) {
            LinkTransferRequestDispatcher.RecipientData memory recipientData =
                abi.decode(order.order, (LinkTransferRequestDispatcher.RecipientData));

            return completeRequest(recipientData);
        } else {
            revert InvalidMethodId();
        }
    }
}
