// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {BuyPrexPointHandler} from "../../../src/handlers/point/BuyPrexPointHandler.sol";
import {BuyPointOrder, BuyPointOrderLib} from "../../../src/credit/BuyPointOrder.sol";
import {TestUtils} from "../../utils/TestUtils.sol";
import {ERC20} from "../../../lib/solmate/src/tokens/ERC20.sol";
import {OrderReceipt, SignedOrder} from "../../../src/interfaces/IOrderHandler.sol";
import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {MockToken} from "../../mock/MockToken.sol";
import {PrexPoint} from "../../../src/credit/PrexPoint.sol";

contract TestPointSetup is Test, TestUtils {
    using BuyPointOrderLib for BuyPointOrder;

    BuyPrexPointHandler public buyPrexPointHandler;
    PrexPoint public prexPoint;
    MockToken public stableToken;

    function setUp() public virtual override {
        super.setUp();

        stableToken = new MockToken();

        buyPrexPointHandler = new BuyPrexPointHandler(address(this), address(permit2), address(this));
        buyPrexPointHandler.setStableToken(address(stableToken));

        prexPoint = buyPrexPointHandler.point();
    }

    function _sign(BuyPointOrder memory request, uint256 fromPrivateKey) internal view returns (bytes memory) {
        bytes32 witness = request.hash();

        return getPermit2Signature(
            fromPrivateKey,
            _toPermit(request),
            address(buyPrexPointHandler),
            BuyPointOrderLib.PERMIT2_ORDER_TYPE,
            witness,
            DOMAIN_SEPARATOR
        );
    }

    function _toPermit(BuyPointOrder memory request)
        internal
        view
        returns (ISignatureTransfer.PermitTransferFrom memory)
    {
        return ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: address(stableToken), amount: request.amount}),
            nonce: request.nonce,
            deadline: request.deadline
        });
    }
}
