// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PolicyManagerSetup} from "./Setup.t.sol";
import {PolicyManager} from "../../src/policy-manager/PolicyManager.sol";
import {IPolicyErrors} from "../../src/interfaces/IPolicyErrors.sol";

contract RegisterAppTest is PolicyManagerSetup {
    event AppRegistered(uint256 appId, address owner, string appName);

    function setUp() public virtual override {
        super.setUp();
    }

    // アプリを登録する
    function test_RegisterApp() public {
        vm.expectEmit(true, true, true, true);
        emit AppRegistered(1, appOwner1, "test");
        uint256 appId = policyManager.registerApp(appOwner1, "test");

        assertEq(appId, 1);
    }
}
