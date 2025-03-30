// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../interfaces/IOrderHandler.sol";
import {PrexSwapRouter} from "../../swap/swap-router/PrexSwapRouter.sol";
import {SwapRequest, SwapRequestLib} from "./SwapOrder.sol";
import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";

contract SwapHandler is IOrderHandler, PrexSwapRouter {
    using SwapRequestLib for SwapRequest;

    uint256 public constant POINTS = 1;

    constructor(address _universalRouter, address _loyaltyConverter, address _pumConverter, address _permit2)
        PrexSwapRouter(_universalRouter, _loyaltyConverter, _pumConverter, _permit2)
    {}

    function execute(address, SignedOrder calldata order, bytes calldata facilitatorData)
        external
        returns (OrderReceipt memory)
    {
        SwapRequest memory request = abi.decode(order.order, (SwapRequest));

        _verifyRequest(request, order.signature);

        _executeSwap(facilitatorData);

        return request.getOrderReceipt(POINTS);
    }

    /**
     * @notice オーダーのリクエストを検証する
     * @param request オーダーのリクエスト
     * @param sig オーダーの署名
     */
    function _verifyRequest(SwapRequest memory request, bytes memory sig) internal {
        if (address(this) != address(request.dispatcher)) {
            revert InvalidDispatcher();
        }

        if (block.timestamp > request.deadline) {
            revert DeadlinePassed();
        }

        permit2.permitWitnessTransferFrom(
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({token: request.tokenIn, amount: request.amountIn}),
                nonce: request.nonce,
                deadline: request.deadline
            }),
            ISignatureTransfer.SignatureTransferDetails({to: request.recipient, requestedAmount: request.amountIn}),
            request.swapper,
            request.hash(),
            SwapRequestLib.PERMIT2_ORDER_TYPE,
            sig
        );
    }
}
