// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {BipsLibrary} from "../../src/libraries/BipsLibrary.sol";

contract WrapperBipsLibraryTest {
    using BipsLibrary for uint256;

    function calculatePortion(uint256 amount, uint256 bips) public pure returns (uint256) {
        return amount.calculatePortion(bips);
    }
}

contract BipsLibraryTest is Test {
    WrapperBipsLibraryTest wrapper;

    function setUp() public {
        wrapper = new WrapperBipsLibraryTest();
    }

    function test_calculatePortion() public pure {
        assertEq(BipsLibrary.calculatePortion(100, 10000), 1);
        assertEq(BipsLibrary.calculatePortion(100, 500000), 50);
        assertEq(BipsLibrary.calculatePortion(100, 0), 0);
    }

    function test_calculatePortion_revert() public {
        vm.expectRevert(BipsLibrary.InvalidBips.selector);
        wrapper.calculatePortion(100, 1000001);
    }
}
