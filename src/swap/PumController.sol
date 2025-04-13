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
import {CreatorTokenFactory} from "../token-factory/CreatorTokenFactory.sol";
import {PumHook} from "./hooks/PumHook.sol";
import {LPFeeLibrary} from "v4-core/src/libraries/LPFeeLibrary.sol";

interface IPositionManager {
    function nextTokenId() external view returns (uint256);
    function modifyLiquidities(bytes calldata unlockData, uint256 deadline) external payable;
    function poolManager() external view returns (IPoolManager);
}

contract PumController is PumConverter {
    mapping(address => address) public creatorTokens;

    address public positionManager;
    address public tokenRegistry;
    IPermit2 public permit2;
    CreatorTokenFactory public creatorTokenFactory;

    uint256 public constant MAX_SUPPLY_CT = 1e8 * 1e18;

    PumHook public pumHook;

    mapping(address => address) public userMainTokenMap;

    mapping(address => uint256) public tokenIdMap;

    event TokenIssued(
        address indexed communityToken, address indexed issuer, string name, string symbol, uint256 amountCT
    );
    
    function __PumController_init(address _owner, address _prexPoint, address _positionManager, address _tokenRegistry, address _creatorTokenFactory, address _permit2)
        internal
        onlyInitializing
    {
        __PumConverter_init(_owner, _prexPoint);

        positionManager = _positionManager;
        tokenRegistry = _tokenRegistry;
        permit2 = IPermit2(_permit2);
        creatorTokenFactory = CreatorTokenFactory(_creatorTokenFactory);

        // approve CARRY token
        // carryToken.approve(address(permit2), type(uint256).max);
        // permit2.approve(address(carryToken), address(positionManager), type(uint160).max, type(uint48).max);
    }

    function setPumHook(address _pumHook) external onlyOwner {
        pumHook = PumHook(_pumHook);
    }

    /**
     * @notice トークンを発行する
     * @param issuer トークンの発行者
     * @param name トークンの名前
     * @param symbol トークンのシンボル
     * @param pictureHash トークンの画像のハッシュ
     * @param metadata トークンのメタデータ
     */
    function _issuePumToken(
        address issuer,
        string memory name,
        string memory symbol,
        bytes32 pictureHash,
        bytes memory metadata
    ) internal returns (address) {
        // Issue PUM token
        address creatorToken = creatorTokenFactory.createCreatorToken(
            CreateTokenParameters(issuer, address(this), MAX_SUPPLY_CT, name, symbol, pictureHash, metadata),
            address(permit2),
            tokenRegistry
        );

        _initializePool(creatorToken, address(carryToken));

        // provide liquidity to PUM/CARRY pool
        // approve creator token
        IERC20(creatorToken).approve(address(permit2), type(uint256).max);
        permit2.approve(address(creatorToken), address(positionManager), type(uint160).max, type(uint48).max);

        _addLiquidity(creatorToken, address(carryToken));

        if (userMainTokenMap[issuer] == address(0)) {
            userMainTokenMap[issuer] = creatorToken;
        }

        emit TokenIssued(creatorToken, issuer, name, symbol, MAX_SUPPLY_CT);

        return creatorToken;
    }

    /**
     * @notice 手数料を収集する
     * @dev オーナーのみが収集できる
     * @param creatorToken トークンのアドレス
     * @param recipient 手数料を受け取るアドレス
     */
    function collectFee(address creatorToken, address recipient) external onlyOwner {
        _collectFee(creatorToken, address(carryToken), tokenIdMap[creatorToken], recipient);
    }

    function _getStartSqrtPriceX96(address tokenA, address tokenB) internal pure returns (uint160) {
        if (tokenA < tokenB) {
            return uint160(500000000000);
        } else {
            return uint160(1e8 * 1e38);
        }
    }

    function _initializePool(address tokenA, address tokenB) internal {
        // TODO: ここでsqrtPriceX96を計算する
        uint256 sqrtPriceX96 = _getStartSqrtPriceX96(tokenA, tokenB);

        PoolKey memory poolKey = _getPoolKey(tokenA, tokenB);

        IPoolManager poolManager = IPositionManager(positionManager).poolManager();

        poolManager.initialize(poolKey, uint160(sqrtPriceX96));
    }

    function _getPoolKey(address tokenA, address tokenB) internal view returns (PoolKey memory) {
        Currency currency0 = Currency.wrap(tokenA);
        Currency currency1 = Currency.wrap(tokenB);
        if (tokenA > tokenB) {
            (currency0, currency1) = (currency1, currency0);
        }
        return PoolKey({
            currency0: currency0,
            currency1: currency1,
            // dynamic fee
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            tickSpacing: 300,
            hooks: IHooks(address(pumHook))
        });
    }

    function _addLiquidity(address tokenA, address tokenB) internal {
        bytes memory actions = new bytes(2);

        actions[0] = bytes1(uint8(Actions.MINT_POSITION));
        actions[1] = bytes1(uint8(Actions.SETTLE_PAIR));

        bytes[] memory params = new bytes[](2);
        params[0] = _encodeMintParams(
            _getPoolKey(tokenA, tokenB),
            int24(tokenA < tokenB ? -340800 : -887100),
            int24(tokenA < tokenB ? 887100 : 340800),
            3980998579334402966,
            type(uint128).max,
            type(uint128).max,
            address(this)
        );
        params[1] = abi.encode(tokenA, tokenB);

        tokenIdMap[tokenA] = IPositionManager(positionManager).nextTokenId();

        IPositionManager(positionManager).modifyLiquidities(abi.encode(actions, params), block.timestamp);
    }

    function _collectFee(address tokenA, address tokenB, uint256 tokenId, address recipient) internal {
        bytes memory actions = new bytes(2);

        actions[0] = bytes1(uint8(Actions.DECREASE_LIQUIDITY));
        actions[1] = bytes1(uint8(Actions.TAKE_PAIR));

        bytes[] memory params = new bytes[](2);
        params[0] = _encodeDecreaseLiquidityParams(tokenId, 0, 0, 0);
        params[1] = abi.encode(tokenA, tokenB, recipient);
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

    function _encodeDecreaseLiquidityParams(uint256 tokenId, uint256 liquidity, uint128 amount0Min, uint128 amount1Min)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(tokenId, liquidity, amount0Min, amount1Min, bytes(""));
    }
}
