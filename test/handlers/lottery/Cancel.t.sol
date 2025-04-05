// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {LotterySetup} from "./Setup.t.sol";
import "../../../src/handlers/lottery/orders/CreateLotteryOrder.sol";
import "../../../src/handlers/lottery/orders/DrawLotteryOrder.sol";
import {SignatureVerification} from "../../../lib/permit2/src/libraries/SignatureVerification.sol";
import {MultiPrizeLottery} from "../../../src/handlers/lottery/MultiPrizeLottery.sol";

contract TestLotteryCancel is LotterySetup {
    uint256 public drawerPrivKey = 11111000002;
    address public drawer = vm.addr(drawerPrivKey);

    bytes32 public lotteryId;

    function setUp() public virtual override(LotterySetup) {
        super.setUp();

        CreateLotteryOrder memory request = _getCreateLotteryOrder(address(lotteryHandler), block.timestamp + 100);

        bytes memory sig = _sign(request, privateKey);

        _createLottery(request, sig);

        lotteryId = lotteryHandler.getLotteryId(request);

        token.mint(drawer, 2 * 1e18);

        vm.prank(drawer);
        token.approve(address(permit2), 2 * 1e18);
    }

    function _getCreateLotteryOrder(address _dispatcher, uint256 _deadline)
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
            dispatcher: _dispatcher,
            isPrepaid: false,
            sender: sender,
            recipient: sender,
            deadline: _deadline,
            nonce: 0,
            token: address(token),
            name: "test",
            entryFee: 1e18,
            prizeCounts: prizeCounts,
            prizeNames: prizeNames
        });
    }

    function testCancelLottery() public {
        vm.prank(sender);
        lotteryHandler.cancelLottery(lotteryId);
    }

    function testCannotCancelLottery_IfCallerIsNotLotteryOwner() public {
        vm.expectRevert(MultiPrizeLottery.CallerIsNotLotteryOwner.selector);
        lotteryHandler.cancelLottery(lotteryId);
    }
}
