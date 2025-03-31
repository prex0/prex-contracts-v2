// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PrexSwapRouter} from "../../../src/swap/swap-router/PrexSwapRouter.sol";
import {IPrexSwap} from "../../../src/interfaces/IPrexSwap.sol";
import {Plan, Planner} from "v4-periphery/test/shared/Planner.sol";
import {Actions} from "v4-periphery/src/libraries/Actions.sol";
import {PathKey} from "v4-periphery/src/libraries/PathKey.sol";
import {IV4Router} from "v4-periphery/src/interfaces/IV4Router.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Currency, CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {CreateTokenParameters} from "../../../src/token-factory/TokenParams.sol";
import {PumController} from "../../../src/swap/PumController.sol";
import {LoyaltyConverter} from "../../../src/swap/converter/LoyaltyConverter.sol";
import {TokenRegistry} from "../../../src/data/TokenRegistry.sol";
import {LiquidityAmounts} from "v4-periphery/src/libraries/LiquidityAmounts.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {CreatorTokenFactory} from "../../../src/token-factory/CreatorTokenFactory.sol";
import {PrexPoint} from "../../../src/credit/PrexPoint.sol";
import {PumHook} from "../../../src/swap/hooks/PumHook.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";

interface IPositionManager {
    function poolManager() external view returns (address);
}

