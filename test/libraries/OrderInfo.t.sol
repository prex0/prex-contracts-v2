// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {OrderInfo, OrderInfoLib} from "../../src/libraries/OrderInfo.sol";

contract OrderInfoTest is Test {
    function test_hash() public {
        OrderInfo memory orderInfo =
            OrderInfo({dispatcher: address(1), policyId: 1, sender: address(2), deadline: 100, nonce: 1});

        assertEq(OrderInfoLib.hash(orderInfo), 0xbcb1549603216fbb26d64904877eeeef03eab0d0553016cd0dee39d8e57099b5);
    }

    function testTypeHash() public pure {
        assertEq(OrderInfoLib.ORDER_INFO_TYPE_HASH, 0x9050702bb8d5ddad912e228179852accd0e0bbf3c9b8929a7c8274ef45d8c50e);
    }
}
