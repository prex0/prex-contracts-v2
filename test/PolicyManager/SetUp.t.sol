// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PrexPoint} from "../../src/credit/PrexPoint.sol";
import {PolicyManager} from "../../src/PolicyManager.sol";

contract PolicyManagerSetup is Test {
    PrexPoint public prexPoint;
    PolicyManager public policyManager;

    address owner = address(this);
    uint256 internal userPrivateKey = 12345;
    address public user = vm.addr(userPrivateKey);
    address public permit2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    function setUp() public virtual {
        prexPoint = new PrexPoint(owner, address(permit2));
        policyManager = new PolicyManager(address(prexPoint));

        prexPoint.setOrderExecutor(address(policyManager));

        prexPoint.mint(user, 1000 * 1e6);
    }
}
