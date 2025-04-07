// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../interfaces/IOrderHandler.sol";
import "./LinkTransferRequest.sol";
import "./LinkTransferRequestDispatcher.sol";

contract LinkTransferHandler is IOrderHandler, LinkTransferRequestDispatcher {
    error InvalidMethodId();

    constructor(address _permit2, address _owner) LinkTransferRequestDispatcher(_permit2, _owner) {}

    function execute(address, SignedOrder calldata order, bytes calldata)
        external
        onlyOrderExecutor
        returns (OrderReceipt memory)
    {
        if (order.methodId == 1) {
            LinkTransferRequest memory request = abi.decode(order.order, (LinkTransferRequest));

            return createRequest(request, order.signature, keccak256(order.order));
        } else if (order.methodId == 2) {
            LinkTransferRequestDispatcher.RecipientData memory recipientData =
                abi.decode(order.order, (LinkTransferRequestDispatcher.RecipientData));

            return completeRequest(recipientData, keccak256(order.order));
        } else {
            revert InvalidMethodId();
        }
    }
}
