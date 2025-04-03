// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../../src/interfaces/IOrderHandler.sol";

struct ClaimInfo {
    bytes32 requestId;
    string idempotencyKey;
    uint256 deadline;
    address recipient;
}

struct ClaimDropRequest {
    ClaimInfo claimInfo;
    bytes sig;
    address subPublicKey;
    bytes subSig;
}
