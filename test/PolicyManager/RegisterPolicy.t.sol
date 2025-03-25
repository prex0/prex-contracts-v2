// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PolicyManagerSetup} from "./Setup.t.sol";
import {PolicyManager} from "../../src/PolicyManager.sol";

contract RegisterPolicyTest is PolicyManagerSetup {
    function setUp() public virtual override {
        super.setUp();
    }

    function test_RegisterPolicy() public {
        uint256 appId = policyManager.registerApp(appOwner1);

        vm.startPrank(appOwner1);
        policyManager.registerPolicy(address(0), address(0), appId, "");
        vm.stopPrank();
    }

    function test_RegisterPolicy_InvalidAppOwner() public {
        uint256 appId = policyManager.registerApp(appOwner1);

        vm.startPrank(appOwner2);
        vm.expectRevert(PolicyManager.InvalidAppOwner.selector);

        policyManager.registerPolicy(address(0), address(0), appId, "");

        vm.stopPrank();
    }
}
