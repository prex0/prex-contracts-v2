// test/IssueHandlerTest.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../../src/handlers/token/IssueCreatorTokenHandler.sol";
import "../../../lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import "../../../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {CarryToken} from "../../../src/swap/CarryToken.sol";

contract MockPermit2 {
    function approve(address, address, uint160, uint48) external {}
}

contract HandlerV2 is IssueCreatorTokenHandler {
    function newMethod() public returns (uint256) {
        return 100;
    }
}

contract IssueCreatorHandlerTest is Test {
    IssueCreatorTokenHandler public logic;
    ProxyAdmin public proxyAdmin;
    TransparentUpgradeableProxy public proxy;
    MockPermit2 public permit2;

    address public token = address(0x1234);
    address public owner = address(0x7);

    function setUp() public {
        permit2 = new MockPermit2();
        logic = new IssueCreatorTokenHandler();

        bytes memory initData = abi.encodeWithSelector(
            IssueCreatorTokenHandler.initialize.selector,
            owner,
            address(0),
            address(0),
            address(0),
            address(0),
            address(permit2)
        );

        proxy = new TransparentUpgradeableProxy(address(logic), owner, initData);
    }

    function testInitializeAndIssue() public {
        address admin = getAdminAddress(address(proxy));
        IssueCreatorTokenHandler handler = IssueCreatorTokenHandler(address(proxy));

        assertEq(handler.points(), 0);

        HandlerV2 logicV2 = new HandlerV2();

        vm.prank(owner);
        ProxyAdmin(admin).upgradeAndCall(ITransparentUpgradeableProxy(address(proxy)), address(logicV2), bytes(""));

        HandlerV2 handlerV2 = HandlerV2(address(proxy));

        assertEq(handlerV2.newMethod(), 100);
    }

    function getAdminAddress(address proxy) internal view returns (address) {
        address CHEATCODE_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;
        Vm vm = Vm(CHEATCODE_ADDRESS);

        bytes32 adminSlot = vm.load(proxy, ERC1967Utils.ADMIN_SLOT);
        return address(uint160(uint256(adminSlot)));
    }
}
