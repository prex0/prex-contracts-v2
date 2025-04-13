// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PrexPoint} from "../../src/credit/PrexPoint.sol";
import {PolicyManagerWrapper} from "../mock/PolicyManagerWrapper.sol";
import {TestUtils} from "../utils/TestUtils.sol";

contract PolicyManagerSetup is Test, TestUtils {
    PrexPoint public prexPoint;
    PolicyManagerWrapper public policyManager;

    address owner = address(this);

    address appOwner1 = address(1);
    address appOwner2 = address(2);

    function setUp() public virtual override {
        super.setUp();

        prexPoint = new PrexPoint("PrexPoint", "PREX", owner, address(permit2));
        policyManager = new PolicyManagerWrapper();

        policyManager.initialize(address(prexPoint), owner);

        // Set policy manager as consumer
        prexPoint.setConsumer(address(policyManager));

        prexPoint.mint(appOwner1, 1000 * 1e6);
        prexPoint.mint(appOwner2, 1000 * 1e6);
    }
}
