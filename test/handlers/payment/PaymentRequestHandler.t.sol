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

contract PaymentRequestTest is PaymentSetup {
    MockToken mockToken;

    address owner = address(this);
    uint256 internal userPrivateKey = 12345;
    address public user = vm.addr(userPrivateKey);

    address public recipient = address(1001);

    function setUp() public virtual override {
        super.setUp();

        mockToken = new MockToken();

        // mint 100 token to user
        mockToken.mint(user, 100 * 1e18);

        vm.prank(user);
        mockToken.approve(address(permit2), 1e18);
    }

    function test_CreatePaymentRequest() public {
        CreatePaymentRequestOrder memory request = CreatePaymentRequestOrder({
            dispatcher: address(paymentRequestHandler),
            policyId: 0,
            creator: user,
            recipient: recipient,
            deadline: 1,
            nonce: 1,
            amount: 1e18,
            token: address(mockToken),
            name: "test",
            isPrepaid: true,
            maxPayments: 10
        });

        OrderReceipt memory receipt = paymentRequestHandler.execute(
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

        assertEq(receipt.policyId, 0);
        assertEq(receipt.points, 10);
    }
}
