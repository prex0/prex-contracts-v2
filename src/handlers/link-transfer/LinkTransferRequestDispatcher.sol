// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./LinkTransferRequest.sol";
import "../../../lib/solmate/src/tokens/ERC20.sol";
import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import "../../../lib/permit2/src/interfaces/IPermit2.sol";
import "../../../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../../../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import "../../../lib/solmate/src/utils/ReentrancyGuard.sol";
import "../../../src/interfaces/IOrderHandler.sol";

/**
 * @notice OnetimeLockRequestDispatcher is a contract that allows the sender to create a request with a secret key.
 * The recipient can complete the request by providing the signature of the secret key.
 * This contract integrates with the Permit2 library to handle ERC20 token transfers securely and efficiently.
 */
contract LinkTransferRequestDispatcher is ReentrancyGuard {
    using LinkTransferRequestLib for LinkTransferRequest;

    enum RequestStatus {
        NotSubmitted,
        Pending,
        Completed,
        Cancelled
    }

    struct PendingRequest {
        uint256 amount;
        address token;
        address publicKey;
        address sender;
        uint256 nonce;
        uint256 expiry;
        RequestStatus status;
        uint256 policyId;
    }

    mapping(bytes32 => PendingRequest) public pendingRequests;

    uint256 private constant MAX_EXPIRY = 180 days;

    IPermit2 immutable permit2;

    uint256 public constant POINTS = 1;

    // Request errors
    /// @notice The request already exists
    error RequestAlreadyExists();
    /// @notice The request has expired
    error RequestExpired();
    /// @notice The request has not expired
    error RequestNotExpired();
    /// @notice The request is not pending
    error RequestIsNotPending();
    /// @notice The recipient is not set
    error RecipientNotSet();
    /// @notice The secret is invalid
    error InvalidSecret();
    /// @notice The dispatcher is invalid
    error InvalidDispatcher();
    /// @notice The deadline is invalid
    error InvalidDeadline();
    /// @notice The amount is invalid
    error InvalidAmount();
    /// @notice The deadline has passed
    error DeadlinePassed();
    /// @notice The transfer failed
    error TransferFailed();
    /// @notice The sender is invalid
    error InvalidSender();

    struct RecipientData {
        bytes32 requestId;
        address recipient;
        bytes sig;
        bytes metadata;
    }

    event RequestSubmitted(bytes32 id, address token, address sender, uint256 amount, uint256 expiry, bytes metadata);
    event RequestCompleted(bytes32 id, address recipient, bytes metadata);
    event RequestCancelled(bytes32 id);

    constructor(address _permit2) {
        permit2 = IPermit2(_permit2);
    }

    /**
     * @notice Submits a new transfer request.
     * The submitter's signature is verified by Permit2
     * @param request The transfer request
     * @param sig The submitter's signature
     */
    function createRequest(LinkTransferRequest memory request, bytes memory sig)
        internal
        nonReentrant
        returns (OrderReceipt memory)
    {
        bytes32 id = keccak256(abi.encode(request.publicKey));

        // same public key cannot be used for multiple requests
        if (pendingRequests[id].status != RequestStatus.NotSubmitted) {
            revert RequestAlreadyExists();
        }

        if (request.deadline == 0) {
            revert InvalidDeadline();
        }

        // Expiry period longer than 180 days is invalid
        if (request.deadline > block.timestamp + MAX_EXPIRY) {
            revert InvalidDeadline();
        }

        if (request.amount == 0) {
            revert InvalidAmount();
        }

        // Verify the signature
        _verifySenderRequest(request, sig);

        pendingRequests[id] = PendingRequest({
            amount: request.amount,
            token: request.token,
            publicKey: request.publicKey,
            sender: request.sender,
            nonce: request.nonce,
            expiry: request.deadline,
            status: RequestStatus.Pending,
            policyId: request.policyId
        });

        emit RequestSubmitted(id, request.token, request.sender, request.amount, request.deadline, request.metadata);

        return request.getOrderReceipt(POINTS);
    }

    /**
     * @notice Completes a pending request.
     * This function is executed by the recipient after they receive the secret from the sender.
     * @param recipientData The recipient data
     */
    function completeRequest(RecipientData memory recipientData) internal nonReentrant returns (OrderReceipt memory) {
        PendingRequest storage request = pendingRequests[recipientData.requestId];

        if (recipientData.recipient == address(0)) {
            revert RecipientNotSet();
        }

        if (request.status != RequestStatus.Pending) {
            revert RequestIsNotPending();
        }

        if (request.expiry < block.timestamp) {
            revert RequestExpired();
        }

        _verifyRecipientSignature(
            request.nonce, request.expiry, request.publicKey, recipientData.recipient, recipientData.sig
        );

        uint256 amount = request.amount;

        request.amount = 0;
        request.status = RequestStatus.Completed;

        if (!ERC20(request.token).transfer(recipientData.recipient, amount)) {
            revert TransferFailed();
        }

        emit RequestCompleted(recipientData.requestId, recipientData.recipient, recipientData.metadata);

        return getOrderReceipt(request);
    }

    function getOrderReceipt(PendingRequest memory request) internal pure returns (OrderReceipt memory) {
        address[] memory tokens = new address[](1);

        tokens[0] = request.token;

        return OrderReceipt({tokens: tokens, user: request.sender, policyId: request.policyId, points: 0});
    }

    /**
     * @notice Cancels a pending request.
     * @param id The request ID
     */
    function cancelRequest(bytes32 id) external nonReentrant {
        if (pendingRequests[id].sender != msg.sender) {
            revert InvalidSender();
        }

        _cancelRequest(id);
    }

    /**
     * /**
     * @notice Cancels pending requests.
     */
    function batchCancelRequest(bytes32[] memory ids) external nonReentrant {
        for (uint256 i = 0; i < ids.length; i++) {
            _cancelRequest(ids[i]);
        }
    }

    function _cancelRequest(bytes32 id) internal {
        PendingRequest storage request = pendingRequests[id];

        if (request.status != RequestStatus.Pending) {
            revert RequestIsNotPending();
        }

        require(request.expiry > 0, "Expiry not set");

        if (block.timestamp < request.expiry) {
            revert RequestNotExpired();
        }

        uint256 amount = request.amount;

        request.amount = 0;
        request.status = RequestStatus.Cancelled;

        if (!ERC20(request.token).transfer(request.sender, amount)) {
            revert TransferFailed();
        }

        emit RequestCancelled(id);
    }

    /**
     * @notice Returns the request ID for a given request.
     * @param request The request
     * @return id The request ID
     */
    function getRequestId(LinkTransferRequest memory request) external pure returns (bytes32) {
        return keccak256(abi.encode(request.publicKey));
    }

    /**
     * @notice Verifies the request and the signature.
     */
    function _verifySenderRequest(LinkTransferRequest memory request, bytes memory sig) internal {
        if (address(this) != address(request.dispatcher)) {
            revert InvalidDispatcher();
        }

        if (block.timestamp > request.deadline) {
            revert DeadlinePassed();
        }

        permit2.permitWitnessTransferFrom(
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({token: request.token, amount: request.amount}),
                nonce: request.nonce,
                deadline: request.deadline
            }),
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: request.amount}),
            request.sender,
            request.hash(),
            LinkTransferRequestLib.PERMIT2_ORDER_TYPE,
            sig
        );
    }

    /**
     * @notice Verifies the signature made by the recipient using the private key received from the sender.
     */
    function _verifyRecipientSignature(
        uint256 nonce,
        uint256 deadline,
        address publicKey,
        address recipient,
        bytes memory signature
    ) internal view {
        bytes32 messageHash =
            MessageHashUtils.toEthSignedMessageHash(keccak256(abi.encode(address(this), nonce, deadline, recipient)));

        if (publicKey != ECDSA.recover(messageHash, signature)) {
            revert InvalidSecret();
        }
    }
}
