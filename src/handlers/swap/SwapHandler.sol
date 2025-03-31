// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../interfaces/IOrderHandler.sol";
import {PrexSwapRouter} from "../../swap/swap-router/PrexSwapRouter.sol";
import {SwapRequest, SwapRequestLib} from "./SwapOrder.sol";
import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Owned} from "../../../lib/solmate/src/auth/Owned.sol";

/**
 * @notice トークンスワップを実行するための、基本的なハンドラー
 */
contract SwapHandler is IOrderHandler, PrexSwapRouter, Owned {
    using SwapRequestLib for SwapRequest;

    event SwapOrderFilled(
        address indexed swapper,
        address recipient,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    constructor(
        address _universalRouter,
        address _loyaltyConverter,
        address _pumConverter,
        address _permit2,
        address _owner
    ) PrexSwapRouter(_universalRouter, _loyaltyConverter, _pumConverter, _permit2) Owned(_owner) {}

    function execute(address, SignedOrder calldata order, bytes calldata facilitatorData)
        external
        returns (OrderReceipt memory)
    {
        SwapRequest memory request = abi.decode(order.order, (SwapRequest));

        // オーダーのリクエストを検証し、トークンをコントラクトに移動する
        _verifyRequest(request, order.signature);

        // スワップを実行する
        _executeSwap(facilitatorData);

        // 交換後のトークンをユーザに送付する
        IERC20(request.tokenOut).transfer(request.recipient, request.amountOut);

        emit SwapOrderFilled(
            request.swapper, request.recipient, request.tokenIn, request.tokenOut, request.amountIn, request.amountOut
        );

        return request.getOrderReceipt();
    }

    /**
     * @notice 残ったトークンを送付する
     * @dev オーナーのみが実行できる
     * @param token トークンのアドレス
     * @param recipient 受取人のアドレス
     */
    function sweepToken(address token, address recipient) external onlyOwner {
        _sweepToken(token, recipient);
    }

    function _sweepToken(address token, address recipient) internal {
        uint256 leftAmount = IERC20(token).balanceOf(address(this));
        if (leftAmount > 0) {
            IERC20(token).transfer(recipient, leftAmount);
        }
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
