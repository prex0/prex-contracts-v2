// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/**
 * swap router for UniswapV4, V3 and Converter
 */
contract PrexSwapRouter {
    address public universalRouter;

    constructor(address _universalRouter) {
        universalRouter = _universalRouter;
    }

    function executeSwap(bytes memory data) external {
        (bool success, bytes memory returnData) = universalRouter.call(data);
        if (!success) {
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }
    }
}
