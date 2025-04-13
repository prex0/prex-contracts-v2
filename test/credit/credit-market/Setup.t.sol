// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PrexCreditMarket} from "../../../src/credit/PrexCreditMarket.sol";
import {MockToken} from "../../mock/MockToken.sol";
import {ERC20} from "../../../lib/solmate/src/tokens/ERC20.sol";
import {OrderExecutor} from "../../../src/OrderExecutor.sol";

contract CreditMarketSetup is Test {
    PrexCreditMarket public prexCreditMarket;
    ERC20 public prexCredit;
    MockToken public stableToken;
    OrderExecutor public policyManager;

    address public owner = address(this);
    address public feeRecipient = vm.addr(5);

    function setUp() public virtual {
        prexCreditMarket = new PrexCreditMarket(owner, address(0), feeRecipient);

        stableToken = new MockToken();

        prexCreditMarket.setStableToken(address(stableToken));

        prexCredit = ERC20(address(prexCreditMarket.point()));

        policyManager = new OrderExecutor();

        policyManager.initialize(address(prexCredit), owner);

        prexCreditMarket.setOrderExecutor(address(policyManager));
    }
}
