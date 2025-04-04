// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {LotterySetup} from "./Setup.t.sol";
import "../../../src/handlers/lottery/orders/CreateLotteryOrder.sol";
import {SignatureVerification} from "../../../lib/permit2/src/libraries/SignatureVerification.sol";
import {LotteryLib} from "../../../src/handlers/lottery/LotteryLib.sol";

contract TestLotteryRequestDispatcherSubmit is LotterySetup {
    uint256 public tmpPrivKey = 11111000002;
    address tmpPublicKey = vm.addr(tmpPrivKey);

    function setUp() public virtual override(LotterySetup) {
        super.setUp();
    }

    function _getRequest(bool _isPrepaid, uint256 _deadline) internal view returns (CreateLotteryOrder memory) {
        uint256[] memory prizeCounts = new uint256[](2);
        prizeCounts[0] = 1;
        prizeCounts[1] = 1;

        string[] memory prizeNames = new string[](2);
        prizeNames[0] = "prize1";
        prizeNames[1] = "prize2";

        return CreateLotteryOrder({
            policyId: 0,
            dispatcher: address(lotteryHandler),
            isPrepaid: _isPrepaid,
            sender: sender,
            recipient: sender,
            deadline: _deadline,
            nonce: 0,
            token: address(token),
            name: "test",
            entryFee: 1,
            prizeCounts: prizeCounts,
            prizeNames: prizeNames
        });
    }

    // submit request
    function testCreateLottery_Prepaid() public {
        CreateLotteryOrder memory request = _getRequest(true, block.timestamp + 100);

        bytes memory sig = _sign(request, privateKey);

        OrderReceipt memory receipt = _createLottery(request, sig);

        assertEq(receipt.policyId, 0);
        assertEq(receipt.points, 2);

        LotteryLib.Lottery memory lottery = lotteryHandler.getLotteryInfo(lotteryHandler.getLotteryId(request));

        assertEq(lottery.totalTickets, 2);
        assertEq(lottery.remainingTickets, 2);
        assertEq(lottery.active, true);
    }

    function testCreateLottery_NotPrepaid() public {
        CreateLotteryOrder memory request = _getRequest(false, block.timestamp + 100);

        bytes memory sig = _sign(request, privateKey);

        OrderReceipt memory receipt = _createLottery(request, sig);

        assertEq(receipt.policyId, 0);
        assertEq(receipt.points, 1);

        LotteryLib.Lottery memory lottery = lotteryHandler.getLotteryInfo(lotteryHandler.getLotteryId(request));

        assertEq(lottery.totalTickets, 2);
        assertEq(lottery.remainingTickets, 2);
        assertEq(lottery.active, true);
    }
}
