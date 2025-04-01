// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PrexPoint} from "../../src/credit/PrexPoint.sol";
import {PrexPointMarket} from "../../src/credit/PrexPointMarket.sol";
import {PointMarketSetup} from "./Setup.t.sol";

contract PointMarketTest is PointMarketSetup {
    address public minter = vm.addr(6);
    address public recipient = vm.addr(7);
    address public user = vm.addr(8);

    function setUp() public virtual override {
        super.setUp();
    }

    function test_setFeeRecipient() public {
        prexPointMarket.setFeeRecipient(feeRecipient);
        assertEq(prexPointMarket.feeRecipient(), feeRecipient);
    }

    function test_addMinter() public {
        prexPointMarket.addMinter(minter);
        assertEq(prexPointMarket.minterMap(minter), true);
    }

    function test_addMinter_revert() public {
        vm.startPrank(user);
        vm.expectRevert("UNAUTHORIZED");
        prexPointMarket.addMinter(minter);
        vm.stopPrank();
    }

    function test_removeMinter() public {
        prexPointMarket.addMinter(minter);
        prexPointMarket.removeMinter(minter);
        assertEq(prexPointMarket.minterMap(minter), false);
    }

    function test_mint() public {
        prexPointMarket.addMinter(minter);

        vm.startPrank(minter);
        prexPointMarket.mint(recipient, 1000 * 1e12, 0, "test");
        vm.stopPrank();

        assertEq(prexPoint.balanceOf(recipient), 1000 * 1e12);
    }

    function test_CannotMintIfNotMinter() public {
        vm.expectRevert(PrexPointMarket.InvalidMinter.selector);

        vm.startPrank(minter);
        prexPointMarket.mint(recipient, 1000 * 1e12, 0, "test");
        vm.stopPrank();
    }

    function test_CannotMintWithSameIdempotencyKey() public {
        prexPointMarket.addMinter(minter);

        vm.startPrank(minter);
        prexPointMarket.mint(recipient, 1000 * 1e12, 0, "test");

        vm.expectRevert(PrexPointMarket.IdempotencyKeyAlreadyUsed.selector);
        prexPointMarket.mint(recipient, 1000 * 1e12, 0, "test");

        vm.stopPrank();
    }
}
