// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../interfaces/IOrderHandler.sol";
import "./IssueMintableTokenRequest.sol";
import {ERC20} from "../../../lib/solmate/src/tokens/ERC20.sol";
import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import "../../../lib/permit2/src/interfaces/IPermit2.sol";
import {PrexTokenFactory} from "../../token-factory/PrexTokenFactory.sol";
import {ITokenRegistry} from "../../interfaces/ITokenRegistry.sol";
import {ICreatorCoin} from "../../interfaces/ICreatorCoin.sol";

/**
 * @notice ユーザのトークンを発行注文を処理するハンドラー
 */
contract IssueTokenHandler is IOrderHandler {
    using IssueMintableTokenRequestLib for IssueMintableTokenRequest;

    IPermit2 public immutable permit2;
    PrexTokenFactory public immutable tokenFactory;
    ITokenRegistry public immutable tokenRegistry;

    uint256 constant POINTS = 10;

    constructor(address _permit2, address _tokenFactory, address _tokenRegistry) {
        permit2 = IPermit2(_permit2);
        tokenFactory = PrexTokenFactory(_tokenFactory);
        tokenRegistry = ITokenRegistry(_tokenRegistry);
    }

    /**
     * @notice ユーザのトークンを発行注文を処理する
     * @param order オーダーデータ
     * @return 注文の結果
     */
    function execute(address, SignedOrder calldata order, bytes calldata) external returns (OrderReceipt memory) {
        IssueMintableTokenRequest memory request = abi.decode(order.order, (IssueMintableTokenRequest));

        // オーダーのリクエストを検証する
        _verifyRequest(request, order.signature);

        // トークンを発行する
        address token = tokenFactory.createMintableCreatorToken(
            request.name,
            request.symbol,
            request.initialSupply,
            request.recipient,
            request.issuer,
            address(permit2),
            address(tokenRegistry)
        );

        // トークンの画像と詳細を更新する
        ICreatorCoin(token).updateTokenDetails(request.pictureHash, request.metadata);

        return request.getOrderReceipt(POINTS);
    }

    /**
     * @notice オーダーのリクエストを検証する
     * @param request オーダーのリクエスト
     * @param sig オーダーの署名
     */
    function _verifyRequest(IssueMintableTokenRequest memory request, bytes memory sig) internal {
        if (address(this) != address(request.dispatcher)) {
            revert InvalidDispatcher();
        }

        if (block.timestamp > request.deadline) {
            revert DeadlinePassed();
        }

        permit2.permitWitnessTransferFrom(
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({token: address(0), amount: 0}),
                nonce: request.nonce,
                deadline: request.deadline
            }),
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: 0}),
            request.issuer,
            request.hash(),
            IssueMintableTokenRequestLib.PERMIT2_ORDER_TYPE,
            sig
        );
    }
}
