// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../interfaces/IOrderHandler.sol";
import "./DropRequestDispatcher.sol";

contract DropHandler is IOrderHandler, DropRequestDispatcher {
    error InvalidMethodId();

    constructor(address _permit2) DropRequestDispatcher(_permit2) {}

    function execute(address, SignedOrder calldata order, bytes calldata) external returns (OrderReceipt memory) {
        if (order.methodId == 1) {
            DropRequest memory request = abi.decode(order.order, (DropRequest));

            return submitRequest(request, order.signature);
        } else if (order.methodId == 2) {
            RecipientData memory recipientData = abi.decode(order.order, (RecipientData));

            return distribute(recipientData);
        } else {
            revert InvalidMethodId();
        }
    }
}
