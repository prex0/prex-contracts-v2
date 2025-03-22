// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {OrderExecutor} from "../src/OrderExecutor.sol";
import {TransferOrderHandler} from "../src/handlers/transfer/TransferOrderHandler.sol";
import {TransferRequest, TransferRequestLib} from "../src/handlers/transfer/TransferOrder.sol";
import {TestUtils} from "./utils/TestUtils.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import "../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import "../src/PrexPoint.sol";

contract OrderExecutorTest is Test, TestUtils {
    using TransferRequestLib for TransferRequest;

    OrderExecutor public orderExecutor;
    TransferOrderHandler public transferOrderHandler;
    PrexPoint public prexPoint;

    uint256 internal userPrivateKey = 12345;
    address public user = vm.addr(userPrivateKey);

    function setUp() public virtual override {
        super.setUp();

        prexPoint = new PrexPoint(address(0));
        orderExecutor = new OrderExecutor(address(0));
        transferOrderHandler = new TransferOrderHandler(address(permit2));
    }

    function test_Execute() public {
        TransferRequest memory request = TransferRequest({
            dispatcher: address(transferOrderHandler),
            policyId: 0,
            sender: user,
            recipient: user,
            deadline: 1,
            nonce: 1,
            amount: 100,
            token: address(0),
            metadata: bytes("")
        });

        orderExecutor.execute(
            address(transferOrderHandler),
            abi.encode(request),
            _sign(request, userPrivateKey),
            _sign(request, userPrivateKey)
        );
    }

    function _sign(TransferRequest memory request, uint256 fromPrivateKey) internal view returns (bytes memory) {
        bytes32 witness = request.hash();

        return getPermit2Signature(
            fromPrivateKey,
            _toPermit(request),
            address(transferOrderHandler),
            TransferRequestLib.PERMIT2_ORDER_TYPE,
            witness,
            DOMAIN_SEPARATOR
        );
    }

    function _toPermit(TransferRequest memory request)
        internal
        view
        returns (ISignatureTransfer.PermitTransferFrom memory)
    {
        return ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({
                token: address(request.token),
                amount: request.amount
            }),
            nonce: request.nonce,
            deadline: request.deadline
        });
    }
}
