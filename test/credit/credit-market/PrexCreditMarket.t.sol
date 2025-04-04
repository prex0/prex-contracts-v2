// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PrexCreditMarket} from "../../../src/credit/PrexCreditMarket.sol";
import {CreditMarketSetup} from "./Setup.t.sol";

contract CreditMarketTest is CreditMarketSetup {
    address public minter = vm.addr(6);
    address public recipient = vm.addr(7);
    address public user = vm.addr(8);

    uint256 public appId;

    event PointBoughtForApp(uint256 indexed appId, uint256 amount, uint256 method, bytes orderId);

    function setUp() public virtual override {
        super.setUp();

        appId = policyManager.registerApp(owner, "test");
    }

    function test_mint_for_app() public {
        prexCreditMarket.addMinter(minter);

        vm.startPrank(minter);
        prexCreditMarket.mintForApp(appId, 1000 * 1e12, 0, "test");
        vm.stopPrank();

        (, uint256 credit,) = policyManager.apps(appId);
        assertEq(credit, 1000 * 1e12);
    }
}
