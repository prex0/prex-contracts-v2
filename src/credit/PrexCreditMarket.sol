// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {PrexPointMarket} from "./PrexPointMarket.sol";
import {IPolicyManager} from "../interfaces/IPolicyManager.sol";

/**
 * @title PrexCreditMarket
 * @notice Market for PrexCredit
 */
contract PrexCreditMarket is PrexPointMarket {
    address public orderExecutor;

    event PointBoughtForApp(uint256 indexed appId, uint256 amount, uint256 method, bytes orderId);

    constructor(address _owner, address _permit2, address _feeRecipient)
        PrexPointMarket("PrexPoint", "PREXPOINT", _owner, _permit2, _feeRecipient)
    {}

    function setOrderExecutor(address _orderExecutor) external onlyOwner {
        orderExecutor = _orderExecutor;
    }

    function mintForApp(uint256 appId, uint256 amount, uint256 method, string memory orderId) public onlyMinter {
        _issueNewPoint(address(this), amount, method, bytes(orderId));

        IERC20(point).approve(address(orderExecutor), amount);
        IPolicyManager(orderExecutor).depositCredit(appId, amount);

        emit PointBoughtForApp(appId, amount, method, bytes(orderId));
    }
}
