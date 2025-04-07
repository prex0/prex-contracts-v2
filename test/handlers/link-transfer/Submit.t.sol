// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {LinkTransferSetup} from "./Setup.t.sol";
import {LinkTransferHandler} from "../../../src/handlers/link-transfer/LinkTransferHandler.sol";
import {
    LinkTransferRequest, LinkTransferRequestLib
} from "../../../src/handlers/link-transfer/LinkTransferRequest.sol";
import {TestUtils} from "../../utils/TestUtils.sol";
import {ERC20} from "../../../lib/solmate/src/tokens/ERC20.sol";
import {OrderReceipt, SignedOrder} from "../../../src/interfaces/IOrderHandler.sol";
import {OrderHeader} from "../../../src/interfaces/IOrderExecutor.sol";
import {MockToken} from "../../mock/MockToken.sol";
import {LinkTransferRequestDispatcher} from "../../../src/handlers/link-transfer/LinkTransferRequestDispatcher.sol";

contract LinkTransferTest is LinkTransferSetup {
    using LinkTransferRequestLib for LinkTransferRequest;

    MockToken mockToken;

    address owner = address(this);

    uint256 internal userPrivateKey = 12345;
    address public user = vm.addr(userPrivateKey);

    address public recipient = address(1001);

    uint256 tmpPrivKey = 70123;
    address tmpPublicKey = vm.addr(tmpPrivKey);

    function setUp() public virtual override {
        super.setUp();

        mockToken = new MockToken();

        // mint 100 token to user
        mockToken.mint(user, 100 * 1e18);

        vm.prank(user);
        mockToken.approve(address(permit2), 1e18);
    }

    function test_SubmitLinkTransferRequest() public {
        LinkTransferRequest memory request = LinkTransferRequest({
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

        OrderReceipt memory receipt = linkTransferHandler.execute(
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

        assertEq(receipt.policyId, 0);
        assertEq(receipt.points, 5);

        assertEq(mockToken.balanceOf(address(linkTransferHandler)), 1e18);
    }

    function test_SubmitLinkTransferRequest_Expired() public {
        LinkTransferRequest memory request = LinkTransferRequest({
            dispatcher: address(linkTransferHandler),
            policyId: 0,
            sender: user,
            deadline: block.timestamp + 181 days,
            nonce: 1,
            amount: 1e18,
            token: address(mockToken),
            publicKey: tmpPublicKey,
            metadata: bytes("")
        });

        vm.expectRevert(LinkTransferRequestDispatcher.InvalidDeadline.selector);
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
}
