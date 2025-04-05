// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {CreateLotteryOrderLib} from "../../../src/handlers/lottery/orders/CreateLotteryOrder.sol";

contract CreateLotteryOrderLibTest is Test {
    function testTypeHash() public pure {
        assertEq(
            CreateLotteryOrderLib.CREATE_LOTTERY_ORDER_TYPE_HASH,
            0xa5965078abe9fb5226dbab28b73e44c46829202334e329e480558c006f797f79
        );
    }
}
