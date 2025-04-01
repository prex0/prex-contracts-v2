// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PrexSwapRouter} from "../../../src/swap/swap-router/PrexSwapRouter.sol";
import {Plan, Planner} from "v4-periphery/test/shared/Planner.sol";
import {Actions} from "v4-periphery/src/libraries/Actions.sol";
import {PathKey} from "v4-periphery/src/libraries/PathKey.sol";
import {IV4Router} from "v4-periphery/src/interfaces/IV4Router.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Currency, CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {LiquidityAmounts} from "v4-periphery/src/libraries/LiquidityAmounts.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {CreatorTokenFactory} from "../../../src/token-factory/CreatorTokenFactory.sol";
import {PrexPoint} from "../../../src/credit/PrexPoint.sol";
import {PumHook} from "../../../src/swap/hooks/PumHook.sol";
import {ISwapRouter} from "../../../src/interfaces/ISwapRouter.sol";
import {SwapRouterSetup} from "./Setup.t.sol";
import {SignedOrder} from "../../../src/interfaces/IOrderExecutor.sol";
import {CreateTokenParameters} from "../../../src/token-factory/CreatorTokenFactory.sol";

interface IPositionManager {
    function poolManager() external view returns (address);
}

contract LoyaltyControllerTest is SwapRouterSetup {
    using Planner for Plan;
    using CurrencyLibrary for Currency;

    bytes4 private constant EXECUTE_SELECTOR = bytes4(keccak256("execute(bytes,bytes[],uint256)"));

    uint256 userPrivateKey = 12;
    address userAddress = vm.addr(userPrivateKey);

    address issuer = address(0x1234567890123456789012345678901234567890);
    address feeRecipient = vm.addr(500);

    // create two _different_ forks during setup
    function setUp() public override {
        super.setUp();

        // PumPointをユーザに渡す
        loyaltyPoint.mint(userAddress, 10000 * 1e6);
    }

    function testIssueAndMintLoyaltyToken() public {
        address loyaltyToken = loyaltyController.createLoyaltyToken(
            CreateTokenParameters(issuer, userAddress, 10000 * 1e18, "LOYALTY", "LOYALTY", bytes32(0), ""),
            address(0x000000000022D473030F116dDEE9F6B43aC78BA3)
        );

        vm.prank(userAddress);
        loyaltyController.mintLoyaltyCoin(loyaltyToken, userAddress, 10000 * 1e18);

        assertEq(IERC20(loyaltyToken).balanceOf(userAddress), 10000 * 1e18);

        currency0 = Currency.wrap(address(dai));
        // ETH
        currency1 = Currency.wrap(address(0));

        _buy(1000 * 1e18, loyaltyToken, 1000000);

        assertEq(userAddress.balance, 1000000);
    }

    function _buy(uint256 amountIn, address loyaltyToken, uint256 amountOut) internal {
        Currency[] memory tokenPath = new Currency[](2);
        tokenPath[0] = currency0;
        tokenPath[1] = currency1;

        Plan memory plan = Planner.init();

        IV4Router.ExactInputParams memory params = _getExactInputParams(tokenPath, amountIn / 160);
        plan = plan.add(Actions.SWAP_EXACT_IN, abi.encode(params));
        bytes memory data = _makeV4Swap(plan.finalizeSwap(currency0, currency1, address(swapHandler)));

        address[] memory tokensToApproveForUniversalRouter = new address[](1);
        tokensToApproveForUniversalRouter[0] = address(dai);

        swapHandler.execute(
            address(this),
            createSignedOrder(
                userPrivateKey, userAddress, address(loyaltyToken), Currency.unwrap(currency1), amountIn, amountOut, 1
            ),
            abi.encode(
                tokensToApproveForUniversalRouter,
                ISwapRouter.ConvertParams(ISwapRouter.ConvertType.LOYALTY_TO_DAI, address(loyaltyToken)),
                data
            )
        );
    }

    function _getSellFacilitationData(uint256 amountIn) internal view returns (bytes memory) {
        Currency[] memory tokenPath = new Currency[](2);
        tokenPath[0] = currency1;
        tokenPath[1] = currency0;

        Plan memory plan = Planner.init();

        IV4Router.ExactInputParams memory params = _getExactInputParams(tokenPath, amountIn);
        plan = plan.add(Actions.SWAP_EXACT_IN, abi.encode(params));
        bytes memory data = _makeV4Swap(plan.finalizeSwap(currency1, currency0, address(swapHandler)));

        address[] memory tokensToApproveForUniversalRouter = new address[](1);
        tokensToApproveForUniversalRouter[0] = Currency.unwrap(currency1);

        return abi.encode(
            tokensToApproveForUniversalRouter,
            ISwapRouter.ConvertParams(ISwapRouter.ConvertType.CARRY_TO_DAI, Currency.unwrap(currency1)),
            data
        );
    }

    function _sell(uint256 amountIn, address creatorToken, uint256 amountOut) internal {
        bytes memory data = _getSellFacilitationData(amountIn);

        swapHandler.execute(
            address(this),
            createSignedOrder(userPrivateKey, userAddress, creatorToken, address(dai), amountIn, amountOut, 2),
            data
        );
    }

    function _makeV4Swap(bytes memory v4SwapData) internal view returns (bytes memory) {
        bytes memory actions = new bytes(1);

        actions[0] = bytes1(uint8(0x10));

        bytes[] memory params = new bytes[](1);
        params[0] = v4SwapData;

        return abi.encodeWithSelector(EXECUTE_SELECTOR, actions, params, block.timestamp);
    }

    function _getExactInputParams(Currency[] memory _tokenPath, uint256 amountIn)
        internal
        view
        returns (IV4Router.ExactInputParams memory params)
    {
        PathKey[] memory path = new PathKey[](_tokenPath.length - 1);
        for (uint256 i = 0; i < _tokenPath.length - 1; i++) {
            path[i] = PathKey(_tokenPath[i + 1], 3000, 60, IHooks(address(0)), bytes(""));
        }

        params.currencyIn = _tokenPath[0];
        params.path = path;
        params.amountIn = uint128(amountIn);
        params.amountOutMinimum = 0;
    }
}
