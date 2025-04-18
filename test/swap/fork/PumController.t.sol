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
import {LPFeeLibrary} from "v4-core/src/libraries/LPFeeLibrary.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";

interface IPositionManager {
    function poolManager() external view returns (address);
}

contract PumControllerTest is SwapRouterSetup {
    using Planner for Plan;
    using CurrencyLibrary for Currency;

    bytes4 private constant EXECUTE_SELECTOR = bytes4(keccak256("execute(bytes,bytes[],uint256)"));

    uint256 userPrivateKey = 12;
    address userAddress = vm.addr(userPrivateKey);

    address issuer = address(0x1234567890123456789012345678901234567890);
    address feeRecipient = vm.addr(500);

    uint256 nonce = 1;

    // create two _different_ forks during setup
    function setUp() public override {
        super.setUp();

        // PumPointをユーザに渡す
        pumPoint.mint(userAddress, 1000000 * 1e6);
    }

    function testIssuePumToken_AndCheckInitialBuy() public {
        pumPoint.mint(address(pumController), 2000 * 1e6);
        address creatorToken = pumController.issuePumToken(issuer, "PUM", "PUM", bytes32(0), "", 2000 * 1e6);

        currency1 = Currency.wrap(address(creatorToken));

        // 初期購入
        // 21,287,166 (2.1%)
        assertEq(IERC20(creatorToken).balanceOf(issuer), 21287166 * 1e18);
    }

    function testIssuePumToken_AndCheckFirstBuy() public {
        address creatorToken = pumController.issuePumToken(issuer, "PUM", "PUM", bytes32(0), "", 0);

        currency1 = Currency.wrap(address(creatorToken));

        _buy(2000 * 1e6, creatorToken, 21287166 * 1e18);

        // 21,287,166 (2.1%)
        assertEq(IERC20(creatorToken).balanceOf(userAddress), 21287166 * 1e18);
        // 手数料
        assertLt(IERC20(creatorToken).balanceOf(address(swapHandler)), 1e18);
    }

    function testIssuePumToken_AndCheckFirstBuy20000() public {
        address creatorToken = pumController.issuePumToken(issuer, "PUM", "PUM", bytes32(0), "", 0);

        currency1 = Currency.wrap(address(creatorToken));

        _buy(20000 * 1e6, creatorToken, 108723233 * 1e18);

        // ユーザーには約108,723,233トークンが入ってい
        // 10.8%
        assertEq(IERC20(creatorToken).balanceOf(userAddress), 108723233 * 1e18);
        assertLt(IERC20(creatorToken).balanceOf(address(swapHandler)), 1e18);
    }

    function testCannotSellBeforeMarketOpen() public {
        address creatorToken = pumController.issuePumToken(issuer, "PUM", "PUM", bytes32(0), "", 0);

        currency1 = Currency.wrap(address(creatorToken));

        _buy(20000 * 1e6, creatorToken, 500000 * 1e18);
        _buy(180000 * 1e6, creatorToken, 5000000 * 1e18);

        bytes memory data = _getSellFacilitationData(10000 * 1e18);

        SignedOrder memory order =
            createSignedOrder(userPrivateKey, userAddress, creatorToken, address(dai), 10000 * 1e18, 0, 2);

        vm.expectRevert();
        swapHandler.execute(address(this), order, data);
    }

    function testSellAfterMarketOpen() public {
        address creatorToken = pumController.issuePumToken(issuer, "PUM", "PUM", bytes32(0), "", 0);

        currency1 = Currency.wrap(address(creatorToken));

        // assertEq(creatorToken, address(0x4200000000000000000000000000000000000006));
        // pumPoint.mint(address(swapHandler), 200000 * 1e6);

        _buy(20000 * 1e6, creatorToken, 500000 * 1e18);
        _buy(200000 * 1e6, creatorToken, 5000000 * 1e18);

        _sell(2000000 * 1e18, creatorToken, 10 * 1e18);

        pumController.collectFee(creatorToken, feeRecipient);

        assertEq(IERC20(creatorToken).balanceOf(feeRecipient), 113748797352244503611198);
        assertEq(dai.balanceOf(userAddress), 10000000000000000000);
    }

    function testCannotUpdateFee() public {
        address creatorToken = pumController.issuePumToken(issuer, "PUM", "PUM", bytes32(0), "", 0);
        currency1 = Currency.wrap(address(creatorToken));

        vm.startPrank(issuer);
        vm.expectRevert(bytes("UNAUTHORIZED"));
        pumHook.setFee(_getPoolKey(), 100);
        vm.stopPrank();
    }

    function testUpdateFee() public {
        address creatorToken = pumController.issuePumToken(issuer, "PUM", "PUM", bytes32(0), "", 0);

        currency1 = Currency.wrap(address(creatorToken));

        pumHook.setFee(_getPoolKey(), 100);

        _buy(2000 * 1e6, creatorToken, 22491112 * 1e18);

        // 手数料を0.01%に設定したので、ユーザーには約22,491,112トークンが入る
        assertEq(IERC20(creatorToken).balanceOf(userAddress), 22491112 * 1e18);

        // 手数料
        assertLt(IERC20(creatorToken).balanceOf(address(swapHandler)), 1e18);
    }

    function _buy(uint256 amountIn, address creatorToken, uint256 amountOut) internal {
        Currency[] memory tokenPath = new Currency[](2);
        tokenPath[0] = currency0;
        tokenPath[1] = currency1;

        Plan memory plan = Planner.init();

        IV4Router.ExactInputParams memory params = _getExactInputParams(tokenPath, amountIn);
        plan = plan.add(Actions.SWAP_EXACT_IN, abi.encode(params));
        bytes memory data = _makeV4Swap(plan.finalizeSwap(currency0, currency1, address(swapHandler)));

        address[] memory tokensToApproveForUniversalRouter = new address[](1);
        tokensToApproveForUniversalRouter[0] = address(pumController.carryToken());

        swapHandler.execute(
            address(this),
            createSignedOrder(
                userPrivateKey, userAddress, address(pumPoint), creatorToken, amountIn, amountOut, nonce++
            ),
            abi.encode(
                tokensToApproveForUniversalRouter,
                ISwapRouter.ConvertParams(ISwapRouter.ConvertType.PUM_TO_CARRY, address(0)),
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
            createSignedOrder(userPrivateKey, userAddress, creatorToken, address(dai), amountIn, amountOut, nonce++),
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
            path[i] =
                PathKey(_tokenPath[i + 1], LPFeeLibrary.DYNAMIC_FEE_FLAG, 300, IHooks(address(pumHook)), bytes(""));
        }

        params.currencyIn = _tokenPath[0];
        params.path = path;
        params.amountIn = uint128(amountIn);
        params.amountOutMinimum = 0;
    }

    function _getPoolKey() internal view returns (PoolKey memory) {
        if (currency0 < currency1) {
            return PoolKey({
                currency0: currency0,
                currency1: currency1,
                fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
                tickSpacing: 300,
                hooks: IHooks(address(pumHook))
            });
        } else {
            return PoolKey({
                currency0: currency1,
                currency1: currency0,
                fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
                tickSpacing: 300,
                hooks: IHooks(address(pumHook))
            });
        }
    }
}
