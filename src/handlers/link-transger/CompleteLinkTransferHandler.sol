// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../interfaces/IOrderHandler.sol";
import "./LinkTransferRequest.sol";
import "./LinkTransferRequestDispatcher.sol";

contract CompleteLinkTransferHandler is IOrderHandler {
    LinkTransferRequestDispatcher public linkTransferRequestDispatcher;

    constructor(address _linkTransferRequestDispatcher) {
        linkTransferRequestDispatcher = LinkTransferRequestDispatcher(_linkTransferRequestDispatcher);
    }

    function execute(
        address _facilitator,
        bytes calldata order,
        bytes calldata signature
    ) external returns (OrderHeader memory, OrderReceipt memory) {
        LinkTransferRequestDispatcher.RecipientData memory recipientData = abi.decode(order, (LinkTransferRequestDispatcher.RecipientData));

        return linkTransferRequestDispatcher.completeRequest(recipientData);
    }
}
