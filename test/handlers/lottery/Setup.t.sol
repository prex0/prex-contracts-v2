// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {CreateLotteryOrder, CreateLotteryOrderLib} from "../../../src/handlers/lottery/orders/CreateLotteryOrder.sol";
import {DrawLotteryOrder, DrawLotteryOrderLib} from "../../../src/handlers/lottery/orders/DrawLotteryOrder.sol";
import {LotteryHandler} from "../../../src/handlers/lottery/LotteryHandler.sol";
import {TestUtils} from "../../utils/TestUtils.sol";
import {OrderReceipt, SignedOrder} from "../../../src/interfaces/IOrderHandler.sol";
import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {MockToken} from "../../mock/MockToken.sol";

contract LotterySetup is Test, TestUtils {
    using CreateLotteryOrderLib for CreateLotteryOrder;
    using DrawLotteryOrderLib for DrawLotteryOrder;

    LotteryHandler public lotteryHandler;

    uint256 internal privateKey = 12345;
    uint256 internal privateKey2 = 32156;
    uint256 internal privateKey3 = 654321;
    address internal sender = vm.addr(privateKey);
    address internal recipient = vm.addr(privateKey3);

    MockToken public token;
    uint256 constant MINT_AMOUNT = 1e20;

    function setUp() public virtual override {
        super.setUp();

        lotteryHandler = new LotteryHandler(address(permit2));

        token = new MockToken();

        token.mint(sender, MINT_AMOUNT);

        vm.prank(sender);
        token.approve(address(permit2), 1e20);
    }

    function _createLottery(CreateLotteryOrder memory request, bytes memory sig) internal {
        lotteryHandler.execute(
            address(this),
            SignedOrder({
                dispatcher: address(lotteryHandler),
                methodId: 1,
                order: abi.encode(request),
                signature: sig,
                appSig: bytes(""),
                identifier: bytes32(0)
            }),
            bytes("")
        );
    }

    function _drawLottery(DrawLotteryOrder memory request, bytes memory sig) internal {
        lotteryHandler.execute(
            address(this),
            SignedOrder({
                dispatcher: address(lotteryHandler),
                methodId: 2,
                order: abi.encode(request),
                signature: sig,
                appSig: bytes(""),
                identifier: bytes32(0)
            }),
            bytes("")
        );
    }

    function _sign(CreateLotteryOrder memory request, uint256 fromPrivateKey)
        internal
        view
        virtual
        returns (bytes memory)
    {
        bytes32 witness = request.hash();

        return getPermit2Signature(
            fromPrivateKey,
            _toPermit(request),
            address(lotteryHandler),
            CreateLotteryOrderLib.PERMIT2_ORDER_TYPE,
            witness,
            DOMAIN_SEPARATOR
        );
    }

    function _toPermit(CreateLotteryOrder memory request)
        internal
        pure
        returns (ISignatureTransfer.PermitTransferFrom memory)
    {
        return ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: request.token, amount: 0}),
            nonce: request.nonce,
            deadline: request.deadline
        });
    }

    function _sign(DrawLotteryOrder memory request, address _token, uint256 amount, uint256 fromPrivateKey)
        internal
        view
        virtual
        returns (bytes memory)
    {
        bytes32 witness = request.hash();

        return getPermit2Signature(
            fromPrivateKey,
            _toPermit(request, _token, amount),
            address(lotteryHandler),
            DrawLotteryOrderLib.PERMIT2_ORDER_TYPE,
            witness,
            DOMAIN_SEPARATOR
        );
    }

    function _toPermit(DrawLotteryOrder memory request, address _token, uint256 amount)
        internal
        pure
        returns (ISignatureTransfer.PermitTransferFrom memory)
    {
        return ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: _token, amount: amount}),
            nonce: request.nonce,
            deadline: request.deadline
        });
    }
}
