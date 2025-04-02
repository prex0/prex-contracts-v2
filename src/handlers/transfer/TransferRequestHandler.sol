// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IOrderHandler, OrderReceipt, SignedOrder} from "../../interfaces/IOrderHandler.sol";
import {OrderHeader} from "../../interfaces/IOrderExecutor.sol";
import "./TransferRequest.sol";
import {ERC20} from "../../../lib/solmate/src/tokens/ERC20.sol";
import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import "../../../lib/permit2/src/interfaces/IPermit2.sol";

contract TransferRequestHandler is IOrderHandler {
    using TransferRequestLib for TransferRequest;

    IPermit2 permit2;

    event Transferred(
        address token, address from, address to, uint256 amount, uint256 category, bytes metadata, bytes32 orderHash
    );

    uint256 public constant POINTS = 1;

    constructor(address _permit2) {
        permit2 = IPermit2(_permit2);
    }

    /**
     * @notice トークンの送付オーダーを処理する
     * @param order 注文
     * @return 注文の結果
     */
    function execute(address, SignedOrder calldata order, bytes calldata) external returns (OrderReceipt memory) {
        TransferRequest memory request = abi.decode(order.order, (TransferRequest));

        // オーダーのリクエストを検証する
        _verifyRequest(request, order.signature);

        emit Transferred(
            request.token,
            request.sender,
            request.recipient,
            request.amount,
            request.category,
            request.metadata,
            keccak256(order.order)
        );

        return request.getOrderReceipt(POINTS);
    }

    /**
     * @notice オーダーのリクエストを検証する
     * @param request オーダーのリクエスト
     * @param sig オーダーの署名
     */
    function _verifyRequest(TransferRequest memory request, bytes memory sig) internal {
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
            request.hash(),
            TransferRequestLib.PERMIT2_ORDER_TYPE,
            sig
        );
    }
}
