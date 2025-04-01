// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PrexPointMarket} from "../../src/credit/PrexPointMarket.sol";
import {MockToken} from "../mock/MockToken.sol";
import {ERC20} from "../../lib/solmate/src/tokens/ERC20.sol";

contract PointMarketSetup is Test {
    PrexPointMarket public prexPointMarket;
    ERC20 public prexPoint;
    MockToken public stableToken;

    address public owner = address(this);
    address public feeRecipient = vm.addr(5);

    function setUp() public virtual {
        prexPointMarket = new PrexPointMarket("Prex Point Market", "PPM", owner, address(0), feeRecipient);

        stableToken = new MockToken();

        prexPointMarket.setStableToken(address(stableToken));

        prexPoint = ERC20(address(prexPointMarket.point()));
    }
}
