// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {CreatePaymentRequestOrderLib} from "../../../src/handlers/payment/CreatePaymentRequestOrder.sol";

contract CreatePaymentRequestOrderLibTest is Test {
    function testTypeHash() public pure {
        assertEq(
            CreatePaymentRequestOrderLib.CREATE_PAYMENT_REQUEST_ORDER_TYPE_HASH,
            0x33efd1026bcfb6701df7a71e4216b4c487d91a7e012aa0f3e1c93c24597408cf
        );
    }
}
