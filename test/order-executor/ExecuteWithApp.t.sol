// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TransferRequestHandler} from "../../src/handlers/transfer/TransferRequestHandler.sol";
import {TransferRequest, TransferRequestLib} from "../../src/handlers/transfer/TransferRequest.sol";
import {ERC20} from "../../lib/solmate/src/tokens/ERC20.sol";
import {PrexPoint} from "../../src/credit/PrexPoint.sol";
import {SignedOrder} from "../../src/interfaces/IOrderHandler.sol";
import {IERC20Errors} from "../../lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";
import {IPolicyErrors} from "../../src/interfaces/IPolicyErrors.sol";
import {OrderExecutorSetup} from "./Setup.t.sol";
import {StandardPolicyValidator} from "../../src/policies/StandardPolicyValidator.sol";

contract ExecuteWithAppTest is OrderExecutorSetup {
    using TransferRequestLib for TransferRequest;

    uint256 appId;
    uint256 testPolicyId;

    function setUp() public virtual override {
        super.setUp();

        StandardPolicyValidator policyValidator = new StandardPolicyValidator();

        appId = orderExecutor.registerApp(owner, "test");

        {
            address[] memory whitelist = new address[](1);
            whitelist[0] = address(0);

            bytes memory policyParams = abi.encode(whitelist, 1, 1 days);

            testPolicyId =
                orderExecutor.registerPolicy(appId, address(policyValidator), policyPublicKey, policyParams, "test");
        }

        prexPoint.approve(address(orderExecutor), 1000 * 1e6);
        orderExecutor.depositCredit(appId, 1000 * 1e6);
    }

    function createSampleRequest(address sender, address recipient, uint256 policyId)
        internal
        view
        returns (TransferRequest memory)
    {
        return TransferRequest({
            dispatcher: address(transferRequestHandler),
            policyId: policyId,
            sender: sender,
            recipient: recipient,
            deadline: 1,
            nonce: 1,
            amount: 100,
            token: address(0),
            category: 0,
            metadata: bytes("")
        });
    }

    // アプリにクレジットがある場合はクレジットを消費して実行する
    function test_ExecuteWithAppCredit() public {
        TransferRequest memory request = createSampleRequest(user, user2, testPolicyId);

        bytes32 orderHash = orderExecutor.getOrderHashForPolicy(abi.encode(request), testPolicyId, bytes32(0));

        orderExecutor.execute(
            SignedOrder({
                dispatcher: address(transferRequestHandler),
                methodId: 0,
                order: abi.encode(request),
                signature: _sign(request, userPrivateKey),
                appSig: _signMessage(policyPrivateKey, orderHash),
                identifier: bytes32(0)
            }),
            bytes("")
        );

        // check PrexCredit is consumed
        assertEq(prexPoint.balanceOf(address(orderExecutor)), 995 * 1e6);

        (, uint256 credit,) = orderExecutor.apps(appId);

        assertEq(credit, 995 * 1e6);
    }

    // アプリにクレジットがない場合はリバートする
    function test_ExecuteWithoutAppCredit() public {
        TransferRequest memory request = createSampleRequest(user, user2, testPolicyId);

        bytes32 orderHash = orderExecutor.getOrderHashForPolicy(abi.encode(request), testPolicyId, bytes32(0));

        orderExecutor.withdrawCredit(appId, 1000 * 1e6, owner);

        vm.expectRevert(abi.encodeWithSelector(IPolicyErrors.InsufficientCredit.selector, 5 * 1e6, 0));
        orderExecutor.execute(
            SignedOrder({
                dispatcher: address(transferRequestHandler),
                methodId: 0,
                order: abi.encode(request),
                signature: _sign(request, userPrivateKey),
                appSig: _signMessage(policyPrivateKey, orderHash),
                identifier: bytes32(0)
            }),
            bytes("")
        );
    }
}
