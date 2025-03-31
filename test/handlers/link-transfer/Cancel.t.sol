// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {LinkTransferSetup} from "./Setup.t.sol";
import {LinkTransferHandler} from "../../../src/handlers/link-transfer/LinkTransferHandler.sol";
import {
    LinkTransferRequest, LinkTransferRequestLib
} from "../../../src/handlers/link-transfer/LinkTransferRequest.sol";
import {LinkTransferRequestDispatcher} from "../../../src/handlers/link-transfer/LinkTransferRequestDispatcher.sol";
import {TestUtils} from "../../utils/TestUtils.sol";
import {ERC20} from "../../../lib/solmate/src/tokens/ERC20.sol";
import {OrderReceipt, SignedOrder} from "../../../src/interfaces/IOrderHandler.sol";
import {MockToken} from "../../mock/MockToken.sol";

contract CancelLinkTransferTest is LinkTransferSetup {
    using LinkTransferRequestLib for LinkTransferRequest;

    MockToken mockToken;

    address owner = address(this);

    uint256 internal userPrivateKey = 12345;
    address public user = vm.addr(userPrivateKey);

    address public recipient = address(1001);

    uint256 tmpPrivKey = 70123;
    address tmpPublicKey = vm.addr(tmpPrivKey);

    uint256 invalidPrivKey = 70124;
    address invalidPublicKey = vm.addr(invalidPrivKey);

    LinkTransferRequest public request;

    function setUp() public virtual override {
        super.setUp();

        mockToken = new MockToken();

        // mint 100 token to user
        mockToken.mint(user, 100 * 1e18);

        vm.prank(user);
        mockToken.approve(address(permit2), 1e18);

        request = LinkTransferRequest({
            dispatcher: address(linkTransferHandler),
            policyId: 0,
            sender: user,
            deadline: 1,
            nonce: 1,
            amount: 1e18,
            token: address(mockToken),
            publicKey: tmpPublicKey,
            metadata: bytes("")
        });

        linkTransferHandler.execute(
            address(this),
            SignedOrder({
                dispatcher: address(linkTransferHandler),
                methodId: 1,
                order: abi.encode(request),
                signature: _sign(request, userPrivateKey),
                appSig: bytes(""),
                identifier: bytes32(0)
            }),
            bytes("")
        );
    }

    // リンク送付は送信者のみがキャンセルでき、キャンセルすると残高が戻る
    function test_CancelLinkTransferRequest() public {
        uint256 userBalance = ERC20(address(mockToken)).balanceOf(user);

        vm.startPrank(user);
        linkTransferHandler.cancelRequest(linkTransferHandler.getRequestId(request));
        vm.stopPrank();

        uint256 userBalanceAfter = ERC20(address(mockToken)).balanceOf(user);

        assertEq(userBalanceAfter - userBalance, request.amount);
    }

    // 送付者以外がキャンセルしようとすると、リバートする
    function test_CancelLinkTransferRequest_InvalidSender() public {
        bytes32 requestId = linkTransferHandler.getRequestId(request);

        vm.expectRevert(LinkTransferRequestDispatcher.InvalidSender.selector);
        linkTransferHandler.cancelRequest(requestId);
    }

    // すでに受け取り済みのリンク送付はキャンセルできない
    function test_CancelLinkTransferRequest_AlreadyReceived() public {
        bytes32 requestId = linkTransferHandler.getRequestId(request);

        LinkTransferRequestDispatcher.RecipientData memory recipientData =
            _getRecipientData(requestId, request.nonce, request.deadline, recipient, tmpPrivKey);

        linkTransferHandler.execute(
            address(this),
            SignedOrder({
                dispatcher: address(linkTransferHandler),
                methodId: 2,
                order: abi.encode(recipientData),
                signature: bytes(""),
                appSig: bytes(""),
                identifier: bytes32(0)
            }),
            bytes("")
        );

        vm.startPrank(user);
        vm.expectRevert(LinkTransferRequestDispatcher.RequestIsNotPending.selector);
        linkTransferHandler.cancelRequest(requestId);
        vm.stopPrank();
    }
}
