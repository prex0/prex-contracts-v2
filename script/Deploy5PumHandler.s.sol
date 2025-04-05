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

contract DeployPumHandlerScript is Script {
    address public constant OWNER_ADDRESS = 0x51B89C499F3038756Eff64a0EF52d753147EAd75;

    address public constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    address public DAI_ADDRESS = vm.envAddress("DAI_ADDRESS");

    address public POSITION_MANAGER = vm.envAddress("POSITION_MANAGER");

    address public POOL_MANAGER = vm.envAddress("POOL_MANAGER");

    address public constant CREATOR_TOKEN_FACTORY = 0xfC71eE6Dfe60E794F56D8D77A0F03C1325c57ad7;

    address public constant TOKEN_REGISTRY = 0x57F3891da461C783231A79328aa11AE6C724E9B2;

    address public constant DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    address public constant PREX_POINT = 0x74401F3866E057Ae41bf6C22d25235a1C7013B16;

    function run() public {
        vm.startBroadcast();

        // Deploy Creator Token Issue Handler
        IssueCreatorTokenHandler issueCreatorTokenHandler = new IssueCreatorTokenHandler{
            salt: keccak256("IssueCreatorTokenHandler2")
        }(msg.sender, PREX_POINT, POSITION_MANAGER, TOKEN_REGISTRY, CREATOR_TOKEN_FACTORY, PERMIT2_ADDRESS);

        issueCreatorTokenHandler.setDai(DAI_ADDRESS);

        (, bytes32 pumHookSalt) = _mineAddress(address(issueCreatorTokenHandler.carryToken()));
        PumHook pumHook =
            new PumHook{salt: pumHookSalt}(POOL_MANAGER, address(issueCreatorTokenHandler.carryToken()), OWNER_ADDRESS);

        issueCreatorTokenHandler.setPumHook(address(pumHook));
        issueCreatorTokenHandler.transferOwnership(OWNER_ADDRESS);

        console.log("IssueCreatorTokenHandler deployed at", address(issueCreatorTokenHandler));
        console.log("PumHook deployed at", address(pumHook));

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
