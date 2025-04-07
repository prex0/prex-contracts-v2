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

contract ExecuteWithUserTest is OrderExecutorSetup {
    using TransferRequestLib for TransferRequest;

    function setUp() public virtual override {
        super.setUp();
    }

    function test_Execute() public {
        TransferRequest memory request = createSampleRequest(user, user2);

        orderExecutor.execute(
            SignedOrder({
                dispatcher: address(transferRequestHandler),
                methodId: 0,
                order: abi.encode(request),
                signature: _sign(request, userPrivateKey),
                appSig: bytes(""),
                identifier: bytes32(0)
            }),
            bytes("")
        );

        // check PrexCredit is consumed
        assertEq(prexPoint.balanceOf(user), 995 * 1e6);
    }

    // クレジット不足では、オーダーを実行できない
    function test_Execute_InsufficientCredit() public {
        TransferRequest memory request = createSampleRequest(user2, user);

        vm.expectRevert(abi.encodeWithSelector(IPolicyErrors.InsufficientCredit.selector, 5 * 1e6, 0));
        orderExecutor.execute(
            SignedOrder({
                dispatcher: address(transferRequestHandler),
                methodId: 0,
                order: abi.encode(request),
                signature: _sign(request, userPrivateKey2),
                appSig: bytes(""),
                identifier: bytes32(0)
            }),
            bytes("")
        );
    }

    // 登録されていないハンドラーでは、オーダーを実行できない
    function test_Execute_InvalidHandler() public {
        orderExecutor.removeHandler(address(transferRequestHandler));

        TransferRequest memory request = createSampleRequest(user, user2);

        SignedOrder memory order = SignedOrder({
            dispatcher: address(transferRequestHandler),
            methodId: 0,
            order: abi.encode(request),
            signature: _sign(request, userPrivateKey),
            appSig: bytes(""),
            identifier: bytes32(0)
        });

        vm.expectRevert(abi.encodeWithSelector(IPolicyErrors.InvalidHandler.selector));
        orderExecutor.execute(order, bytes(""));
    }
}
