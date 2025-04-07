// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PaymentRequestHandler} from "../../../src/handlers/payment/PaymentRequestHandler.sol";
import {PaymentOrder, PaymentOrderLib} from "../../../src/handlers/payment/PaymentOrder.sol";
import {
    CreatePaymentRequestOrder,
    CreatePaymentRequestOrderLib
} from "../../../src/handlers/payment/CreatePaymentRequestOrder.sol";
import {PaymentOrder, PaymentOrderLib} from "../../../src/handlers/payment/PaymentOrder.sol";
import {TestUtils} from "../../utils/TestUtils.sol";
import {ERC20} from "../../../lib/solmate/src/tokens/ERC20.sol";
import {OrderReceipt, SignedOrder} from "../../../src/interfaces/IOrderHandler.sol";
import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {MockToken} from "../../mock/MockToken.sol";

contract PaymentSetup is Test, TestUtils {
    using CreatePaymentRequestOrderLib for CreatePaymentRequestOrder;
    using PaymentOrderLib for PaymentOrder;

    PaymentRequestHandler public paymentRequestHandler;

    function setUp() public virtual override {
        super.setUp();

        paymentRequestHandler = new PaymentRequestHandler(address(permit2), address(this));

        paymentRequestHandler.setOrderExecutor(address(this));
    }

    function _sign(CreatePaymentRequestOrder memory request, uint256 fromPrivateKey)
        internal
        view
        returns (bytes memory)
    {
        bytes32 witness = request.hash();

        return getPermit2Signature(
            fromPrivateKey,
            _toPermit(request),
            address(paymentRequestHandler),
            CreatePaymentRequestOrderLib.PERMIT2_ORDER_TYPE,
            witness,
            DOMAIN_SEPARATOR
        );
    }

    function _sign(PaymentOrder memory order, address token, uint256 amount, uint256 fromPrivateKey)
        internal
        view
        returns (bytes memory)
    {
        bytes32 witness = order.hash();

        return getPermit2Signature(
            fromPrivateKey,
            _toPermit(order, token, amount),
            address(paymentRequestHandler),
            PaymentOrderLib.PERMIT2_ORDER_TYPE,
            witness,
            DOMAIN_SEPARATOR
        );
    }

    function _toPermit(CreatePaymentRequestOrder memory request)
        internal
        pure
        returns (ISignatureTransfer.PermitTransferFrom memory)
    {
        return ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: request.token, amount: 0}),
            nonce: request.orderInfo.nonce,
            deadline: request.orderInfo.deadline
        });
    }

    function _toPermit(PaymentOrder memory order, address token, uint256 amount)
        internal
        pure
        returns (ISignatureTransfer.PermitTransferFrom memory)
    {
        return ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: token, amount: amount}),
            nonce: order.nonce,
            deadline: order.deadline
        });
    }
}
