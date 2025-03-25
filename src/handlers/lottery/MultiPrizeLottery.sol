// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import "../../../lib/permit2/src/interfaces/IPermit2.sol";
import "./orders/CreateLotteryOrder.sol";
import "./orders/DrawLotteryOrder.sol";
import {OrderReceipt} from "../../interfaces/IOrderHandler.sol";

contract MultiPrizeLottery {
    using CreateLotteryOrderLib for CreateLotteryOrder;
    using DrawLotteryOrderLib for DrawLotteryOrder;

    struct Prize {
        uint256 count; // 当たりの枚数
        uint256 remaining; // 残りの当たり枚数
    }

    struct Lottery {
        uint256 policyId;
        address owner;
        address token;
        uint256 entryFee;
        uint256 totalTickets;
        uint256 remainingTickets;
        bool active;
        Prize[8] prizes;
    }

    uint256 public lotteryCounter;
    mapping(uint256 => Lottery) public lotteries;

    IPermit2 public immutable permit2;

    uint256 public constant POINTS = 1e6;

    error InvalidDispatcher();
    error DeadlinePassed();

    event LotteryCreated(uint256 indexed lotteryId, uint256 totalTickets);
    event LotteryDrawn(uint256 indexed lotteryId, address indexed player, uint256 prizeType, uint256 ticketNumber);

    modifier onlyLotteryOwner(uint256 _lotteryId) {
        require(msg.sender == lotteries[_lotteryId].owner, "Not the owner");
        _;
    }

    modifier isLotteryActive(uint256 _lotteryId) {
        require(lotteries[_lotteryId].active, "Lottery is not active");
        _;
    }

    constructor(address _permit2) {
        permit2 = IPermit2(_permit2);
    }

    /// @notice くじを作成（賞の種類と当選数を設定）
    function createLottery(CreateLotteryOrder memory order, bytes memory sig) internal returns (OrderReceipt memory) {
        _verifyCreateOrder(order, sig);

        lotteryCounter++;
        Lottery storage newLottery = lotteries[lotteryCounter];

        newLottery.owner = order.sender;
        newLottery.token = order.token;
        newLottery.entryFee = order.entryFee;
        newLottery.totalTickets = order.totalTickets;
        newLottery.remainingTickets = order.totalTickets;
        newLottery.active = true;
        newLottery.policyId = order.policyId;

        uint256 totalPrizes = 0;
        for (uint256 i = 0; i < order.prizeCounts.length; i++) {
            newLottery.prizes[i] = Prize(order.prizeCounts[i], order.prizeCounts[i]);
            totalPrizes += order.prizeCounts[i];
        }

        require(totalPrizes <= order.totalTickets, "Too many prize tickets");

        emit LotteryCreated(lotteryCounter, order.totalTickets);

        return CreateLotteryOrderLib.getOrderReceipt(order, POINTS);
    }

    /// @notice くじを引く
    function drawLottery(DrawLotteryOrder memory order, bytes memory sig)
        internal
        isLotteryActive(order.lotteryId)
        returns (OrderReceipt memory)
    {
        Lottery storage lottery = lotteries[order.lotteryId];

        require(lottery.remainingTickets > 0, "No tickets left");

        // トークン支払い
        _verifyDrawOrder(order, sig, lottery.token, lottery.entryFee);

        // 抽選のロジック
        bytes32 blockHash = blockhash(block.number - 1);
        require(blockHash != bytes32(0), "Invalid blockhash");

        uint256 ticketNumber = lottery.totalTickets - lottery.remainingTickets;
        uint256 randomValue = uint256(blockHash) % lottery.remainingTickets;

        uint256 prizeType = 0;
        for (uint256 i = 0; i < lottery.prizes.length; i++) {
            uint256 typeId = i;

            if (lottery.prizes[typeId].remaining > 0 && randomValue < lottery.prizes[typeId].remaining) {
                prizeType = typeId;
                lottery.prizes[typeId].remaining--;
                break;
            }
        }

        // くじの残り枚数を減らす
        lottery.remainingTickets--;

        // すべてのくじが引かれたら終了
        if (lottery.remainingTickets == 0) {
            lottery.active = false;
        }

        emit LotteryDrawn(order.lotteryId, msg.sender, prizeType, ticketNumber);

        return getOrderReceipt(lottery);
    }

    function getOrderReceipt(Lottery memory lottery) internal pure returns (OrderReceipt memory) {
        address[] memory tokens = new address[](1);

        tokens[0] = lottery.token;

        return OrderReceipt({tokens: tokens, user: lottery.owner, policyId: lottery.policyId, points: 0});
    }

    /// @notice くじの情報を取得
    function getLotteryInfo(uint256 _lotteryId)
        external
        view
        returns (uint256 entryFee, uint256 totalTickets, uint256 remainingTickets, bool active)
    {
        Lottery storage lottery = lotteries[_lotteryId];
        return (lottery.entryFee, lottery.totalTickets, lottery.remainingTickets, lottery.active);
    }

    function _verifyCreateOrder(CreateLotteryOrder memory order, bytes memory sig) internal {
        if (address(this) != address(order.dispatcher)) {
            revert InvalidDispatcher();
        }

        if (block.timestamp > order.deadline) {
            revert DeadlinePassed();
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
            revert InvalidDispatcher();
        }

        if (block.timestamp > order.deadline) {
            revert DeadlinePassed();
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
