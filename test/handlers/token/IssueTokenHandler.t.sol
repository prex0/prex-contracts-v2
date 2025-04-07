// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IssueMintableTokenRequestSetup} from "./Setup.t.sol";
import {IssueMintableTokenRequest} from "../../../src/handlers/token/orders/IssueMintableTokenRequest.sol";
import {ERC20} from "../../../lib/solmate/src/tokens/ERC20.sol";
import {OrderReceipt, SignedOrder} from "../../../src/interfaces/IOrderHandler.sol";

contract IssueTokenHandlerTest is IssueMintableTokenRequestSetup {
    address owner = address(this);
    uint256 internal userPrivateKey = 12345;
    address public user = vm.addr(userPrivateKey);

    address public recipient = address(1001);

    function setUp() public virtual override {
        super.setUp();
    }

    function testIssueToken() public {
        IssueMintableTokenRequest memory request = IssueMintableTokenRequest({
            dispatcher: address(issueTokenHandler),
            policyId: 0,
            issuer: user,
            recipient: recipient,
            deadline: 1,
            nonce: 1,
            initialSupply: 1e18,
            name: "test",
            symbol: "TEST",
            pictureHash: bytes32(0),
            metadata: ""
        });

        OrderReceipt memory receipt = issueTokenHandler.execute(
            address(this),
            SignedOrder({
                dispatcher: address(issueTokenHandler),
                methodId: 0,
                order: abi.encode(request),
                signature: _sign(request, userPrivateKey),
                appSig: bytes(""),
                identifier: bytes32(0)
            }),
            bytes("")
        );

        assertEq(receipt.policyId, 0);
        assertEq(receipt.points, 200);
    }
}
