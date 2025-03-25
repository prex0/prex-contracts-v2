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

contract IssueTokenHandler is IOrderHandler {
    using IssueMintableTokenRequestLib for IssueMintableTokenRequest;

    IPermit2 public immutable permit2;
    PrexTokenFactory public immutable tokenFactory;
    ITokenRegistry public immutable tokenRegistry;

    uint256 constant POINTS = 20 * 1e6;

    error InvalidDispatcher();
    error DeadlinePassed();

    constructor(address _permit2, address _tokenFactory, address _tokenRegistry) {
        permit2 = IPermit2(_permit2);
        tokenFactory = PrexTokenFactory(_tokenFactory);
        tokenRegistry = ITokenRegistry(_tokenRegistry);
    }

    function execute(address, SignedOrder calldata order, bytes calldata)
        external
        returns (OrderReceipt memory)
    {
        // TODO: Implement issue token logic
        IssueMintableTokenRequest memory request = abi.decode(order.order, (IssueMintableTokenRequest));

        _verifyRequest(request, order.signature);

        address token = tokenFactory.createMintableCreatorToken(
            request.name,
            request.symbol,
            request.initialSupply,
            request.recipient,
            request.sender,
            address(permit2),
            address(tokenRegistry)
        );

        ICreatorCoin(token).updateTokenDetails(request.pictureHash, request.metadata);

        return request.getOrderReceipt(POINTS);
    }

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
            request.sender,
            request.hash(),
            IssueMintableTokenRequestLib.PERMIT2_ORDER_TYPE,
            sig
        );
    }
}
