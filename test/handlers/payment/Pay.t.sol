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

contract PaymentTest is PaymentSetup {
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
            creator: user,
            recipient: recipient,
            amount: 1e18,
            expiry: block.timestamp + 100,
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

    function test_Payment() public {
        PaymentOrder memory order = _getPaymentOrder(user, 1, 2);

        OrderReceipt memory receipt = paymentRequestHandler.execute(
            address(this),
            SignedOrder({
                dispatcher: address(paymentRequestHandler),
                methodId: 2,
                order: abi.encode(order),
                signature: _sign(order, address(mockToken), 1e18, userPrivateKey),
                appSig: bytes(""),
                identifier: bytes32(0)
            }),
            bytes("")
        );

        assertEq(receipt.policyId, 0);
        assertEq(receipt.points, 1);

        assertEq(mockToken.balanceOf(user), 99 * 1e18);
        assertEq(mockToken.balanceOf(recipient), 1e18);

        {
            PaymentOrder memory order2 = _getPaymentOrder(user, 1, 3);

            vm.expectRevert(PaymentRequestDispatcher.RequestIsNotOpened.selector);
            paymentRequestHandler.execute(
                address(this),
                SignedOrder({
                    dispatcher: address(paymentRequestHandler),
                    methodId: 2,
                    order: abi.encode(order2),
                    signature: _sign(order2, address(mockToken), 1e18, userPrivateKey),
                    appSig: bytes(""),
                    identifier: bytes32(0)
                }),
                bytes("")
            );
        }
    }

    function _getPaymentOrder(address _sender, uint256 _deadline, uint256 _nonce)
        internal
        view
        returns (PaymentOrder memory)
    {
        return PaymentOrder({
            dispatcher: address(paymentRequestHandler),
            sender: _sender,
            deadline: _deadline,
            nonce: _nonce,
            requestId: requestId,
            metadata: bytes("test")
        });
    }
}
