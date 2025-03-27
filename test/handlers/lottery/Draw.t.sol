// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {LotterySetup} from "./Setup.t.sol";
import "../../../src/handlers/lottery/orders/CreateLotteryOrder.sol";
import "../../../src/handlers/lottery/orders/DrawLotteryOrder.sol";
import {SignatureVerification} from "../../../lib/permit2/src/libraries/SignatureVerification.sol";
import {MultiPrizeLottery} from "../../../src/handlers/lottery/MultiPrizeLottery.sol";

contract TestLotteryDraw is LotterySetup {
    uint256 public drawerPrivKey = 11111000002;
    address public drawer = vm.addr(drawerPrivKey);

    function setUp() public virtual override(LotterySetup) {
        super.setUp();

        CreateLotteryOrder memory request = _getCreateLotteryOrder(address(lotteryHandler), block.timestamp + 100);

        bytes memory sig = _sign(request, privateKey);

        _createLottery(request, sig);

        token.mint(drawer, 2 * 1e18);

        vm.prank(drawer);
        token.approve(address(permit2), 2 * 1e18);
    }

    function _getCreateLotteryOrder(address _dispatcher, uint256 _deadline)
        internal
        view
        returns (CreateLotteryOrder memory)
    {
        return CreateLotteryOrder({
            policyId: 0,
            dispatcher: _dispatcher,
            sender: sender,
            deadline: _deadline,
            nonce: 0,
            token: address(token),
            name: "test",
            entryFee: 1e18,
            totalTickets: 100,
            prizeCounts: new uint256[](0)
        });
    }

    function _getRequest(uint256 lotteryId, address _sender, uint256 _deadline)
        internal
        view
        returns (DrawLotteryOrder memory)
    {
        return DrawLotteryOrder({
            dispatcher: address(lotteryHandler),
            sender: _sender,
            deadline: _deadline,
            nonce: 0,
            lotteryId: lotteryId
        });
    }

    function testDrawLottery() public {
        DrawLotteryOrder memory drawOrder = _getRequest(1, drawer, block.timestamp + 100);

        bytes memory sig = _sign(drawOrder, address(token), 1e18, drawerPrivKey);

        _drawLottery(drawOrder, sig);

        assertEq(token.balanceOf(drawer), 1 * 1e18);
    }

    function testDrawLotteryWithInvalidLotteryId() public {
        DrawLotteryOrder memory drawOrder = _getRequest(2, drawer, block.timestamp + 100);

        bytes memory sig = _sign(drawOrder, address(token), 1e18, drawerPrivKey);

        vm.expectRevert(MultiPrizeLottery.LotteryNotActive.selector);
        _drawLottery(drawOrder, sig);
    }

    function testCannotDrawLottery_IfLotteryIsNotActive() public {
        vm.prank(sender);
        lotteryHandler.cancelLottery(1);

        DrawLotteryOrder memory drawOrder = _getRequest(1, drawer, block.timestamp + 100);

        bytes memory sig = _sign(drawOrder, address(token), 1e18, drawerPrivKey);

        vm.expectRevert(MultiPrizeLottery.LotteryNotActive.selector);
        _drawLottery(drawOrder, sig);
    }
}
