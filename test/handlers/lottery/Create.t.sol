// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {LotterySetup} from "./Setup.t.sol";
import "../../../src/handlers/lottery/orders/CreateLotteryOrder.sol";
import {SignatureVerification} from "../../../lib/permit2/src/libraries/SignatureVerification.sol";

contract TestLotteryRequestDispatcherSubmit is LotterySetup {
    uint256 public tmpPrivKey = 11111000002;
    address tmpPublicKey = vm.addr(tmpPrivKey);

    function setUp() public virtual override(LotterySetup) {
        super.setUp();
    }

    function _getRequest(address _dispatcher, uint256 _deadline) internal view returns (CreateLotteryOrder memory) {
        return CreateLotteryOrder({
            policyId: 0,
            dispatcher: _dispatcher,
            sender: sender,
            deadline: _deadline,
            nonce: 0,
            token: address(token),
            name: "test",
            entryFee: 1,
            totalTickets: 100,
            prizeCounts: new uint256[](0)
        });
    }

    // submit request
    function testCreateLottery() public {
        CreateLotteryOrder memory request = _getRequest(address(lotteryHandler), block.timestamp + 100);

        bytes memory sig = _sign(request, privateKey);

        _createLottery(request, sig);
    }
}
