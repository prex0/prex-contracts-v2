// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../../src/interfaces/IOrderHandler.sol";

struct ClaimDropRequest {
    bytes32 requestId;
    address recipient;
    uint256 deadline;
    bytes sig;
    address subPublicKey;
    bytes subSig;
    string idempotencyKey;
}
