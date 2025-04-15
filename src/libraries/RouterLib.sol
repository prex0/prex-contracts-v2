// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IV4Router} from "v4-periphery/src/interfaces/IV4Router.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {LPFeeLibrary} from "v4-core/src/libraries/LPFeeLibrary.sol";

/// @title RouterLib
/// @notice Library for creating a V4 command
library RouterLib {
    bytes4 private constant EXECUTE_SELECTOR = bytes4(keccak256("execute(bytes,bytes[],uint256)"));

    /**
     * @notice Create a V4 command for the universal router
     * @param currencyIn The input currency
     * @param currencyOut The output currency
     * @param amountIn The amount of input currency
     * @param pumHook The PUM hook
     * @return The V4 command
     */
    function createUniversalRouterCommand(address currencyIn, address currencyOut, uint256 amountIn, address pumHook)
        internal
        view
        returns (bytes memory)
    {
        bytes memory command = createV4Command(currencyIn, currencyOut, amountIn, pumHook);

        bytes memory actions = new bytes(1);

        actions[0] = bytes1(uint8(0x10));

        bytes[] memory params = new bytes[](1);
        params[0] = command;

        return abi.encodeWithSelector(EXECUTE_SELECTOR, actions, params, block.timestamp);
    }

    function createV4Command(address currencyIn, address currencyOut, uint256 amountIn, address pumHook)
        internal
        pure
        returns (bytes memory)
    {
        IV4Router.ExactInputSingleParams memory v4Params =
            getExactInputParams(currencyIn, currencyOut, amountIn, pumHook);

        bytes memory actions = new bytes(3);

        actions[0] = bytes1(uint8(0x06));
        actions[1] = bytes1(uint8(0x0c));
        actions[2] = bytes1(uint8(0x0f));

        bytes[] memory params = new bytes[](3);
        params[0] = abi.encode(v4Params);
        params[1] = abi.encode(currencyIn, type(uint256).max);
        params[2] = abi.encode(currencyOut, 0);

        return abi.encode(actions, params);
    }

    function getExactInputParams(address currencyIn, address currencyOut, uint256 amountIn, address pumHook)
        internal
        pure
        returns (IV4Router.ExactInputSingleParams memory params)
    {
        params.poolKey = getPoolKey(currencyIn, currencyOut, pumHook);
        params.zeroForOne = currencyIn < currencyOut;
        params.amountIn = uint128(amountIn);
        params.amountOutMinimum = 0;
        params.hookData = bytes("");
    }

    function getPoolKey(address tokenIn, address tokenOut, address pumHook) internal pure returns (PoolKey memory) {
        Currency currency0 = Currency.wrap(tokenIn);
        Currency currency1 = Currency.wrap(tokenOut);

        (currency0, currency1) = (tokenIn < tokenOut) ? (currency0, currency1) : (currency1, currency0);

        return PoolKey({
            currency0: currency0,
            currency1: currency1,
            // dynamic fee
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            tickSpacing: 300,
            hooks: IHooks(address(pumHook))
        });
    }
}
