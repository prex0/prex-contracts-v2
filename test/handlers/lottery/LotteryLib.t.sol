// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {LotteryLib} from "../../../src/handlers/lottery/LotteryLib.sol";
import {CreateLotteryOrder, CreateLotteryOrderLib} from "../../../src/handlers/lottery/orders/CreateLotteryOrder.sol";

contract LotteryLibTest is Test {
    LotteryLib.Lottery public lottery2;
    LotteryLib.Lottery public lottery3;

    function setUp() public {
        lottery2 = LotteryLib.create(_getCreateLotteryOrderWith2(1, 1));
    }

    function _getCreateLotteryOrder(uint256[] memory prizeCounts, string[] memory prizeNames)
        internal
        view
        returns (CreateLotteryOrder memory)
    {
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

    function _getCreateLotteryOrderWith2(uint256 _count1, uint256 _count2)
        internal
        view
        returns (CreateLotteryOrder memory)
    {
        uint256[] memory prizeCounts = new uint256[](2);
        prizeCounts[0] = _count1;
        prizeCounts[1] = _count2;

        string[] memory prizeNames = new string[](2);
        prizeNames[0] = "prize1";
        prizeNames[1] = "prize2";

        return _getCreateLotteryOrder(prizeCounts, prizeNames);
    }

    function _getCreateLotteryOrderWith3(uint256 _count1, uint256 _count2, uint256 _count3)
        internal
        view
        returns (CreateLotteryOrder memory)
    {
        uint256[] memory prizeCounts = new uint256[](3);
        prizeCounts[0] = _count1;
        prizeCounts[1] = _count2;
        prizeCounts[2] = _count3;

        string[] memory prizeNames = new string[](3);
        prizeNames[0] = "prize1";
        prizeNames[1] = "prize2";
        prizeNames[2] = "prize3";

        return _getCreateLotteryOrder(prizeCounts, prizeNames);
    }

    function testDrawWith2() public {
        {
            (, uint256 ticketNumber, uint256 prizeType) = LotteryLib.draw(lottery2, bytes32(0));

            assertEq(ticketNumber, 0);
            assertEq(prizeType, 0);
        }

        {
            (, uint256 ticketNumber, uint256 prizeType) = LotteryLib.draw(lottery2, bytes32(0));

            assertEq(ticketNumber, 1);
            assertEq(prizeType, 1);
        }

        {
            (bool success,,) = LotteryLib.draw(lottery2, bytes32(0));

            assertFalse(success);
        }
    }

    mapping(uint256 => uint256) public priceMap;

    function testDrawAll() public {
        lottery3 = LotteryLib.create(_getCreateLotteryOrderWith3(1, 2, 3));

        for (uint256 i = 0; i < 6; i++) {
            (bool success,, uint256 prizeType) = LotteryLib.draw(lottery3, keccak256(abi.encode("test", i)));

            priceMap[prizeType]++;

            assertTrue(success);
        }

        assertEq(priceMap[0], 1);
        assertEq(priceMap[1], 2);
        assertEq(priceMap[2], 3);

        // すべてのくじが引かれたら終了
        {
            (bool success,,) = LotteryLib.draw(lottery3, bytes32(0));

            assertFalse(success);
        }
    }
}
