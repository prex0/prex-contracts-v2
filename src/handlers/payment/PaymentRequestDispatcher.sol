// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./CreatePaymentRequestOrder.sol";
import "./PaymentOrder.sol";
import "../../../lib/solmate/src/tokens/ERC20.sol";
import "../../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import "../../../lib/permit2/src/interfaces/IPermit2.sol";
import "../../../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../../../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import "../../../lib/solmate/src/utils/ReentrancyGuard.sol";
import {IOrderHandler} from "../../interfaces/IOrderHandler.sol";

contract PaymentRequestDispatcher is ReentrancyGuard {
    using CreatePaymentRequestOrderLib for CreatePaymentRequestOrder;
    using PaymentOrderLib for PaymentOrder;

    enum RequestStatus {
        NotSubmitted,
        Opened,
        Closed
    }

    struct PaymentRequest {
        uint256 policyId;
        address creator;
        bool isPrepaid;
        address token;
        uint256 amount;
        address recipient;
        uint256 expiry;
        uint256 leftPayments;
        string name;
        RequestStatus status;
    }

    mapping(bytes32 => PaymentRequest) public paymentRequests;

    uint256 private constant MAX_EXPIRY = 180 days;

    IPermit2 immutable permit2;

    uint256 public constant POINTS = 1;

    // Request errors
    /// @notice The request already exists
    error RequestAlreadyExists();
    /// @notice The request has expired
    error RequestExpired();
    /// @notice The recipient is not set
    error RecipientNotSet();
    /// @notice The deadline is invalid
    error InvalidDeadline();
    /// @notice The amount is invalid
    error InvalidAmount();
    /// @notice The transfer failed
    error TransferFailed();
    /// @notice The sender is invalid
    error InvalidSender();
    /// @notice The request is not opened
    error RequestIsNotOpened();
    /// @notice The request is not expired
    error RequestNotExpired();

    event PaymentRequestCreated(
        bytes32 id,
        address creator,
        address recipient,
        address token,
        uint256 amount,
        uint256 expiry,
        string name,
        uint256 maxPayments,
        bytes32 orderHash
    );
    event PaymentMade(bytes32 id, address sender, bytes metadata, bytes32 orderHash);
    event PaymentRequestCancelled(bytes32 id);

    constructor(address _permit2) {
        permit2 = IPermit2(_permit2);
    }

    /**
     * @notice Submits a new payment request.
     * The submitter's signature is verified by Permit2
     * @param request The payment request
     * @param sig The submitter's signature
     */
    function createPaymentRequest(CreatePaymentRequestOrder memory request, bytes memory sig, bytes32 orderHash)
        internal
        nonReentrant
        returns (OrderReceipt memory)
    {
        bytes32 id = request.hash();

        // same public key cannot be used for multiple requests
        if (paymentRequests[id].status == RequestStatus.Opened || paymentRequests[id].status == RequestStatus.Closed) {
            revert RequestAlreadyExists();
        }

        if (request.expiry == 0) {
            revert InvalidDeadline();
        }

        if (request.amount == 0) {
            revert InvalidAmount();
        }

        if (request.recipient == address(0)) {
            revert RecipientNotSet();
        }

        // Verify the signature
        _verifyCreatePaymentRequest(request, sig);

        paymentRequests[id] = PaymentRequest({
            policyId: request.orderInfo.policyId,
            creator: request.orderInfo.sender,
            isPrepaid: request.isPrepaid,
            token: request.token,
            amount: request.amount,
            recipient: request.recipient,
            expiry: request.expiry,
            leftPayments: request.maxPayments,
            name: request.name,
            status: RequestStatus.Opened
        });

        emit PaymentRequestCreated(
            id,
            request.creator,
            request.recipient,
            request.token,
            request.amount,
            request.expiry,
            request.name,
            request.maxPayments,
            orderHash
        );

        return request.getOrderReceipt(request.isPrepaid ? (POINTS * request.maxPayments) : POINTS);
    }

    /**
     * @notice Completes a payment request.
     * @param paymentOrder The payment order
     */
    function payToken(PaymentOrder memory paymentOrder, bytes memory sig, bytes32 orderHash)
        internal
        nonReentrant
        returns (OrderReceipt memory)
    {
        PaymentRequest storage request = paymentRequests[paymentOrder.requestId];

        if (request.status != RequestStatus.Opened) {
            revert RequestIsNotOpened();
        }

        if (request.expiry < block.timestamp) {
            revert RequestExpired();
        }

        _verifyPaymentRequest(request, paymentOrder, sig);

        request.leftPayments--;

        if (request.leftPayments == 0) {
            request.status = RequestStatus.Closed;

            emit PaymentRequestCancelled(paymentOrder.requestId);
        }

        emit PaymentMade(paymentOrder.requestId, paymentOrder.sender, paymentOrder.metadata, orderHash);

        return _getOrderReceipt(request);
    }

    function _getOrderReceipt(PaymentRequest memory request) internal pure returns (OrderReceipt memory) {
        address[] memory tokens = new address[](1);

        tokens[0] = request.token;

        return OrderReceipt({
            tokens: tokens,
            user: request.creator,
            policyId: request.policyId,
            points: request.isPrepaid ? 0 : POINTS
        });
    }

    /**
     * @notice Cancels a pending request.
     * @param id The request ID
     */
    function cancelPaymentRequest(bytes32 id) external {
        if (paymentRequests[id].creator != msg.sender) {
            revert InvalidSender();
        }

        _cancelPaymentRequest(id);
    }

    /**
     *
     * @notice Cancels pending requests.
     */
    function batchCancelPaymentRequest(bytes32[] memory ids) external nonReentrant {
        for (uint256 i = 0; i < ids.length; i++) {
            _cancelPaymentRequest(ids[i]);
        }
    }

    function _cancelPaymentRequest(bytes32 id) internal {
        PaymentRequest storage request = paymentRequests[id];

        if (request.status != RequestStatus.Opened) {
            revert RequestIsNotOpened();
        }

        require(request.expiry > 0, "Expiry not set");

        if (block.timestamp < request.expiry) {
            revert RequestNotExpired();
        }

        request.status = RequestStatus.Closed;

        emit PaymentRequestCancelled(id);
    }

    /**
     * @notice Returns the request ID for a given request.
     * @param request The request
     * @return id The request ID
     */
    function getRequestId(CreatePaymentRequestOrder memory request) external pure returns (bytes32) {
        return request.hash();
    }

    /**
     * @notice Verifies the request and the signature.
     */
    function _verifyCreatePaymentRequest(CreatePaymentRequestOrder memory request, bytes memory sig) internal {
        if (address(this) != address(request.orderInfo.dispatcher)) {
            revert IOrderHandler.InvalidDispatcher();
        }

        if (block.timestamp > request.orderInfo.deadline) {
            revert IOrderHandler.DeadlinePassed();
        }

        permit2.permitWitnessTransferFrom(
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({token: address(0), amount: 0}),
                nonce: request.orderInfo.nonce,
                deadline: request.orderInfo.deadline
            }),
            ISignatureTransfer.SignatureTransferDetails({to: address(0), requestedAmount: 0}),
            request.creator,
            request.hash(),
            CreatePaymentRequestOrderLib.PERMIT2_ORDER_TYPE,
            sig
        );
    }

    /**
     * @notice Verifies the payment order and the signature.
     */
    function _verifyPaymentRequest(PaymentRequest memory request, PaymentOrder memory paymentOrder, bytes memory sig)
        internal
    {
        if (address(this) != address(paymentOrder.dispatcher)) {
            revert IOrderHandler.InvalidDispatcher();
        }

        if (block.timestamp > paymentOrder.deadline) {
            revert IOrderHandler.DeadlinePassed();
        }

        permit2.permitWitnessTransferFrom(
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({token: request.token, amount: request.amount}),
                nonce: paymentOrder.nonce,
                deadline: paymentOrder.deadline
            }),
            ISignatureTransfer.SignatureTransferDetails({to: request.recipient, requestedAmount: request.amount}),
            paymentOrder.sender,
            paymentOrder.hash(),
            PaymentOrderLib.PERMIT2_ORDER_TYPE,
            sig
        );
    }
}
