// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PolicyManagerSetup} from "./Setup.t.sol";
import {PolicyManager} from "../../src/policy-manager/PolicyManager.sol";
import {IPolicyErrors} from "../../src/interfaces/IPolicyErrors.sol";

contract DeregisterPolicyTest is PolicyManagerSetup {
    uint256 policyId;

    function setUp() public virtual override {
        super.setUp();

        uint256 appId = policyManager.registerApp(appOwner1);

        vm.startPrank(appOwner1);
        policyId = policyManager.registerPolicy(address(0), address(0), appId, "");
        vm.stopPrank();
    }

    // ポリシーを削除する
    function test_DeregisterPolicy() public {
        vm.startPrank(appOwner1);
        policyManager.deregisterPolicy(policyId);
        vm.stopPrank();
    }

    // 不正なポリシーオーナーはポリシーを削除できない
    function test_DeregisterPolicy_InvalidPolicyOwner() public {
        vm.startPrank(appOwner2);

        vm.expectRevert(abi.encodeWithSelector(IPolicyErrors.InvalidPolicyOwner.selector));
        policyManager.deregisterPolicy(policyId);

        vm.stopPrank();
    }
}
