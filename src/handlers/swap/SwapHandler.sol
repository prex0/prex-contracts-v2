// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../interfaces/IOrderHandler.sol";
import {PrexSwapRouter} from "../../swap/swap-router/PrexSwapRouter.sol";
import {SwapRequest, SwapRequestLib} from "./SwapOrder.sol";
import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract SwapHandler is IOrderHandler, PrexSwapRouter {
    using SwapRequestLib for SwapRequest;

    error TooMuchSlippage();

    event SwapOrderFilled(
        address indexed swapper,
        address recipient,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

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

        //　このコントラクトにある状態として
        if (request.exactIn) {
            // request.amountOut is minAmountOut
            uint256 amountOut = IERC20(request.tokenOut).balanceOf(address(this));

            if (amountOut < request.amountOut) {
                revert TooMuchSlippage();
            }

            IERC20(request.tokenOut).transfer(request.recipient, amountOut);

            emit SwapOrderFilled(
                request.swapper, request.recipient, request.tokenIn, request.tokenOut, request.amountIn, amountOut
            );
        } else {
            IERC20(request.tokenOut).transfer(request.recipient, request.amountOut);

            emit SwapOrderFilled(
                request.swapper,
                request.recipient,
                request.tokenIn,
                request.tokenOut,
                request.amountIn,
                request.amountOut
            );
        }

        return request.getOrderReceipt();
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
