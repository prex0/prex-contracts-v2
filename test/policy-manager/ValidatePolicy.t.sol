// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PolicyManagerSetup} from "./Setup.t.sol";
import {PolicyManager} from "../../src/policy-manager/PolicyManager.sol";
import {IPolicyErrors} from "../../src/interfaces/IPolicyErrors.sol";
import {OrderReceipt} from "../../src/interfaces/IOrderHandler.sol";
import {OrderHeader} from "../../src/interfaces/IOrderExecutor.sol";
import {SignatureVerification} from "../../lib/permit2/src/libraries/SignatureVerification.sol";

contract MockPolicyValidator {
    function validatePolicy(OrderHeader memory, OrderReceipt memory, bytes calldata policyParams)
        external
        pure
        returns (bool)
    {
        bool result = abi.decode(policyParams, (bool));

        return result;
    }
}

contract ValidatePolicyTest is PolicyManagerSetup {
    uint256 appId;

    uint256 policyIdTrue;
    uint256 policyIdFalse;

    uint256 internal policyPrivateKey = 12347;
    address public policyPublicKey = vm.addr(policyPrivateKey);

    uint256 internal policyPrivateKeyInvalid = 12348;
    address public policyPublicKeyInvalid = vm.addr(policyPrivateKeyInvalid);

    address public handler = vm.addr(12348);
    address public handlerNotFound = vm.addr(12349);

    address public user = vm.addr(12350);

    bytes32 public orderHash = keccak256(abi.encode("test"));

    bytes32 public orderHashForPolicyTrue;
    bytes32 public orderHashForPolicyFalse;

    function setUp() public virtual override {
        super.setUp();

        MockPolicyValidator validator = new MockPolicyValidator();

        policyManager.addHandler(address(handler));

        appId = policyManager.registerApp(appOwner1, "test");

        vm.startPrank(appOwner1);
        policyIdTrue =
            policyManager.registerPolicy(appId, address(validator), policyPublicKey, abi.encode(true), "true");
        policyIdFalse =
            policyManager.registerPolicy(appId, address(validator), policyPublicKey, abi.encode(false), "false");
        vm.stopPrank();

        orderHashForPolicyTrue = policyManager.getOrderHashForPolicy(abi.encode("test"), policyIdTrue, bytes32(0));
        orderHashForPolicyFalse = policyManager.getOrderHashForPolicy(abi.encode("test"), policyIdFalse, bytes32(0));
    }

    // ハンドラーが不正な場合はリバートする
    function test_ValidatePolicy_InvalidHandler() public {
        vm.expectRevert(abi.encodeWithSelector(IPolicyErrors.InvalidHandler.selector));
        policyManager.validatePolicy(
            OrderHeader({dispatcher: handlerNotFound, methodId: 0, orderHash: orderHash, identifier: bytes32(0)}),
            OrderReceipt({user: address(0), policyId: policyIdTrue, tokens: new address[](0), points: 0}),
            _signMessage(policyPrivateKey, orderHashForPolicyTrue)
        );
    }

    // ポリシーが不正な場合はリバートする
    function test_ValidatePolicy_InvalidPolicy() public {
        vm.expectRevert(abi.encodeWithSelector(IPolicyErrors.InvalidPolicy.selector));
        policyManager.validatePolicy(
            OrderHeader({dispatcher: handler, methodId: 0, orderHash: orderHash, identifier: bytes32(0)}),
            OrderReceipt({user: address(0), policyId: policyIdFalse, tokens: new address[](0), points: 0}),
            _signMessage(policyPrivateKey, orderHashForPolicyFalse)
        );
    }

    // ポリシーが非アクティブな場合はリバートする
    function test_ValidatePolicy_InactivePolicy() public {
        vm.startPrank(appOwner1);
        policyManager.updatePolicyStatus(policyIdTrue, false);
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(IPolicyErrors.InactivePolicy.selector));
        policyManager.validatePolicy(
            OrderHeader({dispatcher: handler, methodId: 0, orderHash: orderHash, identifier: bytes32(0)}),
            OrderReceipt({user: address(0), policyId: policyIdTrue, tokens: new address[](0), points: 0}),
            _signMessage(policyPrivateKey, orderHashForPolicyTrue)
        );
    }

    // アプリ署名が不正な場合はリバートする
    function test_ValidatePolicy_InvalidAppSignature() public {
        vm.expectRevert(SignatureVerification.InvalidSigner.selector);
        policyManager.validatePolicy(
            OrderHeader({dispatcher: handler, methodId: 0, orderHash: orderHash, identifier: bytes32(0)}),
            OrderReceipt({user: address(0), policyId: policyIdTrue, tokens: new address[](0), points: 0}),
            _signMessage(policyPrivateKeyInvalid, orderHashForPolicyTrue)
        );
    }

    // アプリがクレジットを消費するケース
    function test_ValidatePolicy_AppConsume() public {
        vm.startPrank(appOwner1);
        prexPoint.approve(address(policyManager), 1000 * 1e6);
        policyManager.depositCredit(appId, 1000 * 1e6);
        vm.stopPrank();

        policyManager.validatePolicy(
            OrderHeader({dispatcher: handler, methodId: 0, orderHash: orderHash, identifier: bytes32(0)}),
            OrderReceipt({user: address(0), policyId: policyIdTrue, tokens: new address[](0), points: 1}),
            _signMessage(policyPrivateKey, orderHashForPolicyTrue)
        );

        assertEq(prexPoint.balanceOf(address(policyManager)), 995 * 1e6);
        (address owner, uint256 credit,) = policyManager.apps(appId);
        assertEq(owner, appOwner1);
        assertEq(credit, 995 * 1e6);
    }

    // アプリがクレジットを消費するケースで、クレジットが足りない場合はリバートする
    function test_ValidatePolicy_AppConsume_InsufficientCredit() public {
        vm.expectRevert(abi.encodeWithSelector(IPolicyErrors.InsufficientCredit.selector));
        policyManager.validatePolicy(
            OrderHeader({dispatcher: handler, methodId: 0, orderHash: orderHash, identifier: bytes32(0)}),
            OrderReceipt({user: address(0), policyId: policyIdTrue, tokens: new address[](0), points: 1}),
            _signMessage(policyPrivateKey, orderHashForPolicyTrue)
        );
    }

    // ユーザーがクレジットを消費するケース
    function test_ValidatePolicy_UserConsume() public {
        policyManager.validatePolicy(
            OrderHeader({dispatcher: handler, methodId: 0, orderHash: orderHash, identifier: bytes32(0)}),
            OrderReceipt({
                user: user,
                // ポリシーIDが0の場合はユーザーが消費する
                policyId: 0,
                tokens: new address[](0),
                points: 0
            }),
            bytes("")
        );
    }
}
