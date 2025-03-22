// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IOrderHandler, OrderHeader, OrderReceipt} from "../../interfaces/IOrderHandler.sol";
import "./TransferOrder.sol";
import {ERC20} from "../../../lib/solmate/src/tokens/ERC20.sol";
import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import "../../../lib/permit2/src/interfaces/IPermit2.sol";

contract TransferOrderHandler is IOrderHandler {
    using TransferRequestLib for TransferRequest;

    IPermit2 permit2;

    event Transferred(address token, address from, address to, uint256 amount, bytes metadata);

    error InvalidDispatcher();
    error DeadlinePassed();

    uint256 public constant POINTS = 1e18;

    constructor(address _permit2) {
        permit2 = IPermit2(_permit2);
    }

    function execute(
        address _facilitator,
        bytes calldata order,
        bytes calldata signature
    ) external returns (OrderHeader memory, OrderReceipt memory) {
        TransferRequest memory request = abi.decode(order, (TransferRequest));

        bytes32 orderHash = request.hash();

        OrderHeader memory header = request.getOrderHeader();

        _verifyRequest(request, orderHash, signature);

        emit Transferred(request.token, request.sender, request.recipient, request.amount, request.metadata);

        return (header, OrderReceipt(
            address(this),
            orderHash,
            POINTS
        ));
    }
    
    function _verifyRequest(TransferRequest memory request, bytes32 orderHash, bytes memory sig) internal {
        if (address(this) != address(request.dispatcher)) {
            revert InvalidDispatcher();
        }

        if (block.timestamp > request.deadline) {
            revert DeadlinePassed();
        }

        permit2.permitWitnessTransferFrom(
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({token: request.token, amount: request.amount}),
                nonce: request.nonce,
                deadline: request.deadline
            }),
            ISignatureTransfer.SignatureTransferDetails({to: request.recipient, requestedAmount: request.amount}),
            request.sender,
            orderHash,
            TransferRequestLib.PERMIT2_ORDER_TYPE,
            sig
        );
    }
}
