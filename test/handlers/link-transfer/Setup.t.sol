// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {LinkTransferHandler} from "../../../src/handlers/link-transfer/LinkTransferHandler.sol";
import {
    LinkTransferRequest, LinkTransferRequestLib
} from "../../../src/handlers/link-transfer/LinkTransferRequest.sol";
import {LinkTransferRequestDispatcher} from "../../../src/handlers/link-transfer/LinkTransferRequestDispatcher.sol";
import {TestUtils} from "../../utils/TestUtils.sol";
import {ERC20} from "../../../lib/solmate/src/tokens/ERC20.sol";
import {OrderReceipt, SignedOrder} from "../../../src/interfaces/IOrderHandler.sol";
import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {MockToken} from "../../mock/MockToken.sol";

contract LinkTransferSetup is Test, TestUtils {
    using LinkTransferRequestLib for LinkTransferRequest;

    LinkTransferHandler public linkTransferHandler;

    function setUp() public virtual override {
        super.setUp();

        linkTransferHandler = new LinkTransferHandler(address(permit2));
    }

    function _sign(LinkTransferRequest memory request, uint256 fromPrivateKey) internal view returns (bytes memory) {
        bytes32 witness = request.hash();

        return getPermit2Signature(
            fromPrivateKey,
            _toPermit(request),
            address(linkTransferHandler),
            LinkTransferRequestLib.PERMIT2_ORDER_TYPE,
            witness,
            DOMAIN_SEPARATOR
        );
    }

    function _toPermit(LinkTransferRequest memory request)
        internal
        pure
        returns (ISignatureTransfer.PermitTransferFrom memory)
    {
        return ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: address(request.token), amount: request.amount}),
            nonce: request.nonce,
            deadline: request.deadline
        });
    }

    function _getRecipientData(
        bytes32 _requestId,
        uint256 _nonce,
        uint256 _deadline,
        address _recipient,
        uint256 _privateKey
    ) internal view returns (LinkTransferRequestDispatcher.RecipientData memory) {
        bytes32 messageHash = keccak256(abi.encode(address(linkTransferHandler), _nonce, _deadline, _recipient));

        return LinkTransferRequestDispatcher.RecipientData({
            policyId: 0,
            requestId: _requestId,
            recipient: _recipient,
            sig: _signMessage(_privateKey, messageHash),
            metadata: bytes("")
        });
    }
}
