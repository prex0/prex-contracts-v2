// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DropRequestSetup} from "./Setup.t.sol";
import "../../../src/handlers/drop/DropRequestDispatcher.sol";
import {SignatureVerification} from "../../../lib/permit2/src/libraries/SignatureVerification.sol";

contract TestDropRequestDispatcherSubmit is DropRequestSetup {
    uint256 public tmpPrivKey = 11111000002;
    address tmpPublicKey = vm.addr(tmpPrivKey);

    function setUp() public virtual override(DropRequestSetup) {
        super.setUp();
    }

    function _getRequest(address _dispatcher, uint256 _deadline, uint256 _expiry)
        internal
        view
        returns (CreateDropRequest memory)
    {
        return CreateDropRequest({
            policyId: 0,
            dropPolicyId: 0,
            dispatcher: _dispatcher,
            sender: sender,
            deadline: _deadline,
            nonce: 0,
            token: address(token),
            publicKey: tmpPublicKey,
            amount: 1,
            amountPerWithdrawal: 1,
            expiry: _expiry,
            name: "test"
        });
    }

    // submit request
    function testSubmitRequest() public {
        CreateDropRequest memory request =
            _getRequest(address(dropHandler), block.timestamp + 100, block.timestamp + 100);

        bytes memory sig = _sign(request, privateKey);

        _submit(request, sig);

        assertEq(token.balanceOf(sender), MINT_AMOUNT - 1);
    }

    // fails to submit if invalid signature
    function testCannotSubmitRequestIfInvalidSignature() public {
        CreateDropRequest memory request =
            _getRequest(address(dropHandler), block.timestamp + 100, block.timestamp + 100);

        bytes memory sig = _sign(request, privateKey2);

        vm.expectRevert(SignatureVerification.InvalidSigner.selector);
        _submit(request, sig);
    }

    // fails to submit if invalid dispatcher
    function testCannotSubmitRequestIfInvalidDispatcher() public {
        CreateDropRequest memory request = _getRequest(address(0), block.timestamp + 100, block.timestamp + 100);

        bytes memory sig = _sign(request, privateKey2);

        vm.expectRevert(IOrderHandler.InvalidDispatcher.selector);
        _submit(request, sig);
    }

    // fails to submit if request already exists
    function testCannotSubmitRequestIfAlreadyExists() public {
        CreateDropRequest memory request =
            _getRequest(address(dropHandler), block.timestamp + 100, block.timestamp + 100);

        bytes memory sig = _sign(request, privateKey);

        _submit(request, sig);

        vm.expectRevert(DropRequestDispatcher.RequestAlreadyExists.selector);
        _submit(request, sig);
    }

    // fails to submit if request is expired
    function testCannotSubmitRequestIfExpired() public {
        vm.warp(block.timestamp + 1000);

        CreateDropRequest memory request = _getRequest(address(dropHandler), block.timestamp + 100, 100);

        bytes memory sig = _sign(request, privateKey);

        vm.expectRevert(DropRequestDispatcher.InvalidRequest.selector);
        _submit(request, sig);

        vm.stopPrank();
    }

    // fails to submit if request is expired
    function testCannotSubmitRequestIfInvalidExpiry() public {
        vm.warp(block.timestamp + 1000);

        CreateDropRequest memory request =
            _getRequest(address(dropHandler), block.timestamp + 100, block.timestamp + 365 days);

        bytes memory sig = _sign(request, privateKey);

        vm.expectRevert(DropRequestDispatcher.InvalidRequest.selector);
        _submit(request, sig);

        vm.stopPrank();
    }

    // fails to submit if deadline passed
    function testCannotSubmitIfDeadlinePassed() public {
        CreateDropRequest memory request = _getRequest(address(dropHandler), block.timestamp - 1, block.timestamp + 100);

        bytes memory sig = _sign(request, privateKey);

        vm.expectRevert(IOrderHandler.DeadlinePassed.selector);
        _submit(request, sig);

        vm.stopPrank();
    }
}
