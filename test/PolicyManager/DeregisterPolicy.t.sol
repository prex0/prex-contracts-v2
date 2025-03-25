// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PolicyManagerSetup} from "./Setup.t.sol";
import {PolicyManager} from "../../src/PolicyManager.sol";

contract RegisterPolicyTest is PolicyManagerSetup {
    uint256 policyId;

    function setUp() public virtual override {
        super.setUp();

        uint256 appId = policyManager.registerApp(appOwner1);

        vm.startPrank(appOwner1);
        policyId = policyManager.registerPolicy(address(0), address(0), appId, "");
        vm.stopPrank();
    }

    function test_DeregisterPolicy() public {
        vm.startPrank(appOwner1);
        policyManager.deregisterPolicy(policyId);
        vm.stopPrank();
    }

    function test_DeregisterPolicy_InvalidPolicyOwner() public {
        vm.startPrank(appOwner2);
        vm.expectRevert(PolicyManager.InvalidPolicyOwner.selector);

        policyManager.deregisterPolicy(policyId);

        vm.stopPrank();
    }
}
