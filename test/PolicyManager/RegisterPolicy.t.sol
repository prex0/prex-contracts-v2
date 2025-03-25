// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PolicyManagerSetup} from "./Setup.t.sol";
import {PolicyManager} from "../../src/policy-manager/PolicyManager.sol";
import {IPolicyErrors} from "../../src/interfaces/IPolicyErrors.sol";

contract RegisterPolicyTest is PolicyManagerSetup {
    function setUp() public virtual override {
        super.setUp();
    }

    // ポリシーを登録する
    function test_RegisterPolicy() public {
        uint256 appId = policyManager.registerApp(appOwner1);

        vm.startPrank(appOwner1);
        policyManager.registerPolicy(address(0), address(0), appId, "");
        vm.stopPrank();
    }

    // 不正なアプリオーナーはポリシーを登録できない
    function test_RegisterPolicy_InvalidAppOwner() public {
        uint256 appId = policyManager.registerApp(appOwner1);

        vm.startPrank(appOwner2);

        vm.expectRevert(abi.encodeWithSelector(IPolicyErrors.InvalidAppOwner.selector));
        policyManager.registerPolicy(address(0), address(0), appId, "");

        vm.stopPrank();
    }
}
