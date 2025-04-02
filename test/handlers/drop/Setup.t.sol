// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ClaimDropRequest} from "../../../src/handlers/drop/ClaimDropRequest.sol";
import {DropHandler} from "../../../src/handlers/drop/DropHandler.sol";
import {CreateDropRequest, CreateDropRequestLib} from "../../../src/handlers/drop/CreateDropRequest.sol";
import {TestUtils} from "../../utils/TestUtils.sol";
import {OrderReceipt, SignedOrder} from "../../../src/interfaces/IOrderHandler.sol";
import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {MockToken} from "../../mock/MockToken.sol";

contract DropRequestSetup is Test, TestUtils {
    using CreateDropRequestLib for CreateDropRequest;

    DropHandler public dropHandler;

    uint256 internal privateKey = 12345;
    uint256 internal privateKey2 = 32156;
    uint256 internal privateKey3 = 654321;
    address internal sender = vm.addr(privateKey);
    address internal recipient = vm.addr(privateKey3);

    MockToken public token;
    uint256 constant MINT_AMOUNT = 1e20;

    function setUp() public virtual override {
        super.setUp();

        dropHandler = new DropHandler(address(permit2), address(this));

        dropHandler.setOrderExecutor(address(this));

        token = new MockToken();

        token.mint(sender, MINT_AMOUNT);

        vm.prank(sender);
        token.approve(address(permit2), 1e20);
    }

    function _submit(CreateDropRequest memory request, bytes memory sig) internal {
        dropHandler.execute(
            address(this),
            SignedOrder({
                dispatcher: address(dropHandler),
                methodId: 1,
                order: abi.encode(request),
                signature: sig,
                appSig: bytes(""),
                identifier: bytes32(0)
            }),
            bytes("")
        );
    }

    function _drop(ClaimDropRequest memory recipientData) internal {
        dropHandler.execute(
            address(this),
            SignedOrder({
                dispatcher: address(dropHandler),
                methodId: 2,
                order: abi.encode(recipientData),
                signature: bytes(""),
                appSig: bytes(""),
                identifier: bytes32(0)
            }),
            bytes("")
        );
    }

    function _sign(CreateDropRequest memory request, uint256 fromPrivateKey)
        internal
        view
        virtual
        returns (bytes memory)
    {
        bytes32 witness = request.hash();

        return getPermit2Signature(
            fromPrivateKey,
            _toPermit(request),
            address(dropHandler),
            CreateDropRequestLib.PERMIT2_ORDER_TYPE,
            witness,
            DOMAIN_SEPARATOR
        );
    }

    function _toPermit(CreateDropRequest memory request)
        internal
        pure
        returns (ISignatureTransfer.PermitTransferFrom memory)
    {
        return ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: request.token, amount: request.amount}),
            nonce: request.orderInfo.nonce,
            deadline: request.orderInfo.deadline
        });
    }

    function _getRecipientData(
        bytes32 _requestId,
        string memory _idempotencyKey,
        uint256 _deadline,
        address _recipient,
        uint256 _privateKey
    ) internal view returns (ClaimDropRequest memory) {
        bytes32 messageHash = keccak256(abi.encode(address(dropHandler), _idempotencyKey, _deadline, _recipient));

        return ClaimDropRequest({
            requestId: _requestId,
            recipient: _recipient,
            idempotencyKey: _idempotencyKey,
            deadline: _deadline,
            sig: _signMessage(_privateKey, messageHash),
            subPublicKey: address(0),
            subSig: bytes("")
        });
    }

    function _getRecipientDataWithSub(
        bytes32 _requestId,
        string memory _idempotencyKey,
        uint256 _deadline,
        address _recipient,
        uint256 _privateKey,
        uint256 _expiry,
        address _subPublicKey,
        uint256 _subPrivateKey
    ) internal view returns (ClaimDropRequest memory) {
        bytes32 messageHash = keccak256(abi.encode(address(dropHandler), _idempotencyKey, _expiry, _subPublicKey));

        bytes32 subMessageHash = keccak256(abi.encode(address(dropHandler), _idempotencyKey, _deadline, _recipient));

        return ClaimDropRequest({
            requestId: _requestId,
            recipient: _recipient,
            idempotencyKey: _idempotencyKey,
            deadline: _deadline,
            sig: _signMessage(_privateKey, messageHash),
            subPublicKey: _subPublicKey,
            subSig: _signMessage(_subPrivateKey, subMessageHash)
        });
    }
}
