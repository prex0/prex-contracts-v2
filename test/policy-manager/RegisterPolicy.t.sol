// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PolicyManagerSetup} from "./Setup.t.sol";
import {PolicyManager} from "../../src/policy-manager/PolicyManager.sol";
import {IPolicyErrors} from "../../src/interfaces/IPolicyErrors.sol";

contract RegisterPolicyTest is PolicyManagerSetup {
    // テスト確認用のポリシー登録イベント
    event PolicyRegistered(
        uint256 appId, uint256 policyId, address validator, address publicKey, bytes policyParams, string policyName
    );

    function setUp() public virtual override {
        super.setUp();
    }

    // ポリシーを登録する
    function test_RegisterPolicy() public {
        uint256 appId = policyManager.registerApp(appOwner1, "test");

        vm.startPrank(appOwner1);

        vm.expectEmit(address(policyManager));
        emit PolicyRegistered(appId, 1, address(0), address(0), "", "test");
        policyManager.registerPolicy(appId, address(0), address(0), "", "test");
        vm.stopPrank();
    }

    // 不正なアプリオーナーはポリシーを登録できない
    function test_RegisterPolicy_InvalidAppOwner() public {
        uint256 appId = policyManager.registerApp(appOwner1, "test");

        vm.startPrank(appOwner2);

        vm.expectRevert(abi.encodeWithSelector(IPolicyErrors.InvalidAppOwner.selector));
        policyManager.registerPolicy(appId, address(0), address(0), "", "test");

        vm.stopPrank();
    }
}
