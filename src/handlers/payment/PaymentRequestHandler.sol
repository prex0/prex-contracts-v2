// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../interfaces/IOrderHandler.sol";
import "./CreatePaymentRequestOrder.sol";
import "./PaymentOrder.sol";
import "./PaymentRequestDispatcher.sol";

contract PaymentRequestHandler is IOrderHandler, PaymentRequestDispatcher {
    error InvalidMethodId();

    constructor(address _permit2) PaymentRequestDispatcher(_permit2) {}

    function execute(address, SignedOrder calldata order, bytes calldata) external returns (OrderReceipt memory) {
        if (order.methodId == 1) {
            CreatePaymentRequestOrder memory createPaymentRequestOrder =
                abi.decode(order.order, (CreatePaymentRequestOrder));

            return createPaymentRequest(createPaymentRequestOrder, order.signature, keccak256(order.order));
        } else if (order.methodId == 2) {
            PaymentOrder memory paymentOrder = abi.decode(order.order, (PaymentOrder));

            return payToken(paymentOrder, order.signature, keccak256(order.order));
        } else {
            revert InvalidMethodId();
        }
    }
}
