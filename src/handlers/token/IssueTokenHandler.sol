// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../interfaces/IOrderHandler.sol";

contract IssueTokenHandler is IOrderHandler {
    function execute(address _facilitator, SignedOrder calldata order, bytes calldata facilitatorData)
        external
        returns (OrderReceipt memory)
    {
        // TODO: Implement issue token logic
    }
}
