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

// TODO: pumPoint
import {PrexPoint} from "../../../src/credit/PrexPoint.sol";

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
    Plan plan;
    Currency[] tokenPath;
    Currency currency0;
    Currency currency1;

    address issuer = address(0x1234567890123456789012345678901234567890);
    address recipient = address(0x0987654321098765432109876543210987654321);

    PrexPoint public pumPoint;

    // create two _different_ forks during setup
    function setUp() public {
        optimismFork = vm.createFork(OPTIMISM_RPC_URL);
        vm.selectFork(optimismFork);
        vm.rollFork(133_850_000);

        pumPoint = new PrexPoint(address(this), address(0x000000000022D473030F116dDEE9F6B43aC78BA3));
        TokenRegistry tokenRegistry = new TokenRegistry();

        pumController = new PumController(
            address(this),
            address(pumPoint),
            address(0),
            address(0x3C3Ea4B57a46241e54610e5f022E5c45859A1017),
            address(tokenRegistry),
            address(0x000000000022D473030F116dDEE9F6B43aC78BA3)
        );
        pumPoint.setOrderExecutor(address(pumController));
        loyaltyConverter = new LoyaltyConverter(address(0), address(0));

        prexSwapRouter = new PrexSwapRouter(
            address(0x851116D9223fabED8E56C0E6b8Ad0c31d98B3507),
            address(loyaltyConverter),
            address(pumController),
            address(0x000000000022D473030F116dDEE9F6B43aC78BA3)
        );

        plan = Planner.init();

        // CarryToken
        currency0 = Currency.wrap(address(pumController.carryToken()));
    }

    // manage multiple forks in the same test
    function testIssuePumToken() public {
        address creatorToken = pumController.issuePumToken(issuer);

        currency1 = Currency.wrap(address(creatorToken));

        // assertEq(creatorToken, address(0x4200000000000000000000000000000000000006));
        pumPoint.mint(address(prexSwapRouter), 1000 * 1e6);

        {
            uint256 amountIn = 1000 * 1e6;

            tokenPath.push(currency0);
            tokenPath.push(currency1);
            IV4Router.ExactInputParams memory params = _getExactInputParams(tokenPath, amountIn);
            plan = plan.add(Actions.SWAP_EXACT_IN, abi.encode(params));
            bytes memory data = _makeV4Swap(plan.finalizeSwap(currency0, currency1, address(this)));

            address[] memory tokensToApproveForUniversalRouter = new address[](1);
            tokensToApproveForUniversalRouter[0] = address(pumController.carryToken());

            /*
            prexSwapRouter.executeSwap(
                abi.encode(
                    tokensToApproveForUniversalRouter,
                    PrexSwapRouter.ConvertParams(PrexSwapRouter.ConvertType.PUM_TO_CARRY, address(0), 1000 * 1e6),
                    data
                )
            );
            */
        }
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
        pure
        returns (IV4Router.ExactInputParams memory params)
    {
        PathKey[] memory path = new PathKey[](_tokenPath.length - 1);
        for (uint256 i = 0; i < _tokenPath.length - 1; i++) {
            path[i] = PathKey(_tokenPath[i + 1], 60_000, 60, IHooks(address(0)), bytes(""));
        }

        params.currencyIn = _tokenPath[0];
        params.path = path;
        params.amountIn = uint128(amountIn);
        params.amountOutMinimum = 0;
    }
}
