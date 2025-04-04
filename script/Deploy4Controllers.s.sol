// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ProfileRegistryV2} from "../src/data/ProfileRegistryV2.sol";
import {TokenRegistry} from "../src/data/TokenRegistry.sol";
import {BuyLoyaltyPointHandler} from "../src/handlers/point/BuyLoyaltyPointHandler.sol";
import {IssueCreatorTokenHandler} from "../src/handlers/token/IssueCreatorTokenHandler.sol";
import {IssueTokenHandler} from "../src/handlers/token/IssueTokenHandler.sol";
import {IssueLoyaltyTokenHandler} from "../src/handlers/token/IssueLoyaltyTokenHandler.sol";
import {PumHook} from "../src/swap/hooks/PumHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";

contract DeployPointScript is Script {
    address public constant OWNER_ADDRESS = 0x51B89C499F3038756Eff64a0EF52d753147EAd75;

    address public constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    address public constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address public DAI_ADDRESS = vm.envAddress("DAI_ADDRESS");

    address public constant POSITION_MANAGER = 0x3C3Ea4B57a46241e54610e5f022E5c45859A1017;

    address public constant POOL_MANAGER = 0x9a13F98Cb987694C9F086b1F5eB990EeA8264Ec3;

    address public constant PREX_TOKEN_FACTORY = 0x915C46a9f818fF2Ed56f20F52C7Eb5B7be17712a;

    address public constant CREATOR_TOKEN_FACTORY = 0x8Ede005980d9762C8e443722957b3d5147e3140C;

    address public constant PROFILE_REGISTRY = 0x8A4e21d9C0258A7330A70513ce680fC3843dA4B0;

    address public constant TOKEN_REGISTRY = 0x57F3891da461C783231A79328aa11AE6C724E9B2;

    address public constant POINT_MINTER = 0xAd77509161a564cF02790E12d56928940a556cbB;

    address public constant DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    address public constant PREX_POINT = 0x97135B409df491A01319D02E776A4DB9B3b8ce76;

    function run() public {
        vm.startBroadcast();

        // Deploy Loyalty Point and Market
        BuyLoyaltyPointHandler loyaltyPointHandler = new BuyLoyaltyPointHandler{
            salt: keccak256("BuyLoyaltyPointHandler")
        }(msg.sender, PERMIT2_ADDRESS, OWNER_ADDRESS);

        loyaltyPointHandler.addMinter(POINT_MINTER);

        loyaltyPointHandler.transferOwnership(OWNER_ADDRESS);

        console.log("BuyLoyaltyPointHandler deployed at", address(loyaltyPointHandler));
        console.log("LOYALTY Point deployed at", address(loyaltyPointHandler.point()));

        // Deploy Creator Token Issue Handler
        IssueCreatorTokenHandler issueCreatorTokenHandler = new IssueCreatorTokenHandler{
            salt: keccak256("IssueCreatorTokenHandler")
        }(msg.sender, PREX_POINT, POSITION_MANAGER, TOKEN_REGISTRY, CREATOR_TOKEN_FACTORY, PERMIT2_ADDRESS);

        issueCreatorTokenHandler.setDai(DAI_ADDRESS);

        (, bytes32 pumHookSalt) = _mineAddress(address(issueCreatorTokenHandler.carryToken()));
        PumHook pumHook =
            new PumHook{salt: pumHookSalt}(POOL_MANAGER, address(issueCreatorTokenHandler.carryToken()), OWNER_ADDRESS);

        issueCreatorTokenHandler.setPumHook(address(pumHook));
        issueCreatorTokenHandler.transferOwnership(OWNER_ADDRESS);

        console.log("IssueCreatorTokenHandler deployed at", address(issueCreatorTokenHandler));

        // Deploy Token Issue Handler
        IssueTokenHandler issueTokenHandler =
            new IssueTokenHandler{salt: keccak256("IssueTokenHandler")}(PERMIT2_ADDRESS, TOKEN_REGISTRY);

        console.log("IssueTokenHandler deployed at", address(issueTokenHandler));

        // Deploy Loyalty Token Issue Handler
        IssueLoyaltyTokenHandler issueLoyaltyTokenHandler = new IssueLoyaltyTokenHandler{
            salt: keccak256("IssueLoyaltyTokenHandler")
        }(msg.sender, address(loyaltyPointHandler.point()), PERMIT2_ADDRESS, TOKEN_REGISTRY);

        issueLoyaltyTokenHandler.setDai(DAI_ADDRESS);

        issueLoyaltyTokenHandler.transferOwnership(OWNER_ADDRESS);

        console.log("IssueLoyaltyTokenHandler deployed at", address(issueLoyaltyTokenHandler));

        vm.stopBroadcast();
    }

    function _mineAddress(address carryToken) internal view returns (address, bytes32) {
        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG);
        bytes memory constructorArgs = abi.encode(POOL_MANAGER, carryToken, OWNER_ADDRESS);
        (address hookAddress, bytes32 salt) =
            HookMiner.find(address(DEPLOYER), flags, type(PumHook).creationCode, constructorArgs);

        return (hookAddress, salt);
    }
}
