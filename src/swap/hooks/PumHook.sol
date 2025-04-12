// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseHook, IPoolManager, PoolKey} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";
import {PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BeforeSwapDelta} from "v4-core/src/types/BeforeSwapDelta.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {Currency, CurrencyLibrary, equals} from "v4-core/src/types/Currency.sol";
import {Owned} from "solmate/src/auth/Owned.sol";

contract PumHook is BaseHook, Owned {
    using Hooks for IPoolManager;
    using StateLibrary for IPoolManager;
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using {equals} for Currency;

    // 0:creator, 1:carry
    uint160 minSqrtPriceX96ByCarry = 7086382300000000000000;
    // 0:carry, 1:creator
    uint160 maxSqrtPriceX96ByCreator = 885797783642957107159712428047759491;

    Currency public immutable carryToken;

    mapping(address => bool) public isSellableMap;

    error MarketNotSellable();
    error InvalidPool();

    event MarketStatusUpdated(address indexed communityToken, bool sellable);
    event CreatorTokenPriceChanged(address indexed sender, address indexed communityToken, uint160 sqrtPriceX96);

    constructor(address _poolManager, address _carryToken, address _owner)
        BaseHook(IPoolManager(_poolManager))
        Owned(_owner)
    {
        carryToken = Currency.wrap(_carryToken);
    }

    function setMinSqrtPriceX96ByCarry(uint160 _minSqrtPriceX96ByCarry) external onlyOwner {
        minSqrtPriceX96ByCarry = _minSqrtPriceX96ByCarry;
    }

    function setMaxSqrtPriceX96ByCreator(uint160 _maxSqrtPriceX96ByCreator) external onlyOwner {
        maxSqrtPriceX96ByCreator = _maxSqrtPriceX96ByCreator;
    }

    function setMarketStatus(address creatorToken, bool isSellable) external onlyOwner {
        _updateMarketStatus(creatorToken, isSellable);
    }

    function setFee(PoolKey calldata key, uint24 newFee) external onlyOwner {
        poolManager.updateDynamicLPFee(key, newFee);
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
            afterInitialize: true,
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

    function _afterInitialize(address, PoolKey calldata key, uint160, int24) internal override returns (bytes4) {
        // 初期化時に手数料を6.0%に設定
        poolManager.updateDynamicLPFee(key, 60000);

        return BaseHook.afterInitialize.selector;
    }

    function _beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata swapParams, bytes calldata)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        (bool isCarryToken0, address creatorToken) = _getCreatorToken(key);

        if (!isCarryToken0 && !key.currency1.equals(carryToken)) {
            revert InvalidPool();
        }

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

    function _afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) internal override returns (bytes4, int128) {
        (bool isCarryToken0, address creatorToken) = _getCreatorToken(key);

        uint160 minSqrtPriceX96 = _getMinSqrtPriceX96(isCarryToken0);

        // 現在の sqrtPriceX96 を取得
        (uint160 currentSqrtPriceX96,,,) = poolManager.getSlot0(key.toId());

        // 一定価格以上であれば、売却可能にする
        if (currentSqrtPriceX96 > minSqrtPriceX96) {
            _updateMarketStatus(creatorToken, true);
        }

        emit CreatorTokenPriceChanged(sender, creatorToken, currentSqrtPriceX96);

        return (BaseHook.afterSwap.selector, 0);
    }

    function _getCreatorToken(PoolKey calldata key) internal view returns (bool isCarryToken0, address creatorToken) {
        isCarryToken0 = key.currency0.equals(carryToken);
        creatorToken = Currency.unwrap(isCarryToken0 ? key.currency1 : key.currency0);
    }

    function _updateMarketStatus(address creatorToken, bool isSellable) internal {
        if (isSellableMap[creatorToken] == isSellable) {
            return;
        }

        isSellableMap[creatorToken] = isSellable;

        emit MarketStatusUpdated(creatorToken, isSellable);
    }
}
