// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IPrexSwap {
    struct SwapExactInputParams {
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    struct SwapExactOutputParams {
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    struct AddLiquidityParams {
        address token0;
        address token1;
        address recipient;
        uint256 amount0;
        uint256 amount1;
    }

    struct RemoveLiquidityParams {
        address token0;
        address token1;
        address recipient;
        uint256 liquidity;
    }
}
