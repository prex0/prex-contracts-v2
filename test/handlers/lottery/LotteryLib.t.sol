// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {LotteryLib} from "../../../src/handlers/lottery/LotteryLib.sol";
import {CreateLotteryOrder, CreateLotteryOrderLib} from "../../../src/handlers/lottery/orders/CreateLotteryOrder.sol";

contract LotteryLibTest is Test {
    LotteryLib.Lottery public lottery;

    function setUp() public {
        lottery = LotteryLib.create(_getCreateLotteryOrder());
    }

    function _getCreateLotteryOrder()
        internal
        view
        returns (CreateLotteryOrder memory)
    {
        uint256[] memory prizeCounts = new uint256[](2);
        prizeCounts[0] = 1;
        prizeCounts[1] = 1;

        string[] memory prizeNames = new string[](2);
        prizeNames[0] = "prize1";
        prizeNames[1] = "prize2";

        return CreateLotteryOrder({
            policyId: 0,
            dispatcher: address(this),
            sender: address(this),
            deadline: block.timestamp + 100,
            nonce: 0,
            token: address(0),
            name: "test",
            entryFee: 1e18,
            prizeCounts: prizeCounts,
            prizeNames: prizeNames
        });
    }

    function testDraw() public {
        {
            (uint256 ticketNumber, uint256 prizeType) = LotteryLib.draw(lottery, bytes32(0));

            assertEq(ticketNumber, 0);
            assertEq(prizeType, 0);
        }

        {
            (uint256 ticketNumber, uint256 prizeType) = LotteryLib.draw(lottery, bytes32(0));

            assertEq(ticketNumber, 1);
            assertEq(prizeType, 1);
        }

        {
            vm.expectRevert("Lottery is not active");
            LotteryLib.draw(lottery, bytes32(0));
        }
    }
}
