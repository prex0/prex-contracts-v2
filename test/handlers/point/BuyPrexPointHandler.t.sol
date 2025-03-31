// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {TestPointSetup} from "./Setup.t.sol";
import {BuyPrexPointHandler} from "../../../src/handlers/point/BuyPrexPointHandler.sol";
import {BuyPointOrder, BuyPointOrderLib} from "../../../src/credit/BuyPointOrder.sol";
import {OrderReceipt, SignedOrder} from "../../../src/interfaces/IOrderHandler.sol";
import {MockToken} from "../../mock/MockToken.sol";

contract BuyPrexPointTest is TestPointSetup {
    using BuyPointOrderLib for BuyPointOrder;

    address owner = address(this);

    uint256 internal userPrivateKey = 12345;
    address public user = vm.addr(userPrivateKey);

    address public recipient = address(1001);

    uint256 tmpPrivKey = 70123;
    address tmpPublicKey = vm.addr(tmpPrivKey);

    function setUp() public virtual override {
        super.setUp();

        // mint 100 token to user
        stableToken.mint(user, 100 * 1e18);

        vm.prank(user);
        stableToken.approve(address(permit2), 1e18);
    }

    function test_BuyPrexPoint() public {
        BuyPointOrder memory request = BuyPointOrder({
            dispatcher: address(buyPrexPointHandler),
            policyId: 0,
            buyer: user,
            deadline: 1,
            nonce: 1,
            amount: 1e18
        });

        OrderReceipt memory receipt = buyPrexPointHandler.execute(
            address(this),
            SignedOrder({
                dispatcher: address(buyPrexPointHandler),
                methodId: 1,
                order: abi.encode(request),
                signature: _sign(request, userPrivateKey),
                appSig: bytes(""),
                identifier: bytes32(0)
            }),
            bytes("")
        );

        assertEq(receipt.policyId, 0);
        assertEq(receipt.points, 0);

        assertEq(prexPoint.balanceOf(user), 200000000);
    }
}
