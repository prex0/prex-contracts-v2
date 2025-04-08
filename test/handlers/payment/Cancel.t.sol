// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {PaymentSetup} from "./Setup.t.sol";
import {TestUtils} from "../../utils/TestUtils.sol";
import {ERC20} from "../../../lib/solmate/src/tokens/ERC20.sol";
import {OrderReceipt, SignedOrder} from "../../../src/interfaces/IOrderHandler.sol";
import {OrderHeader} from "../../../src/interfaces/IOrderExecutor.sol";
import {MockToken} from "../../mock/MockToken.sol";
import {
    CreatePaymentRequestOrder,
    CreatePaymentRequestOrderLib
} from "../../../src/handlers/payment/CreatePaymentRequestOrder.sol";
import {PaymentOrder, PaymentOrderLib} from "../../../src/handlers/payment/PaymentOrder.sol";
import {PaymentRequestDispatcher} from "../../../src/handlers/payment/PaymentRequestDispatcher.sol";
import {OrderInfo} from "../../../src/libraries/OrderInfo.sol";

contract PaymentCancelTest is PaymentSetup {
    using CreatePaymentRequestOrderLib for CreatePaymentRequestOrder;
    using PaymentOrderLib for PaymentOrder;

    MockToken mockToken;

    address owner = address(this);
    uint256 internal userPrivateKey = 12345;
    address public user = vm.addr(userPrivateKey);

    address public recipient = address(1001);

    bytes32 requestId;

    function setUp() public virtual override {
        super.setUp();

        mockToken = new MockToken();

        // mint 100 token to user
        mockToken.mint(user, 100 * 1e18);

        vm.prank(user);
        mockToken.approve(address(permit2), 1e18);

        CreatePaymentRequestOrder memory request = CreatePaymentRequestOrder({
            orderInfo: OrderInfo({
                dispatcher: address(paymentRequestHandler),
                policyId: 0,
                sender: user,
                deadline: 1,
                nonce: 1
            }),
            recipient: recipient,
            amount: 1e18,
            expiry: 100,
            token: address(mockToken),
            name: "test",
            isPrepaid: false,
            maxPayments: 1
        });

        paymentRequestHandler.execute(
            address(this),
            SignedOrder({
                dispatcher: address(paymentRequestHandler),
                methodId: 1,
                order: abi.encode(request),
                signature: _sign(request, userPrivateKey),
                appSig: bytes(""),
                identifier: bytes32(0)
            }),
            bytes("")
        );

        requestId = paymentRequestHandler.getRequestId(request);
    }

    function testCancelPaymentRequest() public {
        vm.prank(user);
        paymentRequestHandler.cancelPaymentRequest(requestId);
    }

    function testCancelPaymentRequestRevertIfCallerIsNotCreator() public {
        vm.expectRevert(PaymentRequestDispatcher.InvalidSender.selector);
        paymentRequestHandler.cancelPaymentRequest(requestId);
    }

    function testCancelBatchPaymentRequest_RevertIfRequestIsNotExpired() public {
        bytes32[] memory requestIds = new bytes32[](1);
        requestIds[0] = requestId;

        vm.expectRevert(PaymentRequestDispatcher.RequestNotExpired.selector);
        paymentRequestHandler.batchCancelPaymentRequest(requestIds);
    }

    function testCancelBatchPaymentRequest() public {
        vm.warp(102);

        bytes32[] memory requestIds = new bytes32[](1);
        requestIds[0] = requestId;

        paymentRequestHandler.batchCancelPaymentRequest(requestIds);
    }
}
