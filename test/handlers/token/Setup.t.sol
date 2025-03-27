// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IssueTokenHandler} from "../../../src/handlers/token/IssueTokenHandler.sol";
import {
    IssueMintableTokenRequest,
    IssueMintableTokenRequestLib
} from "../../../src/handlers/token/IssueMintableTokenRequest.sol";
import {TestUtils} from "../../utils/TestUtils.sol";
import {ERC20} from "../../../lib/solmate/src/tokens/ERC20.sol";
import {OrderReceipt, SignedOrder} from "../../../src/interfaces/IOrderHandler.sol";
import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {MockToken} from "../../mock/MockToken.sol";
import {PrexTokenFactory} from "../../../src/token-factory/PrexTokenFactory.sol";
import {TokenRegistry} from "../../../src/data/TokenRegistry.sol";

contract IssueMintableTokenRequestSetup is Test, TestUtils {
    using IssueMintableTokenRequestLib for IssueMintableTokenRequest;

    IssueTokenHandler public issueTokenHandler;

    function setUp() public virtual override {
        super.setUp();

        PrexTokenFactory tokenFactory = new PrexTokenFactory();
        TokenRegistry tokenRegistry = new TokenRegistry();

        issueTokenHandler = new IssueTokenHandler(address(permit2), address(tokenFactory), address(tokenRegistry));
    }

    function _sign(IssueMintableTokenRequest memory request, uint256 fromPrivateKey)
        internal
        view
        returns (bytes memory)
    {
        bytes32 witness = request.hash();

        return getPermit2Signature(
            fromPrivateKey,
            _toPermit(request),
            address(issueTokenHandler),
            IssueMintableTokenRequestLib.PERMIT2_ORDER_TYPE,
            witness,
            DOMAIN_SEPARATOR
        );
    }

    function _toPermit(IssueMintableTokenRequest memory request)
        internal
        pure
        returns (ISignatureTransfer.PermitTransferFrom memory)
    {
        return ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: address(0), amount: 0}),
            nonce: request.nonce,
            deadline: request.deadline
        });
    }
}
