// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PolicyManagerSetup} from "./SetUp.t.sol";

contract RegisterPolicyTest is PolicyManagerSetup {
    function setUp() public virtual override {
        super.setUp();
    }

    function test_RegisterPolicy() public {
        uint256 appId = policyManager.registerApp(address(this));

        policyManager.registerPolicy(address(0), address(0), appId);
    }
}
