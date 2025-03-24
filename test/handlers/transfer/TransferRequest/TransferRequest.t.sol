// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {TransferRequestHandler} from "../../../../src/handlers/transfer/TransferRequestHandler.sol";
import {TransferRequest, TransferRequestLib} from "../../../../src/handlers/transfer/TransferRequest.sol";
import {TestUtils} from "../../../utils/TestUtils.sol";
import {ERC20} from "../../../../lib/solmate/src/tokens/ERC20.sol";
import {OrderHeader, OrderReceipt} from "../../../../src/interfaces/IOrderHandler.sol";
import "../../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {MockToken} from "../../../mock/MockToken.sol";

contract TransferRequestTest is Test, TestUtils {
    using TransferRequestLib for TransferRequest;

    TransferRequestHandler public transferRequestHandler;

    MockToken mockToken;

    address owner = address(this);
    uint256 internal userPrivateKey = 12345;
    address public user = vm.addr(userPrivateKey);

    address public recipient = address(1001);

    function setUp() public virtual override {
        super.setUp();

        transferRequestHandler = new TransferRequestHandler(address(permit2));

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

        (OrderHeader memory header, OrderReceipt memory receipt) = transferRequestHandler.execute(
            address(transferRequestHandler),
            abi.encode(request),
            _sign(request, userPrivateKey)
        );

        assertEq(header.policyId, 0);
        assertEq(receipt.points, 1e6);

        assertEq(ERC20(address(mockToken)).balanceOf(recipient), 1e18);
    }

    function _sign(TransferRequest memory request, uint256 fromPrivateKey) internal view returns (bytes memory) {
        bytes32 witness = request.hash();

        return getPermit2Signature(
            fromPrivateKey,
            _toPermit(request),
            address(transferRequestHandler),
            TransferRequestLib.PERMIT2_ORDER_TYPE,
            witness,
            DOMAIN_SEPARATOR
        );
    }

    function _toPermit(TransferRequest memory request)
        internal
        pure
        returns (ISignatureTransfer.PermitTransferFrom memory)
    {
        return ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({
                token: address(request.token),
                amount: request.amount
            }),
            nonce: request.nonce,
            deadline: request.deadline
        });
    }
}
