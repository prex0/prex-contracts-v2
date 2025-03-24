// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./DropRequest.sol";
import "../../../lib/solmate/src/tokens/ERC20.sol";
import "../../../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../../../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import "../../../lib/permit2/src/interfaces/IPermit2.sol";
import "../../../lib/solmate/src/utils/ReentrancyGuard.sol";

struct RecipientData {
    bytes32 requestId;
    address recipient;
    uint256 nonce;
    uint256 deadline;
    bytes sig;
    address subPublicKey;
    bytes subSig;
}

/**
 * @notice TokenDistributor is a contract that allows senders to create multiple distribution requests.
 * Each request can have multiple recipients who can claim their allocated tokens.
 * Recipients complete their claims by providing the signature of a secret key associated with the request.
 * This contract integrates with the Permit2 library to handle ERC20 token transfers securely and efficiently.
 * It supports multiple concurrent requests, enabling flexible and scalable token distribution scenarios.
 */
contract DropRequestHandler is ReentrancyGuard {
    using DropRequestLib for DropRequest;

    enum RequestStatus {
        NotSubmitted,
        Pending,
        Cancelled,
        Completed
    }

    struct PendingRequest {
        uint256 amount;
        uint256 amountPerWithdrawal;
        address token;
        address publicKey;
        address sender;
        uint256 expiry;
        RequestStatus status;
        string name;
    }

    mapping(address => bytes32) public publicKeyToRequestId;

    mapping(bytes32 => PendingRequest) public pendingRequests;

    /// @dev nonce => isUsed
    mapping(uint256 => bool) public nonceUsedMap;

    IPermit2 public immutable permit2;

    /// @dev Error codes
    error InvalidRequest();
    /// request already exists
    error RequestAlreadyExists();
    /// request is not pending
    error RequestNotPending();
    /// request is expired
    error RequestExpiredError();
    /// insufficient funds
    error InsufficientFunds();
    /// request is not expired
    error RequestNotExpired();
    /// caller is not sender
    error CallerIsNotSender();
    /// nonce used
    error NonceUsed();
    /// invalid secret
    error InvalidSecret();

    // common permit2 errors
    /// invalid dispatcher
    error InvalidDispatcher();
    /// deadline passed
    error DeadlinePassed();
    /// public key already exists
    error PublicKeyAlreadyExists();

    /// invalid additional validation
    error InvalidAdditionalValidation();

    event Submitted(
        bytes32 id,
        address token,
        address sender,
        address publicKey,
        uint256 amount,
        uint256 amountPerWithdrawal,
        uint256 expiry,
        string name
    );

    event Deposited(bytes32 id, address depositor, uint256 amount);
    event Received(bytes32 id, address recipient, uint256 amount);
    event RequestCancelled(bytes32 id, uint256 amount);
    event RequestExpired(bytes32 id, uint256 amount);

    constructor(address _permit2) {
        permit2 = IPermit2(_permit2);
    }

    /**
     * @notice Submits a request to distribute tokens.
     * @dev Only facilitators can submit requests.
     * @param request The request to submit.
     * @param sig The signature of the request.
     */
    function submit(DropRequest memory request, bytes memory sig) public {
        bytes32 id = request.hash();

        if (!request.verify()) {
            revert InvalidRequest();
        }

        if (pendingRequests[id].status != RequestStatus.NotSubmitted) {
            revert RequestAlreadyExists();
        }

        _verifySubmitRequest(request, sig);

        pendingRequests[id] = PendingRequest({
            amount: request.amount,
            amountPerWithdrawal: request.amountPerWithdrawal,
            token: request.token,
            publicKey: request.publicKey,
            sender: request.sender,
            expiry: request.expiry,
            status: RequestStatus.Pending,
            name: request.name
        });

        if (publicKeyToRequestId[request.publicKey] != bytes32(0)) {
            revert PublicKeyAlreadyExists();
        }

        publicKeyToRequestId[request.publicKey] = id;

        emit Submitted(
            id,
            request.token,
            request.sender,
            request.publicKey,
            request.amount,
            request.amountPerWithdrawal,
            request.expiry,
            request.name
        );
    }

    /**
     * @notice Distribute the request to the recipient
     * @dev Only facilitators can submit distribute requests.
     * @param recipientData The data of the recipient.
     */
    function distribute(RecipientData memory recipientData) public {
        PendingRequest storage request = pendingRequests[recipientData.requestId];

        if (block.timestamp > request.expiry) {
            revert RequestExpiredError();
        }

        if (request.amount < request.amountPerWithdrawal) {
            revert InsufficientFunds();
        }

        _verifyRecipientData(request.publicKey, request.expiry, recipientData);

        request.amount -= request.amountPerWithdrawal;

        ERC20(request.token).transfer(recipientData.recipient, request.amountPerWithdrawal);

        emit Received(recipientData.requestId, recipientData.recipient, request.amountPerWithdrawal);
    }

    /**
     * @notice Cancel the request during distribution
     * @param id The ID of the request to cancel.
     */
    function cancelRequest(bytes32 id) public nonReentrant {
        PendingRequest storage request = pendingRequests[id];

        if (request.sender != msg.sender) {
            revert CallerIsNotSender();
        }

        if (request.status != RequestStatus.Pending) {
            revert RequestNotPending();
        }

        uint256 leftAmount = request.amount;

        request.amount = 0;

        request.status = RequestStatus.Cancelled;

        ERC20(request.token).transfer(request.sender, leftAmount);

        emit RequestCancelled(id, leftAmount);
    }

    /**
     * @notice Complete the request after the expiry
     * @param id The ID of the request to complete.
     */
    function completeRequest(bytes32 id) public {
        PendingRequest storage request = pendingRequests[id];

        if (request.expiry > block.timestamp) {
            revert RequestNotExpired();
        }

        if (request.status != RequestStatus.Pending) {
            revert RequestNotPending();
        }

        uint256 leftAmount = request.amount;

        request.amount = 0;

        request.status = RequestStatus.Completed;

        if (leftAmount > 0) {
            ERC20(request.token).transfer(request.sender, leftAmount);
        }

        emit RequestExpired(id, leftAmount);
    }

    /**
     * @notice Verifies the request and the signature.
     */
    function _verifySubmitRequest(DropRequest memory request, bytes memory sig) internal {
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
            DropRequestLib.PERMIT2_ORDER_TYPE,
            sig
        );
    }

    /**
     * @notice Verifies the signature made by the recipient using the private key received from the sender.
     */
    function _verifyRecipientData(address publicKey, uint256 expiry, RecipientData memory recipientData) internal {
        if (nonceUsedMap[recipientData.nonce]) {
            revert NonceUsed();
        }

        nonceUsedMap[recipientData.nonce] = true;

        if (block.timestamp > recipientData.deadline) {
            revert DeadlinePassed();
        }

        if (recipientData.subPublicKey != address(0)) {
            _verifyRecipientSignature(
                publicKey, recipientData.nonce, expiry, recipientData.subPublicKey, recipientData.sig
            );
            _verifyRecipientSignature(
                recipientData.subPublicKey,
                recipientData.nonce,
                recipientData.deadline,
                recipientData.recipient,
                recipientData.subSig
            );
        } else {
            _verifyRecipientSignature(
                publicKey, recipientData.nonce, recipientData.deadline, recipientData.recipient, recipientData.sig
            );
        }
    }

    function _verifyRecipientSignature(
        address publicKey,
        uint256 nonce,
        uint256 deadline,
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
