// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SwapHandler} from "../../../src/handlers/swap/SwapHandler.sol";
import {SwapRequest, SwapRequestLib} from "../../../src/handlers/swap/SwapOrder.sol";
import {TestUtils} from "../../utils/TestUtils.sol";
import {ERC20} from "../../../lib/solmate/src/tokens/ERC20.sol";
import {OrderReceipt, SignedOrder} from "../../../src/interfaces/IOrderHandler.sol";
import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {MockToken} from "../../mock/MockToken.sol";
import {MockUniversalRouter} from "../../mock/MockUniversalRouter.sol";
import {TokenRegistry} from "../../../src/data/TokenRegistry.sol";

contract MockPumConverter {
    MockToken public immutable pumPoint;

    constructor() {
        pumPoint = new MockToken();
    }
}

contract MockLoyaltyConverter {
    MockToken public immutable dai;

    constructor() {
        dai = new MockToken();
    }
}

contract SwapHandlerSetup is Test, TestUtils {
    using SwapRequestLib for SwapRequest;

    MockToken public tokenIn;
    MockToken public tokenOut;
    MockUniversalRouter public universalRouter;
    SwapHandler public swapHandler;

    function setUp() public virtual override {
        super.setUp();

        tokenIn = new MockToken();
        tokenOut = new MockToken();
        universalRouter = new MockUniversalRouter(address(tokenOut));

        MockPumConverter pumConverter = new MockPumConverter();
        MockLoyaltyConverter loyaltyConverter = new MockLoyaltyConverter();

        swapHandler = new SwapHandler(
            address(universalRouter), address(loyaltyConverter), address(pumConverter), address(permit2), address(this)
        );
    }

    function _sign(SwapRequest memory request, uint256 fromPrivateKey) internal view returns (bytes memory) {
        bytes32 witness = request.hash();

        return getPermit2Signature(
            fromPrivateKey,
            _toPermit(request),
            address(swapHandler),
            SwapRequestLib.PERMIT2_ORDER_TYPE,
            witness,
            DOMAIN_SEPARATOR
        );
    }

    function _toPermit(SwapRequest memory request)
        internal
        pure
        returns (ISignatureTransfer.PermitTransferFrom memory)
    {
        return ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: request.tokenIn, amount: request.amountIn}),
            nonce: request.nonce,
            deadline: request.deadline
        });
    }
}
