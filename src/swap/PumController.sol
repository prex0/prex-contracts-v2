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
import {RouterLib} from "../libraries/RouterLib.sol";

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
    address public universalRouter;

    uint256 public constant MAX_SUPPLY_CT = 1e9 * 1e18;

    PumHook public pumHook;

    mapping(address => address) public userMainTokenMap;

    mapping(address => uint256) public tokenIdMap;

    event TokenIssued(
        address indexed communityToken, address indexed issuer, string name, string symbol, uint256 amountCT
    );

    event InitialSwap(
        address indexed creatorToken,
        address indexed issuer,
        address creditToken,
        uint256 creditAmount,
        uint256 creatorTokenAmount
    );

    function __PumController_init(
        address _owner,
        address _prexPoint,
        address _positionManager,
        address _tokenRegistry,
        address _creatorTokenFactory,
        address _permit2
    ) internal onlyInitializing {
        __PumConverter_init(_owner, _prexPoint);

        positionManager = _positionManager;
        tokenRegistry = _tokenRegistry;
        permit2 = IPermit2(_permit2);
        creatorTokenFactory = CreatorTokenFactory(_creatorTokenFactory);
    }

    function setPumHook(address _pumHook) external onlyOwner {
        pumHook = PumHook(_pumHook);
    }

    /**
     * @notice ユニバーサルルーターを設定する
     * @param _universalRouter ユニバーサルルーターのアドレス
     */
    function setUniversalRouter(address _universalRouter) external onlyOwner {
        universalRouter = _universalRouter;

        // approve CARRY token
        carryToken.approve(address(permit2), type(uint256).max);
        permit2.approve(address(carryToken), address(universalRouter), type(uint160).max, type(uint48).max);
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
        bytes memory metadata,
        uint256 creditAmount
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

        // initial buy
        if (creditAmount > 0) {
            _initialSwap(creatorToken, creditAmount, issuer);
        }

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
            // min sqrt price
            return uint160(4295128739);
        } else {
            // max sqrt price
            return uint160(1461446703485210103287273052203988822378723970341);
        }
    }

    function _initializePool(address tokenA, address tokenB) internal {
        uint256 sqrtPriceX96 = _getStartSqrtPriceX96(tokenA, tokenB);

        PoolKey memory poolKey = RouterLib.getPoolKey(tokenA, tokenB, address(pumHook));

        IPoolManager poolManager = IPositionManager(positionManager).poolManager();

        poolManager.initialize(poolKey, uint160(sqrtPriceX96));
    }

    function _addLiquidity(address tokenA, address tokenB) internal {
        bytes memory actions = new bytes(3);

        actions[0] = bytes1(uint8(Actions.MINT_POSITION));
        actions[1] = bytes1(uint8(Actions.MINT_POSITION));
        actions[2] = bytes1(uint8(Actions.SETTLE_PAIR));

        bytes[] memory params = new bytes[](3);
        params[0] = _encodeIncreaseParams(
            RouterLib.getPoolKey(tokenA, tokenB, address(pumHook)),
            int24(tokenA < tokenB ? -340500 : -887100),
            int24(tokenA < tokenB ? 887100 : 340500),
            32329285099435181112,
            type(uint128).max,
            type(uint128).max,
            address(this)
        );
        params[1] = _encodeIncreaseParams(
            RouterLib.getPoolKey(tokenA, tokenB, address(pumHook)),
            int24(tokenA < tokenB ? -370800 : -887100),
            int24(tokenA < tokenB ? 887100 : 370800),
            1776694939356593754,
            type(uint128).max,
            type(uint128).max,
            address(this)
        );
        params[2] = abi.encode(tokenA, tokenB);

        tokenIdMap[tokenA] = IPositionManager(positionManager).nextTokenId();

        IPositionManager(positionManager).modifyLiquidities(abi.encode(actions, params), block.timestamp);
    }

    function _initialSwap(address creatorToken, uint256 initialAmount, address issuer) internal {
        bytes memory data = RouterLib.createUniversalRouterCommand(
            address(carryToken), address(creatorToken), initialAmount, address(pumHook)
        );

        // burn initial amount of PUM point
        pumPoint.burn(initialAmount);
        // mint initial amount of CARRY token
        carryToken.mint(address(this), initialAmount);

        _executeUniversalRouter(data);

        uint256 creatorTokenAmount = IERC20(creatorToken).balanceOf(address(this));

        creatorTokenAmount = roundDown(creatorTokenAmount, 18);

        // transfer creator token to issuer
        IERC20(creatorToken).transfer(issuer, creatorTokenAmount);

        emit InitialSwap(creatorToken, issuer, address(pumPoint), initialAmount, creatorTokenAmount);
    }

    function roundDown(uint256 value, uint256 decimals) internal pure returns (uint256) {
        return (value / (10 ** decimals)) * (10 ** decimals);
    }

    /// @notice ユニバーサルルーターを実行する
    function _executeUniversalRouter(bytes memory data) internal {
        (bool success, bytes memory returnData) = universalRouter.call(data);
        if (!success) {
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }
    }

    /**
     * @notice 手数料を収集する
     * @param tokenA トークンAのアドレス
     * @param tokenB トークンBのアドレス
     * @param tokenId トークンのID
     * @param recipient 手数料を受け取るアドレス
     */
    function _collectFee(address tokenA, address tokenB, uint256 tokenId, address recipient) internal {
        bytes memory actions = new bytes(2);

        actions[0] = bytes1(uint8(Actions.DECREASE_LIQUIDITY));
        actions[1] = bytes1(uint8(Actions.TAKE_PAIR));

        bytes[] memory params = new bytes[](2);
        params[0] = _encodeDecreaseLiquidityParams(tokenId, 0, 0, 0);
        params[1] = abi.encode(tokenA, tokenB, recipient);
        IPositionManager(positionManager).modifyLiquidities(abi.encode(actions, params), block.timestamp);
    }

    /// @notice LP用の流動性追加パラメータをエンコードする
    function _encodeIncreaseParams(
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

    /// @notice LP用の流動性削除パラメータをエンコードする
    function _encodeDecreaseLiquidityParams(uint256 tokenId, uint256 liquidity, uint128 amount0Min, uint128 amount1Min)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(tokenId, liquidity, amount0Min, amount1Min, bytes(""));
    }
}
