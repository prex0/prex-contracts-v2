// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {SwapHandlerSetup} from "./Setup.t.sol";
import {SwapRequest} from "../../../src/handlers/swap/SwapOrder.sol";
import {ERC20} from "../../../lib/solmate/src/tokens/ERC20.sol";
import {OrderReceipt, SignedOrder} from "../../../src/interfaces/IOrderHandler.sol";
import {MockToken} from "../../mock/MockToken.sol";
import {ISwapRouter} from "../../../src/interfaces/ISwapRouter.sol";

contract SwapHandlerTest is SwapHandlerSetup {
    address owner = address(this);
    uint256 internal userPrivateKey = 12345;
    address public user = vm.addr(userPrivateKey);

    address public recipient = address(1001);

    function setUp() public virtual override {
        super.setUp();

        tokenIn.mint(user, 100 * 1e18);

        vm.startPrank(user);
        tokenIn.approve(address(permit2), 100 * 1e18);
        vm.stopPrank();
    }

    function testSwap() public {
        SwapRequest memory request = SwapRequest({
            dispatcher: address(swapHandler),
            policyId: 0,
            swapper: user,
            recipient: recipient,
            deadline: 1,
            nonce: 1,
            exactIn: true,
            tokenIn: address(tokenIn),
            tokenOut: address(tokenOut),
            amountIn: 1e18,
            amountOut: 1e18
        });

        OrderReceipt memory receipt = swapHandler.execute(
            address(this),
            SignedOrder({
                dispatcher: address(swapHandler),
                methodId: 0,
                order: abi.encode(request),
                signature: _sign(request, userPrivateKey),
                appSig: bytes(""),
                identifier: bytes32(0)
            }),
            encodeFacilitationData()
        );

        assertEq(receipt.policyId, 0);
        assertEq(receipt.points, 0);
    }

    function encodeFacilitationData() internal view returns (bytes memory) {
        bytes memory data =
            abi.encodeWithSelector(bytes4(keccak256("execute(address,uint256)")), address(swapHandler), 1e18);

        return abi.encode(new address[](0), ISwapRouter.ConvertParams(ISwapRouter.ConvertType.NOOP, address(0)), data);
    }
}
