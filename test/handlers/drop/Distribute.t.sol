// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {DropRequestSetup} from "./Setup.t.sol";
import "../../../src/handlers/drop/DropRequestDispatcher.sol";

contract TestDropRequestDispatcherDistribute is DropRequestSetup {
    using DropRequestLib for DropRequest;

    DropRequest internal request;
    bytes32 internal requestId;

    uint256 public constant AMOUNT = 3;
    uint256 public constant EXPIRY_UNTIL = 5 hours;

    uint256 public constant tmpPrivKey = 11111000002;
    uint256 public constant subPrivKey = 11111000003;

    function setUp() public virtual override(DropRequestSetup) {
        super.setUp();

        vm.warp(1 days);

        address tmpPublicKey = vm.addr(tmpPrivKey);

        request = DropRequest({
            policyId: 0,
            dispatcher: address(dropHandler),
            sender: sender,
            deadline: block.timestamp + EXPIRY_UNTIL,
            nonce: 0,
            token: address(token),
            publicKey: tmpPublicKey,
            amount: AMOUNT,
            amountPerWithdrawal: 1,
            expiry: block.timestamp + EXPIRY_UNTIL,
            name: "test"
        });

        requestId = dropHandler.getRequestId(request);

        bytes memory sig = _sign(request, privateKey);

        _submit(request, sig);
    }

    // distribute
    function testDistribute() public {
        RecipientData memory recipientData =
            _getRecipientData(requestId, "0", block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        assertEq(token.balanceOf(recipient), 0);
        _drop(recipientData);
        assertEq(token.balanceOf(recipient), 1);

        assertEq(token.balanceOf(recipient), 1);
    }

    function testDistributeWithSub() public {
        RecipientData memory recipientData = _getRecipientDataWithSub(
            requestId, "0", block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey, request.expiry, subPrivKey
        );

        vm.startPrank(facilitator);

        assertEq(token.balanceOf(recipient), 0);
        _drop(recipientData);
        assertEq(token.balanceOf(recipient), 1);

        vm.stopPrank();

        assertEq(token.balanceOf(recipient), 1);
    }

    // fails to distribute with insufficient locked amount
    function testCannotDistributeWithInsufficientLockedAmount() public {
        _drop(_getRecipientData(requestId, "1", block.timestamp + EXPIRY_UNTIL, address(11), tmpPrivKey));
        _drop(_getRecipientData(requestId, "2", block.timestamp + EXPIRY_UNTIL, address(12), tmpPrivKey));
        _drop(_getRecipientData(requestId, "3", block.timestamp + EXPIRY_UNTIL, address(13), tmpPrivKey));

        RecipientData memory recipientData =
            _getRecipientData(requestId, "0", block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.expectRevert(DropRequestDispatcher.InsufficientFunds.selector);
        _drop(recipientData);

        assertEq(token.balanceOf(address(11)), 1);
        assertEq(token.balanceOf(address(12)), 1);
    }

    // fails to distribute after expiry
    function testCannotDistributeAfterExpiry() public {
        RecipientData memory recipientData =
            _getRecipientData(requestId, "0", block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.warp(block.timestamp + EXPIRY_UNTIL + 1);

        vm.expectRevert(DropRequestDispatcher.RequestExpiredError.selector);
        _drop(recipientData);
    }

    // fails to distribute with incorrect signature
    function testCannotDistributeWithIncorrectSignature() public {
        RecipientData memory recipientData =
            _getRecipientData(requestId, "0", block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        recipientData.sig = _sign(request, privateKey);

        vm.expectRevert(DropRequestDispatcher.InvalidSecret.selector);
        _drop(recipientData);
    }

    // fails to distribute with incorrect nonce
    function testCannotDistributeWithIncorrectNonce() public {
        _drop(_getRecipientData(requestId, "1", block.timestamp + EXPIRY_UNTIL, address(11), tmpPrivKey));

        RecipientData memory recipientData =
            _getRecipientData(requestId, "1", block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.expectRevert(DropRequestDispatcher.IdempotencyKeyUsed.selector);
        _drop(recipientData);
    }
}
