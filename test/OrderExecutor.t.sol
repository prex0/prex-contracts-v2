// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {OrderExecutor} from "../src/OrderExecutor.sol";
import {TransferRequestHandler} from "../src/handlers/transfer/TransferRequestHandler.sol";
import {TransferRequest, TransferRequestLib} from "../src/handlers/transfer/TransferRequest.sol";
import {TestUtils} from "./utils/TestUtils.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import "../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {PrexPoint} from "../src/credit/PrexPoint.sol";
import {SignedOrder} from "../src/interfaces/IOrderHandler.sol";
import {IERC20Errors} from "../lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";

contract OrderExecutorTest is Test, TestUtils {
    using TransferRequestLib for TransferRequest;

    OrderExecutor public orderExecutor;
    TransferRequestHandler public transferRequestHandler;
    PrexPoint public prexPoint;

    address owner = address(this);

    uint256 internal userPrivateKey = 12345;
    address public user = vm.addr(userPrivateKey);

    uint256 internal userPrivateKey2 = 12346;
    address public user2 = vm.addr(userPrivateKey2);

    function setUp() public virtual override {
        super.setUp();

        prexPoint = new PrexPoint(owner, address(permit2));
        orderExecutor = new OrderExecutor(address(prexPoint));
        transferRequestHandler = new TransferRequestHandler(address(permit2));

        prexPoint.setOrderExecutor(address(orderExecutor));

        prexPoint.mint(user, 1000 * 1e6);
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

    function test_Execute() public {
        TransferRequest memory request = createSampleRequest(user, user2);

        orderExecutor.execute(
            SignedOrder({
                dispatcher: address(transferRequestHandler),
                methodId: 0,
                order: abi.encode(request),
                signature: _sign(request, userPrivateKey),
                appSig: bytes(""),
                identifier: bytes32(0)
            }),
            bytes("")
        );

        // check PrexCredit is consumed
        assertEq(prexPoint.balanceOf(user), 999 * 1e6);
    }

    function test_Execute_InsufficientCredit() public {
        TransferRequest memory request = createSampleRequest(user2, user);

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, user2, 0, 1e6));
        orderExecutor.execute(
            SignedOrder({
                dispatcher: address(transferRequestHandler),
                methodId: 0,
                order: abi.encode(request),
                signature: _sign(request, userPrivateKey2),
                appSig: bytes(""),
                identifier: bytes32(0)
            }),
            bytes("")
        );
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
