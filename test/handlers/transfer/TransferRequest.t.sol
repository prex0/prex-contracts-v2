// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {TransferRequestSetup} from "./Setup.t.sol";
import {TransferRequestHandler} from "../../../src/handlers/transfer/TransferRequestHandler.sol";
import {TransferRequest, TransferRequestLib} from "../../../src/handlers/transfer/TransferRequest.sol";
import {TestUtils} from "../../utils/TestUtils.sol";
import {ERC20} from "../../../lib/solmate/src/tokens/ERC20.sol";
import {OrderReceipt, SignedOrder} from "../../../src/interfaces/IOrderHandler.sol";
import {OrderHeader} from "../../../src/interfaces/IOrderExecutor.sol";
import {MockToken} from "../../mock/MockToken.sol";

contract TransferRequestTest is TransferRequestSetup {
    using TransferRequestLib for TransferRequest;

    MockToken mockToken;

    address owner = address(this);
    uint256 internal userPrivateKey = 12345;
    address public user = vm.addr(userPrivateKey);

    address public recipient = address(1001);

    function setUp() public virtual override {
        super.setUp();

        mockToken = new MockToken();

        // mint 100 token to user
        mockToken.mint(user, 100 * 1e18);

        vm.prank(user);
        mockToken.approve(address(permit2), 1e18);
    }

    function test_Execute() public {
        TransferRequest memory request = TransferRequest({
            dispatcher: address(transferRequestHandler),
            policyId: 0,
            sender: user,
            recipient: recipient,
            deadline: 1,
            nonce: 1,
            amount: 1e18,
            token: address(mockToken),
            category: 0,
            metadata: bytes("")
        });

        OrderReceipt memory receipt = transferRequestHandler.execute(
            address(this),
            SignedOrder({
                dispatcher: address(transferRequestHandler),
                methodId: 0,
                order: abi.encode(request),
                signature: _sign(request, userPrivateKey),
                appSig: bytes("")
            })
        );

        assertEq(receipt.policyId, 0);
        assertEq(receipt.points, 1e6);

        assertEq(ERC20(address(mockToken)).balanceOf(recipient), 1e18);
    }
}
