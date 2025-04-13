// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {OrderExecutor} from "../../src/OrderExecutor.sol";
import {TransferRequestHandler} from "../../src/handlers/transfer/TransferRequestHandler.sol";
import {TransferRequest, TransferRequestLib} from "../../src/handlers/transfer/TransferRequest.sol";
import {TestUtils} from "../utils/TestUtils.sol";
import {ERC20} from "../../lib/solmate/src/tokens/ERC20.sol";
import "../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {PrexPoint} from "../../src/credit/PrexPoint.sol";

contract OrderExecutorSetup is Test, TestUtils {
    using TransferRequestLib for TransferRequest;

    OrderExecutor public orderExecutor;
    TransferRequestHandler public transferRequestHandler;
    PrexPoint public prexPoint;

    address owner = address(this);

    uint256 internal userPrivateKey = 12345;
    address public user = vm.addr(userPrivateKey);

    uint256 internal userPrivateKey2 = 12346;
    address public user2 = vm.addr(userPrivateKey2);

    uint256 internal policyPrivateKey = 12347;
    address public policyPublicKey = vm.addr(policyPrivateKey);

    function setUp() public virtual override {
        super.setUp();

        prexPoint = new PrexPoint("PrexPoint", "PREX", owner, address(permit2));
        orderExecutor = new OrderExecutor();
        orderExecutor.initialize(address(prexPoint), owner);
        transferRequestHandler = new TransferRequestHandler(address(permit2), owner);
        transferRequestHandler.setOrderExecutor(address(orderExecutor));

        // Set order executor as consumer
        prexPoint.setConsumer(address(orderExecutor));

        prexPoint.mint(user, 1000 * 1e6);
        prexPoint.mint(owner, 1000 * 1e6);

        // register handler
        orderExecutor.addHandler(address(transferRequestHandler));
    }

    function createSampleRequest(address sender, address recipient) internal view returns (TransferRequest memory) {
        return TransferRequest({
            dispatcher: address(transferRequestHandler),
            policyId: 0,
            sender: sender,
            recipient: recipient,
            deadline: 1,
            nonce: 1,
            amount: 100,
            token: address(0),
            category: 0,
            metadata: bytes("")
        });
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
