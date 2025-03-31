// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import "../../../lib/permit2/src/interfaces/IPermit2.sol";
import "./orders/CreateLotteryOrder.sol";
import "./orders/DrawLotteryOrder.sol";
import {OrderReceipt} from "../../interfaces/IOrderHandler.sol";
import {IOrderHandler} from "../../interfaces/IOrderHandler.sol";
import "./LotteryLib.sol";

/**
 * @notice 複数の賞を持つくじ
 */
contract MultiPrizeLottery {
    using CreateLotteryOrderLib for CreateLotteryOrder;
    using DrawLotteryOrderLib for DrawLotteryOrder;
    using LotteryLib for LotteryLib.Lottery;

    uint256 public lotteryCounter;
    mapping(uint256 => LotteryLib.Lottery) public lotteries;

    IPermit2 public immutable permit2;

    uint256 public constant POINTS = 1;

    event LotteryCreated(
        uint256 indexed lotteryId,
        address token,
        uint256 entryFee,
        string name,
        uint256[] prizeCounts,
        string[] prizeNames
    );
    event LotteryDrawn(uint256 indexed lotteryId, address indexed player, uint256 ticketNumber, uint256 prizeType);

    // errors
    error CallerIsNotLotteryOwner();
    error LotteryNotFound();
    error LotteryNotActive();

    modifier onlyLotteryOwner(uint256 _lotteryId) {
        if (msg.sender != lotteries[_lotteryId].owner) {
            revert CallerIsNotLotteryOwner();
        }
        _;
    }

    modifier isLotteryActive(uint256 _lotteryId) {
        if (!lotteries[_lotteryId].active) {
            revert LotteryNotActive();
        }
        _;
    }

    constructor(address _permit2) {
        permit2 = IPermit2(_permit2);
    }

    /// @notice くじを作成（賞の種類と当選数を設定）
    function createLottery(CreateLotteryOrder memory order, bytes memory sig) internal returns (OrderReceipt memory) {
        _verifyCreateOrder(order, sig);

        lotteryCounter++;
        uint256 lotteryId = lotteryCounter;

        lotteries[lotteryId] = LotteryLib.create(order);

        emit LotteryCreated(lotteryId, order.token, order.entryFee, order.name, order.prizeCounts, order.prizeNames);

        return CreateLotteryOrderLib.getOrderReceipt(order, _getRequiredPoints(lotteryId));
    }

    function _getRequiredPoints(uint256 _lotteryId) internal view returns (uint256) {
        if (lotteries[_lotteryId].isPrepaid) {
            return lotteries[_lotteryId].totalTickets * POINTS;
        }

        return POINTS;
    }

    /**
     * @notice くじをキャンセル
     * @param _lotteryId くじのID
     */
    function cancelLottery(uint256 _lotteryId) external onlyLotteryOwner(_lotteryId) {
        lotteries[_lotteryId].active = false;
    }

    /// @notice くじを引く
    function drawLottery(DrawLotteryOrder memory order, bytes memory sig)
        internal
        isLotteryActive(order.lotteryId)
        returns (OrderReceipt memory)
    {
        LotteryLib.Lottery storage lottery = lotteries[order.lotteryId];

        require(lottery.remainingTickets > 0, "No tickets left");

        // トークン支払い
        _verifyDrawOrder(order, sig, lottery.token, lottery.entryFee);

        // 抽選のロジック
        bytes32 blockHash = blockhash(block.number - 1);
        require(blockHash != bytes32(0), "Invalid blockhash");

        (bool success, uint256 ticketNumber, uint256 prizeType) = lottery.draw(blockHash);

        if (!success) {
            revert LotteryNotActive();
        }

        emit LotteryDrawn(order.lotteryId, order.sender, ticketNumber, prizeType);

        return _getOrderReceipt(lottery);
    }

    function _getOrderReceipt(LotteryLib.Lottery memory lottery) internal pure returns (OrderReceipt memory) {
        address[] memory tokens = new address[](1);

        tokens[0] = lottery.token;

        return OrderReceipt({
            tokens: tokens,
            user: lottery.owner,
            policyId: lottery.policyId,
            points: lottery.isPrepaid ? 0 : POINTS
        });
    }

    /// @notice くじの情報を取得
    function getLotteryInfo(uint256 _lotteryId) external view returns (LotteryLib.Lottery memory) {
        return lotteries[_lotteryId];
    }

    function _verifyCreateOrder(CreateLotteryOrder memory order, bytes memory sig) internal {
        if (address(this) != address(order.dispatcher)) {
            revert IOrderHandler.InvalidDispatcher();
        }

        if (block.timestamp > order.deadline) {
            revert IOrderHandler.DeadlinePassed();
        }

        permit2.permitWitnessTransferFrom(
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({token: address(order.token), amount: 0}),
                nonce: order.nonce,
                deadline: order.deadline
            }),
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: 0}),
            order.sender,
            order.hash(),
            CreateLotteryOrderLib.PERMIT2_ORDER_TYPE,
            sig
        );
    }

    function _verifyDrawOrder(DrawLotteryOrder memory order, bytes memory sig, address token, uint256 amount)
        internal
    {
        if (address(this) != address(order.dispatcher)) {
            revert IOrderHandler.InvalidDispatcher();
        }

        if (block.timestamp > order.deadline) {
            revert IOrderHandler.DeadlinePassed();
        }

        permit2.permitWitnessTransferFrom(
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({token: address(token), amount: amount}),
                nonce: order.nonce,
                deadline: order.deadline
            }),
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: amount}),
            order.sender,
            order.hash(),
            DrawLotteryOrderLib.PERMIT2_ORDER_TYPE,
            sig
        );
    }
}
