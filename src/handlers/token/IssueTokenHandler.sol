// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../interfaces/IOrderHandler.sol";
import "./orders/IssueMintableTokenRequest.sol";
import {ERC20} from "../../../lib/solmate/src/tokens/ERC20.sol";
import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import "../../../lib/permit2/src/interfaces/IPermit2.sol";
import {PrexTokenFactory} from "../../token-factory/PrexTokenFactory.sol";
import {ITokenRegistry} from "../../interfaces/ITokenRegistry.sol";
import {CreateTokenParameters} from "../../token-factory/TokenParams.sol";

/**
 * @notice ユーザのトークンを発行注文を処理するハンドラー
 */
contract IssueTokenHandler is IOrderHandler, PrexTokenFactory {
    using IssueMintableTokenRequestLib for IssueMintableTokenRequest;

    IPermit2 public immutable permit2;
    ITokenRegistry public immutable tokenRegistry;

    uint256 constant POINTS = 10;

    event TokenIssued(
        address indexed token,
        address indexed issuer,
        address recipient,
        string name,
        string symbol,
        uint256 initialSupply,
        bytes32 orderHash
    );

    constructor(address _permit2, address _tokenRegistry) {
        permit2 = IPermit2(_permit2);
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

        CreateTokenParameters memory params = CreateTokenParameters({
            name: request.name,
            symbol: request.symbol,
            initialSupply: request.initialSupply,
            recipient: request.recipient,
            issuer: request.issuer,
            pictureHash: request.pictureHash,
            metadata: request.metadata
        });

        // トークンを発行する
        address token = createMintableCreatorToken(params, address(permit2), address(tokenRegistry));

        emit TokenIssued(
            token,
            request.issuer,
            request.recipient,
            request.name,
            request.symbol,
            request.initialSupply,
            keccak256(order.order)
        );

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
