// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import "../../../lib/permit2/src/interfaces/IPermit2.sol";
import "./orders/CreateLotteryOrder.sol";
import "./orders/DrawLotteryOrder.sol";
import {OrderReceipt} from "../../interfaces/IOrderHandler.sol";
import {IOrderHandler} from "../../interfaces/IOrderHandler.sol";
import "./LotteryLib.sol";
import {BaseHandler} from "../../base/BaseHandler.sol";

/**
 * @notice 複数の賞を持つくじ
 */
contract MultiPrizeLottery is BaseHandler {
    using CreateLotteryOrderLib for CreateLotteryOrder;
    using DrawLotteryOrderLib for DrawLotteryOrder;
    using LotteryLib for LotteryLib.Lottery;

    struct LotteryResult {
        bytes32 lotteryId;
        uint256 prizeType;
    }

    struct LotteryResultView {
        bytes32 lotteryId;
        uint256 prizeType;
        string prizeName;
    }

    mapping(bytes32 => LotteryLib.Lottery) public lotteries;

    mapping(bytes32 => LotteryResult) private lotteryResults;

    IPermit2 public immutable permit2;

    event LotteryCreated(
        bytes32 indexed lotteryId,
        address token,
        address owner,
        address recipient,
        uint256 entryFee,
        uint256 expiry,
        string name,
        uint256[] prizeCounts,
        string[] prizeNames,
        bytes32 orderHash
    );
    event LotteryDrawn(
        bytes32 indexed lotteryId, address indexed player, uint256 ticketNumber, uint256 prizeType, bytes32 orderHash
    );
    event LotteryCancelled(bytes32 indexed lotteryId);

    // errors
    error CallerIsNotLotteryOwner();
    error LotteryNotFound();
    error LotteryNotActive();
    error LotteryAlreadyExists();
    error LotteryExpired();
    error LotteryNotExpired();
    error LotteryAlreadyCancelled();

    modifier onlyLotteryOwner(bytes32 _lotteryId) {
        if (msg.sender != lotteries[_lotteryId].owner) {
            revert CallerIsNotLotteryOwner();
        }
        _;
    }

    modifier isLotteryActive(bytes32 _lotteryId) {
        if (!lotteries[_lotteryId].active) {
            revert LotteryNotActive();
        }
        _;
    }

    constructor(address _permit2, address _owner) BaseHandler(_owner) {
        permit2 = IPermit2(_permit2);
    }

    function getLotteryId(CreateLotteryOrder memory order) public pure returns (bytes32) {
        return keccak256(abi.encode(order));
    }

    /// @notice くじを作成（賞の種類と当選数を設定）
    function createLottery(CreateLotteryOrder memory order, bytes memory sig, bytes32 orderHash)
        internal
        returns (OrderReceipt memory)
    {
        _verifyCreateOrder(order, sig);

        bytes32 lotteryId = getLotteryId(order);

        if (lotteries[lotteryId].active || lotteries[lotteryId].token != address(0)) {
            revert LotteryAlreadyExists();
        }

        lotteries[lotteryId] = LotteryLib.create(order);

        emit LotteryCreated(
            lotteryId,
            order.token,
            order.orderInfo.sender,
            order.recipient,
            order.entryFee,
            order.expiry,
            order.name,
            order.prizeCounts,
            order.prizeNames,
            orderHash
        );

        return CreateLotteryOrderLib.getOrderReceipt(order, _getRequiredPoints(lotteryId));
    }

    function _getRequiredPoints(bytes32 _lotteryId) internal view returns (uint256) {
        if (lotteries[_lotteryId].isPrepaid) {
            return lotteries[_lotteryId].totalTickets * points;
        }

        return points;
    }

    /**
     * @notice くじをキャンセル
     * @param _lotteryId くじのID
     */
    function cancelLottery(bytes32 _lotteryId) external onlyLotteryOwner(_lotteryId) {
        if (!lotteries[_lotteryId].active) {
            revert LotteryAlreadyCancelled();
        }

        lotteries[_lotteryId].active = false;

        emit LotteryCancelled(_lotteryId);
    }

    /**
     * @notice 複数のくじをキャンセル
     * @param _lotteryIds くじのID
     */
    function batchCancelLottery(bytes32[] memory _lotteryIds) external {
        for (uint256 i = 0; i < _lotteryIds.length; i++) {
            _cancelExpiredLottery(_lotteryIds[i]);
        }
    }

    function _cancelExpiredLottery(bytes32 _lotteryId) internal {
        if (!lotteries[_lotteryId].active) {
            revert LotteryAlreadyCancelled();
        }

        if (block.timestamp < lotteries[_lotteryId].expiry) {
            revert LotteryNotExpired();
        }

        lotteries[_lotteryId].active = false;

        emit LotteryCancelled(_lotteryId);
    }

    /// @notice くじを引く
    function drawLottery(DrawLotteryOrder memory order, bytes memory sig, bytes32 orderHash)
        internal
        isLotteryActive(order.lotteryId)
        returns (OrderReceipt memory)
    {
        LotteryLib.Lottery storage lottery = lotteries[order.lotteryId];

        if (block.timestamp > lottery.expiry) {
            revert LotteryExpired();
        }

        require(lottery.remainingTickets > 0, "No tickets left");

        // トークン支払い
        _verifyDrawOrder(order, sig, lottery.token, lottery.entryFee, lottery.recipient);

        // 抽選のロジック
        bytes32 blockHash = blockhash(block.number - 1);
        require(blockHash != bytes32(0), "Invalid blockhash");

        (bool success, uint256 ticketNumber, uint256 prizeType) = lottery.draw(blockHash);

        if (!success) {
            revert LotteryNotActive();
        }

        lotteryResults[keccak256(abi.encode(order))] = LotteryResult({lotteryId: order.lotteryId, prizeType: prizeType});

        emit LotteryDrawn(order.lotteryId, order.sender, ticketNumber, prizeType, orderHash);

        if (!lottery.active) {
            emit LotteryCancelled(order.lotteryId);
        }

        return _getOrderReceipt(lottery);
    }

    function _getOrderReceipt(LotteryLib.Lottery memory lottery) internal view returns (OrderReceipt memory) {
        address[] memory tokens = new address[](1);

        tokens[0] = lottery.token;

        return OrderReceipt({
            tokens: tokens,
            user: lottery.owner,
            policyId: lottery.policyId,
            points: lottery.isPrepaid ? 0 : points
        });
    }

    /// @notice くじの情報を取得
    function getLotteryInfo(bytes32 _lotteryId) external view returns (LotteryLib.Lottery memory) {
        return lotteries[_lotteryId];
    }

    /// @notice くじの結果を取得
    function getLotteryResult(bytes32 _resultId) external view returns (LotteryResultView memory) {
        LotteryResult memory result = lotteryResults[_resultId];

        return LotteryResultView({
            lotteryId: result.lotteryId,
            prizeType: result.prizeType,
            prizeName: lotteries[result.lotteryId].prizes[result.prizeType].name
        });
    }

    function _verifyCreateOrder(CreateLotteryOrder memory order, bytes memory sig) internal {
        if (address(this) != address(order.orderInfo.dispatcher)) {
            revert IOrderHandler.InvalidDispatcher();
        }

        if (block.timestamp > order.orderInfo.deadline) {
            revert IOrderHandler.DeadlinePassed();
        }

        permit2.permitWitnessTransferFrom(
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({token: address(order.token), amount: 0}),
                nonce: order.orderInfo.nonce,
                deadline: order.orderInfo.deadline
            }),
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: 0}),
            order.orderInfo.sender,
            order.hash(),
            CreateLotteryOrderLib.PERMIT2_ORDER_TYPE,
            sig
        );
    }

    function _verifyDrawOrder(
        DrawLotteryOrder memory order,
        bytes memory sig,
        address token,
        uint256 amount,
        address recipient
    ) internal {
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
            ISignatureTransfer.SignatureTransferDetails({to: recipient, requestedAmount: amount}),
            order.sender,
            order.hash(),
            DrawLotteryOrderLib.PERMIT2_ORDER_TYPE,
            sig
        );
    }
}
