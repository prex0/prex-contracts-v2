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

        {
            CreateLotteryOrder memory request = _getCreateLotteryOrder(false, block.timestamp + 100, 0);

            bytes memory sig = _sign(request, privateKey);

            _createLottery(request, sig);
        }

        {
            CreateLotteryOrder memory request = _getCreateLotteryOrder(true, block.timestamp + 100, 1);

            bytes memory sig = _sign(request, privateKey);

            _createLottery(request, sig);
        }

        token.mint(drawer, 2 * 1e18);

        vm.prank(drawer);
        token.approve(address(permit2), 2 * 1e18);
    }

    function _getCreateLotteryOrder(bool _isPrepaid, uint256 _deadline, uint256 _nonce)
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
            dispatcher: address(lotteryHandler),
            isPrepaid: _isPrepaid,
            sender: sender,
            recipient: sender,
            deadline: _deadline,
            nonce: _nonce,
            token: address(token),
            name: "test",
            entryFee: 1e18,
            prizeCounts: prizeCounts,
            prizeNames: prizeNames
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
        // non prepaid lottery
        DrawLotteryOrder memory drawOrder = _getRequest(1, drawer, block.timestamp + 100);

        bytes memory sig = _sign(drawOrder, address(token), 1e18, drawerPrivKey);

        OrderReceipt memory receipt = _drawLottery(drawOrder, sig);

        assertEq(receipt.policyId, 0);
        assertEq(receipt.points, 1);

        assertEq(token.balanceOf(drawer), 1 * 1e18);
    }

    function testDrawLottery_Prepaid() public {
        // prepaid lottery
        DrawLotteryOrder memory drawOrder = _getRequest(2, drawer, block.timestamp + 100);

        bytes memory sig = _sign(drawOrder, address(token), 1e18, drawerPrivKey);

        OrderReceipt memory receipt = _drawLottery(drawOrder, sig);

        assertEq(receipt.policyId, 0);
        assertEq(receipt.points, 0);

        assertEq(token.balanceOf(drawer), 1 * 1e18);
    }

    function testDrawLotteryWithInvalidLotteryId() public {
        DrawLotteryOrder memory drawOrder = _getRequest(10, drawer, block.timestamp + 100);

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
