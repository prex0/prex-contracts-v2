// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../interfaces/IOrderHandler.sol";
import "./orders/IssueCreatorTokenRequest.sol";
import {ERC20} from "../../../lib/solmate/src/tokens/ERC20.sol";
import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import "../../../lib/permit2/src/interfaces/IPermit2.sol";
import {PrexTokenFactory} from "../../token-factory/PrexTokenFactory.sol";
import {ITokenRegistry} from "../../interfaces/ITokenRegistry.sol";
import {CreateTokenParameters} from "../../token-factory/TokenParams.sol";
import {PumController} from "../../swap/PumController.sol";

/**
 * @notice ユーザのトークンを発行注文を処理するハンドラー
 */
contract IssueCreatorTokenHandler is IOrderHandler, PumController {
    using IssueCreatorTokenRequestLib for IssueCreatorTokenRequest;

    uint256 public points = 0;

    address public orderExecutor;

    error CallerMustBeOrderExecutor();

    modifier onlyOrderExecutor() {
        if (msg.sender != orderExecutor) {
            revert CallerMustBeOrderExecutor();
        }
        _;
    }

    function initialize(address _owner, address _prexPoint, address _positionManager, address _tokenRegistry, address _creatorTokenFactory, address _permit2)
        external
        initializer
    {
        __PumController_init(_owner, _prexPoint, _positionManager, _tokenRegistry, _creatorTokenFactory, _permit2);
    }

    /**
     * @notice ポイントを設定する
     * @param _points ポイント
     */
    function setPoints(uint256 _points) external onlyOwner {
        points = _points;
    }

    /**
     * @notice オーダー実行者を設定する
     * @param _orderExecutor オーダー実行者
     */
    function setOrderExecutor(address _orderExecutor) external onlyOwner {
        orderExecutor = _orderExecutor;
    }

    /**
     * @notice ユーザのトークンを発行注文を処理する
     * @param order オーダーデータ
     * @return 注文の結果
     */
    function execute(address, SignedOrder calldata order, bytes calldata)
        external
        onlyOrderExecutor
        returns (OrderReceipt memory)
    {
        IssueCreatorTokenRequest memory request = abi.decode(order.order, (IssueCreatorTokenRequest));

        // オーダーのリクエストを検証する
        _verifyRequest(request, order.signature);

        _issuePumToken(request.issuer, request.name, request.symbol, request.pictureHash, request.metadata);

        return request.getOrderReceipt(points);
    }

    /**
     * @notice オーダーのリクエストを検証する
     * @param request オーダーのリクエスト
     * @param sig オーダーの署名
     */
    function _verifyRequest(IssueCreatorTokenRequest memory request, bytes memory sig) internal {
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
            IssueCreatorTokenRequestLib.PERMIT2_ORDER_TYPE,
            sig
        );
    }
}
