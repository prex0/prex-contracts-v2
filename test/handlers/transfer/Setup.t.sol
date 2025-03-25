// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {TransferRequestHandler} from "../../../src/handlers/transfer/TransferRequestHandler.sol";
import {TransferRequest, TransferRequestLib} from "../../../src/handlers/transfer/TransferRequest.sol";
import {TestUtils} from "../../utils/TestUtils.sol";
import {ERC20} from "../../../lib/solmate/src/tokens/ERC20.sol";
import {OrderReceipt, SignedOrder} from "../../../src/interfaces/IOrderHandler.sol";
import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {MockToken} from "../../mock/MockToken.sol";

contract TransferRequestSetup is Test, TestUtils {
    using TransferRequestLib for TransferRequest;

    TransferRequestHandler public transferRequestHandler;

    function setUp() public virtual override {
        super.setUp();

        transferRequestHandler = new TransferRequestHandler(address(permit2));
    }

    function _sign(TransferRequest memory request, uint256 fromPrivateKey) internal view returns (bytes memory) {
        bytes32 witness = request.hash();

        return getPermit2Signature(
            fromPrivateKey,
            _toPermit(request),
            address(transferRequestHandler),
            TransferRequestLib.PERMIT2_ORDER_TYPE,
            witness,
            DOMAIN_SEPARATOR
        );
    }

    function _toPermit(TransferRequest memory request)
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
}
