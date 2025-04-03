// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {DropRequestSetup} from "./Setup.t.sol";
import "../../../src/handlers/drop/DropRequestDispatcher.sol";
import {CreateDropRequest, OrderInfo} from "../../../src/handlers/drop/CreateDropRequest.sol";

contract TestDropRequestDispatcherDistribute is DropRequestSetup {
    CreateDropRequest internal request;
    bytes32 internal requestId;

    uint256 public constant AMOUNT = 3;
    uint256 public constant EXPIRY_UNTIL = 5 hours;

    uint256 public constant tmpPrivKey = 11111000002;
    uint256 public constant subPrivKey = 11111000003;
    address public subPublicKey = vm.addr(subPrivKey);

    function setUp() public virtual override(DropRequestSetup) {
        super.setUp();

        vm.warp(1 days);

        address tmpPublicKey = vm.addr(tmpPrivKey);

        request = _createCreateDropRequest(tmpPublicKey);

        requestId = dropHandler.getRequestId(request);

        bytes memory sig = _sign(request, privateKey);

        _submit(request, sig);
    }

    function _createCreateDropRequest(address _tmpPublicKey) internal view returns (CreateDropRequest memory) {
        return CreateDropRequest({
            orderInfo: OrderInfo({
                policyId: 0,
                dispatcher: address(dropHandler),
                sender: sender,
                deadline: block.timestamp + EXPIRY_UNTIL,
                nonce: 0
            }),
            isPrepaid: true,
            token: address(token),
            dropPolicyId: 0,
            publicKey: _tmpPublicKey,
            amount: AMOUNT,
            amountPerWithdrawal: 1,
            expiry: block.timestamp + EXPIRY_UNTIL,
            name: "test"
        });
    }

    // 通常の受け取り
    function testClaimDropRequest() public {
        ClaimDropRequest memory recipientData =
            _getClaimDropRequest(requestId, "0", block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        assertEq(token.balanceOf(recipient), 0);
        _drop(recipientData);
        assertEq(token.balanceOf(recipient), 1);

        assertEq(token.balanceOf(recipient), 1);
    }

    // サブキーを使用した受け取り
    function testClaimDropRequest_WithSubKey() public {
        ClaimDropRequest memory recipientData = _getClaimDropRequestWithSub(
            requestId,
            "0",
            block.timestamp + EXPIRY_UNTIL,
            recipient,
            tmpPrivKey,
            request.expiry,
            subPublicKey,
            subPrivKey
        );

        assertEq(token.balanceOf(recipient), 0);
        _drop(recipientData);
        assertEq(token.balanceOf(recipient), 1);

        assertEq(token.balanceOf(recipient), 1);
    }

    // fails to distribute with insufficient locked amount
    function testCannotDistributeWithInsufficientLockedAmount() public {
        _drop(_getClaimDropRequest(requestId, "1", block.timestamp + EXPIRY_UNTIL, address(11), tmpPrivKey));
        _drop(_getClaimDropRequest(requestId, "2", block.timestamp + EXPIRY_UNTIL, address(12), tmpPrivKey));
        _drop(_getClaimDropRequest(requestId, "3", block.timestamp + EXPIRY_UNTIL, address(13), tmpPrivKey));

        ClaimDropRequest memory recipientData =
            _getClaimDropRequest(requestId, "0", block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.expectRevert(DropRequestDispatcher.InsufficientFunds.selector);
        _drop(recipientData);

        assertEq(token.balanceOf(address(11)), 1);
        assertEq(token.balanceOf(address(12)), 1);
    }

    // fails to distribute after expiry
    function testCannotDistributeAfterExpiry() public {
        ClaimDropRequest memory recipientData =
            _getClaimDropRequest(requestId, "0", block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.warp(block.timestamp + EXPIRY_UNTIL + 1);

        vm.expectRevert(DropRequestDispatcher.RequestExpiredError.selector);
        _drop(recipientData);
    }

    // fails to distribute with incorrect signature
    function testCannotDistributeWithIncorrectSignature() public {
        ClaimDropRequest memory recipientData =
            _getClaimDropRequest(requestId, "0", block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        recipientData.sig = _sign(request, privateKey);

        vm.expectRevert(DropRequestDispatcher.InvalidSecret.selector);
        _drop(recipientData);
    }

    // fails to distribute with same idempotency key
    function testCannotDistributeWithSameIdempotencyKey() public {
        _drop(_getClaimDropRequest(requestId, "1", block.timestamp + EXPIRY_UNTIL, address(11), tmpPrivKey));

        ClaimDropRequest memory recipientData =
            _getClaimDropRequest(requestId, "1", block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        vm.expectRevert(DropRequestDispatcher.IdempotencyKeyUsed.selector);
        _drop(recipientData);
    }
}
