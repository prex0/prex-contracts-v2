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
import {Currency} from "v4-core/src/types/Currency.sol";

import {PumConverter} from "../../../src/swap/converter/PumConverter.sol";
import {LoyaltyConverter} from "../../../src/swap/converter/LoyaltyConverter.sol";

contract SwapRouterTest is Test {
    using Planner for Plan;

    // the identifiers of the forks
    uint256 optimismFork;

    //Access variables from .env file via vm.envString("varname")
    //Replace ALCHEMY_KEY by your alchemy key or Etherscan key, change RPC url if need
    //inside your .env file e.g:
    //MAINNET_RPC_URL = 'https://eth-mainnet.g.alchemy.com/v2/ALCHEMY_KEY'
    //string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    string OPTIMISM_RPC_URL = vm.envString("RPC_URL");

    PumConverter public pumConverter;
    LoyaltyConverter public loyaltyConverter;

    PrexSwapRouter public prexSwapRouter;
    Plan plan;
    Currency[] tokenPath;
    Currency currency0;
    Currency currency1;

    // create two _different_ forks during setup
    function setUp() public {
        optimismFork = vm.createFork(OPTIMISM_RPC_URL);
        vm.selectFork(optimismFork);
        vm.rollFork(1_337_000);

        pumConverter = new PumConverter(address(0), address(0), address(0));
        loyaltyConverter = new LoyaltyConverter(address(0), address(0));

        prexSwapRouter = new PrexSwapRouter(
            address(0x851116D9223fabED8E56C0E6b8Ad0c31d98B3507),
            address(loyaltyConverter),
            address(pumConverter),
            address(0x000000000022D473030F116dDEE9F6B43aC78BA3)
        );

        plan = Planner.init();

        // WETH
        currency0 = Currency.wrap(address(0x4200000000000000000000000000000000000006));
        currency1 = Currency.wrap(address(0x4200000000000000000000000000000000000007));
    }

    // manage multiple forks in the same test
    function testExecuteSwap() public {
        uint256 amountIn = 1 ether;

        tokenPath.push(currency0);
        tokenPath.push(currency1);
        IV4Router.ExactInputParams memory params = _getExactInputParams(tokenPath, amountIn);
        plan = plan.add(Actions.SWAP_EXACT_IN, abi.encode(params));
        bytes memory data = plan.encode();

        prexSwapRouter.executeSwap(
            abi.encode(
                new address[](0), PrexSwapRouter.ConvertParams(PrexSwapRouter.ConvertType.NOOP, address(0), 0), data
            )
        );
    }

    function _getExactInputParams(Currency[] memory _tokenPath, uint256 amountIn)
        internal
        pure
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
