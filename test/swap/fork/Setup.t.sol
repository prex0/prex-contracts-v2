// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SwapHandler} from "../../../src/handlers/swap/SwapHandler.sol";
import {SwapRequest, SwapRequestLib} from "../../../src/handlers/swap/SwapOrder.sol";
import {TestUtils} from "../../utils/TestUtils.sol";
import {ERC20} from "../../../lib/solmate/src/tokens/ERC20.sol";
import {OrderReceipt, SignedOrder} from "../../../src/interfaces/IOrderHandler.sol";
import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {MockToken} from "../../mock/MockToken.sol";
import {MockUniversalRouter} from "../../mock/MockUniversalRouter.sol";
import {TokenRegistry} from "../../../src/data/TokenRegistry.sol";
import {PumController} from "../../../src/swap/PumController.sol";
import {LoyaltyController} from "../../../src/swap/LoyaltyController.sol";
import {Currency, CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {PrexPoint} from "../../../src/credit/PrexPoint.sol";
import {PumHook} from "../../../src/swap/hooks/PumHook.sol";
import {CreatorTokenFactory} from "../../../src/token-factory/CreatorTokenFactory.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";
import "../../../lib/permit2/src/interfaces/IPermit2.sol";
import {CreateTokenParameters} from "../../../src/token-factory/CreatorTokenFactory.sol";

contract MockLoyaltyController is LoyaltyController {
    address public tokenRegistry;

    constructor(address _owner, address _dai, address _loyaltyPoint, address _tokenRegistry)
        LoyaltyController(_owner, _dai, _loyaltyPoint)
    {
        tokenRegistry = _tokenRegistry;
    }

    function createLoyaltyToken(CreateTokenParameters memory params, address _permit2) external returns (address) {
        return super._createLoyaltyToken(params, _permit2, tokenRegistry);
    }
}

contract MockPumController is PumController {
    constructor(
        address _owner,
        address _pumPoint,
        address _dai,
        address _positionManager,
        address _tokenRegistry,
        address _creatorTokenFactory,
        address _permit2
    ) PumController(_owner, _pumPoint, _dai, _positionManager, _tokenRegistry, _creatorTokenFactory, _permit2) {}

    function issuePumToken(
        address issuer,
        string memory name,
        string memory symbol,
        bytes32 pictureHash,
        bytes memory metadata
    ) external returns (address) {
        return super._issuePumToken(issuer, name, symbol, pictureHash, metadata);
    }
}

contract SwapRouterSetup is Test, TestUtils {
    using SwapRequestLib for SwapRequest;

    // the identifiers of the forks
    uint256 optimismFork;

    //Access variables from .env file via vm.envString("varname")
    //Replace ALCHEMY_KEY by your alchemy key or Etherscan key, change RPC url if need
    //inside your .env file e.g:
    //MAINNET_RPC_URL = 'https://eth-mainnet.g.alchemy.com/v2/ALCHEMY_KEY'
    //string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    string OPTIMISM_RPC_URL = vm.envString("RPC_URL");

    MockPumController public pumController;
    MockLoyaltyController public loyaltyController;

    SwapHandler public swapHandler;

    Currency currency0;
    Currency currency1;

    PrexPoint public pumPoint;
    PrexPoint public loyaltyPoint;
    CreatorTokenFactory public creatorTokenFactory;
    PumHook public pumHook;
    IERC20 public dai;

    // create two _different_ forks during setup
    function setUp() public virtual override {
        optimismFork = vm.createFork(OPTIMISM_RPC_URL);
        vm.selectFork(optimismFork);
        vm.rollFork(133_850_000);
        vm.chainId(10);

        IPermit2 permit2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);

        DOMAIN_SEPARATOR = permit2.DOMAIN_SEPARATOR();

        dai = IERC20(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);

        pumPoint =
            new PrexPoint("PrexPoint", "PREX", address(this), address(0x000000000022D473030F116dDEE9F6B43aC78BA3));
        loyaltyPoint =
            new PrexPoint("LoyaltyPoint", "LOYALTY", address(this), address(0x000000000022D473030F116dDEE9F6B43aC78BA3));
        TokenRegistry tokenRegistry = new TokenRegistry();
        creatorTokenFactory = new CreatorTokenFactory();
        pumController = new MockPumController(
            address(this),
            address(pumPoint),
            address(dai),
            address(0x3C3Ea4B57a46241e54610e5f022E5c45859A1017),
            address(tokenRegistry),
            address(creatorTokenFactory),
            address(0x000000000022D473030F116dDEE9F6B43aC78BA3)
        );
        (, bytes32 pumHookSalt) = _mineAddress();
        pumHook = new PumHook{salt: pumHookSalt}(
            address(0x9a13F98Cb987694C9F086b1F5eB990EeA8264Ec3), address(pumController.carryToken()), address(this)
        );
        pumController.setPumHook(address(pumHook));

        // Set pumController as consumer
        pumPoint.setConsumer(address(pumController));
        loyaltyController =
            new MockLoyaltyController(address(this), address(dai), address(loyaltyPoint), address(tokenRegistry));

        loyaltyPoint.setConsumer(address(loyaltyController));

        swapHandler = new SwapHandler(
            address(0x851116D9223fabED8E56C0E6b8Ad0c31d98B3507),
            address(loyaltyController),
            address(pumController),
            address(0x000000000022D473030F116dDEE9F6B43aC78BA3),
            address(this)
        );

        // Deposit DAI to PumController
        deal(address(dai), address(this), 20000 * 1e18);
        dai.approve(address(pumController), 10000 * 1e18);
        pumController.depositDai(10000 * 1e18);

        // Deposit DAI to LoyaltyController
        dai.approve(address(loyaltyController), 10000 * 1e18);
        loyaltyController.depositDai(10000 * 1e18);

        // CarryToken
        currency0 = Currency.wrap(address(pumController.carryToken()));
    }

    function createSignedOrder(
        uint256 userPrivateKey,
        address user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 nonce
    ) public view returns (SignedOrder memory) {
        SwapRequest memory request = SwapRequest({
            dispatcher: address(swapHandler),
            policyId: 0,
            swapper: user,
            recipient: user,
            deadline: block.timestamp + 60,
            nonce: nonce,
            exactIn: true,
            tokenIn: address(tokenIn),
            tokenOut: address(tokenOut),
            amountIn: amountIn,
            amountOut: amountOut
        });

        return SignedOrder({
            dispatcher: address(swapHandler),
            methodId: 0,
            order: abi.encode(request),
            signature: _sign(request, userPrivateKey),
            appSig: bytes(""),
            identifier: bytes32(0)
        });
    }

    function _sign(SwapRequest memory request, uint256 fromPrivateKey) internal view returns (bytes memory) {
        bytes32 witness = request.hash();

        return getPermit2Signature(
            fromPrivateKey,
            _toPermit(request),
            address(swapHandler),
            SwapRequestLib.PERMIT2_ORDER_TYPE,
            witness,
            DOMAIN_SEPARATOR
        );
    }

    function _toPermit(SwapRequest memory request)
        internal
        pure
        returns (ISignatureTransfer.PermitTransferFrom memory)
    {
        return ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: request.tokenIn, amount: request.amountIn}),
            nonce: request.nonce,
            deadline: request.deadline
        });
    }

    function _mineAddress() internal view returns (address, bytes32) {
        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG);
        bytes memory constructorArgs = abi.encode(
            address(0x9a13F98Cb987694C9F086b1F5eB990EeA8264Ec3), address(pumController.carryToken()), address(this)
        );
        (address hookAddress, bytes32 salt) =
            HookMiner.find(address(this), flags, type(PumHook).creationCode, constructorArgs);

        return (hookAddress, salt);
    }
}
