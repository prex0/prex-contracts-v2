// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

contract PolicyPrimitiveSetup is Test {
    address owner = address(this);
    uint256 internal userPrivateKey = 12345;
    address public user = vm.addr(userPrivateKey);
    address public permit2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    function setUp() public virtual {}
}
