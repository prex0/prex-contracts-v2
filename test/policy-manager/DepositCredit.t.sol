// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PolicyManagerSetup} from "./Setup.t.sol";
import {PolicyManager} from "../../src/policy-manager/PolicyManager.sol";
import {IPolicyErrors} from "../../src/interfaces/IPolicyErrors.sol";

contract DepositCreditTest is PolicyManagerSetup {
    uint256 appId;

    function setUp() public virtual override {
        super.setUp();

        appId = policyManager.registerApp(appOwner1, "test");
    }

    // クレジットをデポジットする
    function test_DepositCredit() public {
        vm.startPrank(appOwner1);
        prexPoint.approve(address(policyManager), 100);
        policyManager.depositCredit(appId, 100);
        vm.stopPrank();

        assertEq(prexPoint.balanceOf(address(policyManager)), 100);

        (, uint256 credit,) = policyManager.apps(appId);

        assertEq(credit, 100);
    }
}
