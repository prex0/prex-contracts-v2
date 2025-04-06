// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CreateLotteryOrder} from "./orders/CreateLotteryOrder.sol";

/**
 * @notice くじを引くためのライブラリ
 */
library LotteryLib {
    struct Prize {
        uint256 count; // 当たりの枚数
        uint256 remaining; // 残りの当たり枚数
        string name; // 賞の名前
    }

    struct Lottery {
        uint256 policyId;
        bool isPrepaid;
        address owner;
        address recipient;
        address token;
        uint256 entryFee;
        string name;
        uint256 totalTickets;
        uint256 remainingTickets;
        bool active;
        Prize[8] prizes;
    }

    function create(CreateLotteryOrder memory order) internal pure returns (Lottery memory) {
        Lottery memory newLottery;

        newLottery.policyId = order.policyId;
        newLottery.isPrepaid = order.isPrepaid;
        newLottery.owner = order.sender;
        newLottery.recipient = order.recipient;
        newLottery.token = order.token;
        newLottery.entryFee = order.entryFee;
        newLottery.active = true;
        newLottery.name = order.name;

        uint256 totalTickets = 0;
        for (uint256 i = 0; i < order.prizeCounts.length; i++) {
            newLottery.prizes[i] = LotteryLib.Prize(order.prizeCounts[i], order.prizeCounts[i], order.prizeNames[i]);
            totalTickets += order.prizeCounts[i];
        }

        newLottery.totalTickets = totalTickets;
        newLottery.remainingTickets = totalTickets;

        return newLottery;
    }

    function draw(Lottery storage lottery, bytes32 randomHash) internal returns (bool, uint256, uint256) {
        if (lottery.remainingTickets == 0 || !lottery.active) {
            return (false, 0, 0);
        }

        uint256 ticketNumber = lottery.totalTickets - lottery.remainingTickets;
        uint256 randomValue = uint256(randomHash) % lottery.remainingTickets;

        uint256 prizeType = 0;
        for (uint256 i = 0; i < lottery.prizes.length; i++) {
            uint256 typeId = i;

            if (lottery.prizes[typeId].remaining > 0 && randomValue < lottery.prizes[typeId].remaining) {
                prizeType = typeId;
                lottery.prizes[typeId].remaining--;
                break;
            } else {
                randomValue -= lottery.prizes[typeId].remaining;
            }
        }

        // くじの残り枚数を減らす
        lottery.remainingTickets--;

        // すべてのくじが引かれたら終了
        if (lottery.remainingTickets == 0) {
            lottery.active = false;
        }

        return (true, ticketNumber, prizeType);
    }
}
