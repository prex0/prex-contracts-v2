// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {CreateTokenParameters} from "../token-factory/TokenParams.sol";
import {CreatorCoin} from "../token-factory/tokens/CreatorCoin.sol";
import {PumConverter} from "./converter/PumConverter.sol";
import {IImmutableState} from "v4-periphery/src/interfaces/IImmutableState.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Actions} from "v4-periphery/src/libraries/Actions.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IPermit2} from "../../lib/permit2/src/interfaces/IPermit2.sol";

interface IPositionManager {
    function modifyLiquidities(bytes calldata unlockData, uint256 deadline) external payable;
    function poolManager() external view returns (IPoolManager);
}

contract PumController is PumConverter {
    event CreatorCoinCreated(address indexed token);

    mapping(address => address) public creatorTokens;

    address public positionManager;
    address public tokenRegistry;
    IPermit2 public permit2;

    constructor(
        address _owner,
        address _prexPoint,
        address _dai,
        address _positionManager,
        address _tokenRegistry,
        address _permit2
    ) PumConverter(_owner, _prexPoint, _dai) {
        positionManager = _positionManager;
        tokenRegistry = _tokenRegistry;
        permit2 = IPermit2(_permit2);

        carryToken.approve(address(permit2), type(uint256).max);
        permit2.approve(address(carryToken), address(positionManager), type(uint160).max, type(uint48).max);
    }

    //
    function issuePumToken(
        address issuer,
        string memory name,
        string memory symbol,
        bytes32 pictureHash,
        string memory metadata
    ) public returns (address) {
        // Issue PUM token
        address creatorToken = _createCreatorToken(
            CreateTokenParameters(issuer, address(this), 1e8 * 1e18, name, symbol, pictureHash, metadata),
            address(0),
            tokenRegistry
        );

        _initializePool(creatorToken, address(carryToken), _getStartSqrtPriceX96(creatorToken, address(carryToken)));

        // provide liquidity to PUM/CARRY pool
        // TODO: approve
        IERC20(creatorToken).approve(address(permit2), type(uint256).max);
        permit2.approve(address(creatorToken), address(positionManager), type(uint160).max, type(uint48).max);
        _addLiquidity(creatorToken, address(carryToken));

        return creatorToken;
    }

    function _getStartSqrtPriceX96(address tokenA, address tokenB) internal pure returns (uint256) {
        if (tokenA < tokenB) {
            return (500000000000);
        } else {
            return (1e8 * 1e38);
        }
    }

    function _initializePool(address tokenA, address tokenB, uint256 sqrtPriceX96) internal {
        PoolKey memory poolKey = _getPoolKey(tokenA, tokenB);

        IPoolManager poolManager = IPositionManager(positionManager).poolManager();

        poolManager.initialize(poolKey, uint160(sqrtPriceX96));
    }

    function _getPoolKey(address tokenA, address tokenB) internal pure returns (PoolKey memory) {
        Currency currency0 = Currency.wrap(tokenA);
        Currency currency1 = Currency.wrap(tokenB);
        if (tokenA > tokenB) {
            (currency0, currency1) = (currency1, currency0);
        }
        return PoolKey({
            currency0: currency0,
            currency1: currency1,
            // 6.0%
            fee: 60_000,
            tickSpacing: 60,
            hooks: IHooks(address(0))
        });
    }

    function _addLiquidity(address tokenA, address tokenB) internal {
        bytes memory actions = new bytes(2);

        actions[0] = bytes1(uint8(Actions.MINT_POSITION));
        actions[1] = bytes1(uint8(Actions.SETTLE_PAIR));

        bytes[] memory params = new bytes[](2);
        params[0] = _encodeMintParams(
            _getPoolKey(tokenA, tokenB),
            int24(tokenA < tokenB ? -340680 : -887220),
            int24(tokenA < tokenB ? 887220 : 340680),
            4004955170909380034,
            type(uint128).max,
            type(uint128).max,
            address(this)
        );
        params[1] = abi.encode(tokenA, tokenB);
        IPositionManager(positionManager).modifyLiquidities(abi.encode(actions, params), block.timestamp);
    }

    function _encodeMintParams(
        PoolKey memory poolKey,
        int24 tickLower,
        int24 tickUpper,
        uint256 liquidity,
        uint128 amount0Max,
        uint128 amount1Max,
        address owner
    ) internal pure returns (bytes memory) {
        return abi.encode(poolKey, tickLower, tickUpper, liquidity, amount0Max, amount1Max, owner, bytes(""));
    }

    /**
     * @notice Create a creator token
     * pumpumの推しの証を作成する
     * @param params トークンのパラメータ
     * @param _permit2 The permit2 address
     * @param _tokenRegistry The token registry address
     * @return The address of the created token
     */
    function _createCreatorToken(CreateTokenParameters memory params, address _permit2, address _tokenRegistry)
        internal
        returns (address)
    {
        CreatorCoin coin = new CreatorCoin(params, _permit2, _tokenRegistry);

        creatorTokens[address(coin)] = address(coin);

        emit CreatorCoinCreated(address(coin));

        return address(coin);
    }
}