contract PumControllerTest is Test {
    using Planner for Plan;
    using CurrencyLibrary for Currency;

    bytes4 private constant EXECUTE_SELECTOR = bytes4(keccak256("execute(bytes,bytes[],uint256)"));

    // the identifiers of the forks
    uint256 optimismFork;

    //Access variables from .env file via vm.envString("varname")
    //Replace ALCHEMY_KEY by your alchemy key or Etherscan key, change RPC url if need
    //inside your .env file e.g:
    //MAINNET_RPC_URL = 'https://eth-mainnet.g.alchemy.com/v2/ALCHEMY_KEY'
    //string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    string OPTIMISM_RPC_URL = vm.envString("RPC_URL");

    PumController public pumController;
    LoyaltyConverter public loyaltyConverter;

    PrexSwapRouter public prexSwapRouter;

    Currency currency0;
    Currency currency1;

    address issuer = address(0x1234567890123456789012345678901234567890);
    address recipient = address(0x0987654321098765432109876543210987654321);

    PrexPoint public pumPoint;
    CreatorTokenFactory public creatorTokenFactory;
    PumHook public pumHook;
    IERC20 public dai;

    // create two _different_ forks during setup
    function setUp() public {
        optimismFork = vm.createFork(OPTIMISM_RPC_URL);
        vm.selectFork(optimismFork);
        vm.rollFork(133_850_000);

        dai = IERC20(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);

        pumPoint =
            new PrexPoint("PrexPoint", "PREX", address(this), address(0x000000000022D473030F116dDEE9F6B43aC78BA3));
        TokenRegistry tokenRegistry = new TokenRegistry();
        creatorTokenFactory = new CreatorTokenFactory();
        pumController = new PumController(
            address(this),
            address(pumPoint),
            address(dai),
            address(0x3C3Ea4B57a46241e54610e5f022E5c45859A1017),
            address(tokenRegistry),
            address(creatorTokenFactory),
            address(0x000000000022D473030F116dDEE9F6B43aC78BA3)
        );
        (, bytes32 pumHookSalt) = mineAddress();
        pumHook = new PumHook{salt: pumHookSalt}(
            address(0x9a13F98Cb987694C9F086b1F5eB990EeA8264Ec3), address(pumController.carryToken()), address(this)
        );
        pumController.setPumHook(address(pumHook));

        // Set pumController as consumer
        pumPoint.setConsumer(address(pumController));
        loyaltyConverter = new LoyaltyConverter(address(0), address(0));

        prexSwapRouter = new PrexSwapRouter(
            address(0x851116D9223fabED8E56C0E6b8Ad0c31d98B3507),
            address(loyaltyConverter),
            address(pumController),
            address(0x000000000022D473030F116dDEE9F6B43aC78BA3)
        );

        // Deposit DAI to PumController
        deal(address(dai), address(this), 10000 * 1e18);
        dai.approve(address(pumController), 10000 * 1e18);
        pumController.depositDai(10000 * 1e18);

        // CarryToken
        currency0 = Currency.wrap(address(pumController.carryToken()));
    }

    function mineAddress() internal view returns (address, bytes32) {
        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG);
        bytes memory constructorArgs = abi.encode(
            address(0x9a13F98Cb987694C9F086b1F5eB990EeA8264Ec3), address(pumController.carryToken()), address(this)
        );
        (address hookAddress, bytes32 salt) =
            HookMiner.find(address(this), flags, type(PumHook).creationCode, constructorArgs);

        return (hookAddress, salt);
    }

    function testIssuePumToken_AndCheckFirstBuy() public {
        address creatorToken = pumController.issuePumToken(issuer, "PUM", "PUM", bytes32(0), "");

        currency1 = Currency.wrap(address(creatorToken));

        // assertEq(creatorToken, address(0x4200000000000000000000000000000000000006));
        pumPoint.mint(address(prexSwapRouter), 200000 * 1e6);

        _buy(2000 * 1e6);

        assertEq(IERC20(creatorToken).balanceOf(address(this)), 1158515346047294579105489);
    }

    function testCannotSellBeforeMarketOpen() public {
        address creatorToken = pumController.issuePumToken(issuer, "PUM", "PUM", bytes32(0), "");

        currency1 = Currency.wrap(address(creatorToken));

        // assertEq(creatorToken, address(0x4200000000000000000000000000000000000006));
        pumPoint.mint(address(prexSwapRouter), 200000 * 1e6);

        _buy(20000 * 1e6);

        bytes memory data = _getSellFacilitationData(10000 * 1e18);

        currency1.transfer(address(prexSwapRouter), 10000 * 1e18);

        vm.expectRevert();
        prexSwapRouter.executeSwap(data);
    }

    function testSellAfterMarketOpen() public {
        address creatorToken = pumController.issuePumToken(issuer, "PUM", "PUM", bytes32(0), "");

        currency1 = Currency.wrap(address(creatorToken));

        // assertEq(creatorToken, address(0x4200000000000000000000000000000000000006));
        pumPoint.mint(address(prexSwapRouter), 200000 * 1e6);

        _buy(200000 * 1e6);

        bytes memory data = _getSellFacilitationData(10000 * 1e18);

        currency1.transfer(address(prexSwapRouter), 10000 * 1e18);

        prexSwapRouter.executeSwap(data);
    }

    function _buy(uint256 amountIn) internal {
        Currency[] memory tokenPath = new Currency[](2);
        tokenPath[0] = currency0;
        tokenPath[1] = currency1;

        Plan memory plan = Planner.init();

        IV4Router.ExactInputParams memory params = _getExactInputParams(tokenPath, amountIn);
        plan = plan.add(Actions.SWAP_EXACT_IN, abi.encode(params));
        bytes memory data = _makeV4Swap(plan.finalizeSwap(currency0, currency1, address(this)));

        address[] memory tokensToApproveForUniversalRouter = new address[](1);
        tokensToApproveForUniversalRouter[0] = address(pumController.carryToken());

        prexSwapRouter.executeSwap(
            abi.encode(
                tokensToApproveForUniversalRouter,
                PrexSwapRouter.ConvertParams(PrexSwapRouter.ConvertType.PUM_TO_CARRY, address(0), amountIn),
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
        bytes memory data = _makeV4Swap(plan.finalizeSwap(currency1, currency0, address(this)));

        address[] memory tokensToApproveForUniversalRouter = new address[](1);
        tokensToApproveForUniversalRouter[0] = Currency.unwrap(currency1);

        return abi.encode(
            tokensToApproveForUniversalRouter,
            PrexSwapRouter.ConvertParams(PrexSwapRouter.ConvertType.CARRY_TO_DAI, Currency.unwrap(currency1), 0),
            data
        );
    }

    function _sell(uint256 amountIn) internal {
        bytes memory data = _getSellFacilitationData(amountIn);

        currency1.transfer(address(prexSwapRouter), amountIn);

        prexSwapRouter.executeSwap(data);
    }

    /*
    function testLiquidity() public {
        uint256 liquidity = LiquidityAmounts.getLiquidityForAmount0(
            TickMath.getSqrtPriceAtTick(-340680), TickMath.getSqrtPriceAtTick(887220), 1e8 * 1e18
        );

        assertEq(liquidity, 4004955170909380034);
    }

    function testLiquidity2() public {
        uint256 liquidity = LiquidityAmounts.getLiquidityForAmount1(
            TickMath.getSqrtPriceAtTick(-887220), TickMath.getSqrtPriceAtTick(340680), 1e8 * 1e18
        );

        assertEq(liquidity, 4004955170909380034);
    }
    */

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
            path[i] = PathKey(_tokenPath[i + 1], 60_000, 60, IHooks(address(pumHook)), bytes(""));
        }

        params.currencyIn = _tokenPath[0];
        params.path = path;
        params.amountIn = uint128(amountIn);
        params.amountOutMinimum = 0;
    }
}
