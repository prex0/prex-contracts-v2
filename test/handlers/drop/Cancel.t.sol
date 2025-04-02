// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {DropRequestSetup} from "./Setup.t.sol";
import "../../../src/handlers/drop/DropRequestDispatcher.sol";
import {CreateDropRequest, OrderInfo} from "../../../src/handlers/drop/CreateDropRequest.sol";

contract TestDropRequestDispatcherCancel is DropRequestSetup {
    CreateDropRequest internal request;
    bytes32 internal requestId;

    uint256 public constant AMOUNT = 3;
    uint256 public constant EXPIRY_UNTIL = 5 hours;

    uint256 public constant tmpPrivKey = 11111000002;
    uint256 public constant subPrivKey = 11111000003;

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

    function testCancel() public {
        vm.startPrank(sender);

        uint256 beforeBalance = token.balanceOf(sender);
        dropHandler.cancelRequest(requestId);
        uint256 afterBalance = token.balanceOf(sender);

        assertEq(afterBalance - beforeBalance, AMOUNT);

        vm.stopPrank();
    }

    // 送信者以外がキャンセルしようとするとリバートする
    function testCancel_InvalidSender() public {
        vm.expectRevert(DropRequestDispatcher.CallerIsNotSender.selector);
        dropHandler.cancelRequest(requestId);
    }

    // 配布後でもキャンセルできる
    function testCancel_AfterDrop() public {
        ClaimDropRequest memory recipientData =
            _getRecipientData(requestId, "0", block.timestamp + EXPIRY_UNTIL, recipient, tmpPrivKey);

        _drop(recipientData);

        assertEq(token.balanceOf(recipient), 1);

        vm.startPrank(sender);
        dropHandler.cancelRequest(requestId);
        vm.stopPrank();

        assertEq(token.balanceOf(sender), 99999999999999999999);
    }
}
