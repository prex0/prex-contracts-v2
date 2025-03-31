// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {PolicyManagerSetup} from "./Setup.t.sol";
import {PolicyManager} from "../../src/policy-manager/PolicyManager.sol";
import {IPolicyErrors} from "../../src/interfaces/IPolicyErrors.sol";

contract WithdrawCreditTest is PolicyManagerSetup {
    uint256 appId;

    function setUp() public virtual override {
        super.setUp();

        appId = policyManager.registerApp(appOwner1, "test");

        vm.startPrank(appOwner1);
        prexPoint.approve(address(policyManager), 100);
        policyManager.depositCredit(appId, 100);
        vm.stopPrank();
    }

    // クレジットを引き出す
    function test_WithdrawCredit() public {
        vm.startPrank(appOwner1);
        policyManager.withdrawCredit(appId, 100, appOwner1);
        vm.stopPrank();

        assertEq(prexPoint.balanceOf(address(policyManager)), 0);

        (, uint256 credit) = policyManager.apps(appId);

        assertEq(credit, 0);
    }

    // クレジットが不足している場合はリバートする
    function test_WithdrawCredit_InsufficientCredit() public {
        vm.startPrank(appOwner1);
        vm.expectRevert(abi.encodeWithSelector(IPolicyErrors.InsufficientCredit.selector));
        policyManager.withdrawCredit(appId, 101, appOwner1);
        vm.stopPrank();
    }

    // 不正なアプリオーナーはクレジットを引き出せない
    function test_WithdrawCredit_InvalidAppOwner() public {
        vm.startPrank(appOwner2);
        vm.expectRevert(abi.encodeWithSelector(IPolicyErrors.InvalidAppOwner.selector));
        policyManager.withdrawCredit(appId, 100, appOwner2);
        vm.stopPrank();
    }
}
