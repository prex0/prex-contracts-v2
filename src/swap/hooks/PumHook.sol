// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseHook, IPoolManager, PoolKey} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";
import {PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BeforeSwapDelta} from "v4-core/src/types/BeforeSwapDelta.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {Currency, CurrencyLibrary, equals} from "v4-core/src/types/Currency.sol";

contract PumHook is BaseHook {
    using Hooks for IPoolManager;
    using StateLibrary for IPoolManager;
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using {equals} for Currency;

    // 0:creator, 1:carry
    uint160 minSqrtPriceX96ByCarry = 7130534626283790000000000000000;
    // 0:carry, 1:creator
    uint160 maxSqrtPriceX96ByCreator = 880312916825159000000000000;

    Currency public immutable carryToken;

    mapping(address => bool) public isSellableMap;

    error MarketNotSellable();
    error InvalidPool();

    event MarketStatusUpdated(address indexed communityToken, bool sellable);

    constructor(address _poolManager, address _carryToken) BaseHook(IPoolManager(_poolManager)) {
        carryToken = Currency.wrap(_carryToken);
    }

    function _getMinSqrtPriceX96(bool isToken0Carry) internal view returns (uint160) {
        if (isToken0Carry) {
            return maxSqrtPriceX96ByCreator;
        } else {
            return minSqrtPriceX96ByCarry;
        }
    }

    // このHookが使用するフックの設定
    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function _beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata swapParams, bytes calldata)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        bool isCarryToken0 = key.currency0.equals(carryToken);

        if (!isCarryToken0 && !key.currency1.equals(carryToken)) {
            revert InvalidPool();
        }

        address creatorToken = isCarryToken0 ? Currency.unwrap(key.currency1) : Currency.unwrap(key.currency0);
        bool isSellable = isSellableMap[creatorToken];

        if (isCarryToken0) {
            if (!swapParams.zeroForOne && !isSellable) {
                revert MarketNotSellable();
            }
        } else {
            if (swapParams.zeroForOne && !isSellable) {
                revert MarketNotSellable();
            }
        }

        return (BaseHook.beforeSwap.selector, BeforeSwapDelta.wrap(0), 0);
    }

    // スワップ前に呼び出される
    function _afterSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
        internal
        override
        returns (bytes4, int128)
    {
        bool isCarryToken0 = key.currency0.equals(carryToken);

        uint160 minSqrtPriceX96 = _getMinSqrtPriceX96(isCarryToken0);

        // 現在の sqrtPriceX96 を取得
        (uint160 currentSqrtPriceX96,,,) = poolManager.getSlot0(key.toId());

        // 許可価格以上でなければ Revert（売りを拒否）
        if (currentSqrtPriceX96 > minSqrtPriceX96) {
            _updateMarketStatus(key, isCarryToken0, false);
        }

        return (BaseHook.afterSwap.selector, 0);
    }

    function _updateMarketStatus(PoolKey calldata key, bool isCarryToken0, bool isSellable) internal {
        address creatorToken = Currency.unwrap(isCarryToken0 ? key.currency1 : key.currency0);

        if (isSellableMap[creatorToken] == isSellable) {
            return;
        }

        isSellableMap[creatorToken] = isSellable;

        emit MarketStatusUpdated(creatorToken, isSellable);
    }
}
