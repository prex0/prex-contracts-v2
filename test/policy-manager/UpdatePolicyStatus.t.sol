// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PolicyManagerSetup} from "./Setup.t.sol";
import {PolicyManager} from "../../src/policy-manager/PolicyManager.sol";
import {IPolicyErrors} from "../../src/interfaces/IPolicyErrors.sol";

contract UpdatePolicyStatusTest is PolicyManagerSetup {
    uint256 policyId;

    function setUp() public virtual override {
        super.setUp();

        uint256 appId = policyManager.registerApp(appOwner1, "test");

        vm.startPrank(appOwner1);
        policyId = policyManager.registerPolicy(appId, address(0), address(0), "", "test");
        vm.stopPrank();
    }

    // ポリシーを削除する
    function test_UpdatePolicyStatus() public {
        vm.startPrank(appOwner1);
        policyManager.updatePolicyStatus(policyId, false);
        vm.stopPrank();
    }

    // 不正なポリシーオーナーはポリシーを削除できない
    function test_UpdatePolicyStatus_InvalidPolicyOwner() public {
        vm.startPrank(appOwner2);

        vm.expectRevert(abi.encodeWithSelector(IPolicyErrors.InvalidPolicyOwner.selector));
        policyManager.updatePolicyStatus(policyId, false);

        vm.stopPrank();
    }
}
