// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Owned} from "../../lib/solmate/src/auth/Owned.sol";
import {ISignatureTransfer} from "../../lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {IPermit2} from "../../lib/permit2/src/interfaces/IPermit2.sol";
import "./PrexPoint.sol";
import "./BuyPointOrder.sol";
import {IOrderHandler} from "../interfaces/IOrderHandler.sol";

/**
 * @title PrexPointMarket
 * @notice Market for PrexPoint
 */
contract PrexPointMarket is Owned {
    using BuyPointOrderLib for BuyPointOrder;

    PrexPoint public immutable point;

    IERC20 public stableToken;

    uint256 public pointPrice = 1e12 / 200;

    IPermit2 public immutable permit2;

    address public feeRecipient;

    mapping(address minter => bool) public minterMap;

    mapping(uint256 method => mapping(bytes idempotencyKey => bool)) private idempotencyKeyMap;

    error IdempotencyKeyAlreadyUsed();
    error InvalidMinter();
    error InvalidPointPrice();

    event PointBought(address indexed buyer, uint256 amount, uint256 method, bytes orderId);
    event FeeRecipientUpdated(address indexed newFeeRecipient);
    event MinterAdded(address indexed newMinter);
    event MinterRemoved(address indexed minter);

    modifier onlyMinter() {
        if (!minterMap[msg.sender]) {
            revert InvalidMinter();
        }
        _;
    }

    constructor(string memory name, string memory symbol, address owner, address _permit2, address _feeRecipient)
        Owned(owner)
    {
        permit2 = IPermit2(_permit2);
        feeRecipient = _feeRecipient;
        point = new PrexPoint(name, symbol, address(this), _permit2);
    }

    /**
     * @notice Set the stable token
     * @param _stableToken The address of the stable token
     */
    function setStableToken(address _stableToken) public onlyOwner {
        require(address(stableToken) == address(0), "StableToken already set");
        stableToken = IERC20(_stableToken);
    }

    /**
     * @notice Set the fee recipient
     * @param _feeRecipient The address of the fee recipient
     */
    function setFeeRecipient(address _feeRecipient) public onlyOwner {
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }

    /**
     * @notice Set the consumer
     * @param _consumer The address of the consumer
     */
    function setConsumer(address _consumer) public onlyOwner {
        point.setConsumer(_consumer);
    }

    /**
     * @notice Add a minter
     * @param newMinter The address of the new minter
     */
    function addMinter(address newMinter) public onlyOwner {
        minterMap[newMinter] = true;

        emit MinterAdded(newMinter);
    }

    /**
     * @notice Remove a minter
     * @param minter The address of the minter to remove
     */
    function removeMinter(address minter) public onlyOwner {
        minterMap[minter] = false;

        emit MinterRemoved(minter);
    }

    function moveOwnership(address newOwner) public onlyOwner {
        Owned(address(point)).transferOwnership(newOwner);
    }

    /**
     * @notice Set the price of 1e12 PrexPoint in 1e18
     * @param _pointPrice The price of 1e12 PrexPoint in 1e18
     */
    function setPointPrice(uint256 _pointPrice) public onlyOwner {
        if (_pointPrice == 0) {
            revert InvalidPointPrice();
        }
        pointPrice = _pointPrice;
    }

    /**
     * @notice Mint tokens
     * @param to The address to mint to
     * @param amount The amount of tokens to mint
     * @param method The method of the mint operation
     * @param orderId The idempotency key for the mint operation
     */
    function mint(address to, uint256 amount, uint256 method, string memory orderId) public onlyMinter {
        if (idempotencyKeyMap[method][bytes(orderId)]) {
            revert IdempotencyKeyAlreadyUsed();
        }

        _issueNewPoint(to, amount, method, bytes(orderId));
    }

    /**
     * @notice Buy tokens with DAI
     * @param order The order to buy
     * @param sig The signature of the order
     */
    function buy(BuyPointOrder memory order, bytes memory sig) internal {
        _verifyBuyOrder(order, sig);

        uint256 pointAmount = order.amount / pointPrice;

        bytes memory orderId = abi.encodePacked(order.hash());

        _issueNewPoint(order.buyer, pointAmount, 0, orderId);
    }

    function _issueNewPoint(address to, uint256 amount, uint256 method, bytes memory orderId) internal {
        idempotencyKeyMap[method][orderId] = true;

        point.mint(to, amount);

        emit PointBought(to, amount, method, orderId);
    }

    function _verifyBuyOrder(BuyPointOrder memory order, bytes memory sig) internal {
        if (address(this) != address(order.dispatcher)) {
            revert IOrderHandler.InvalidDispatcher();
        }

        if (block.timestamp > order.deadline) {
            revert IOrderHandler.DeadlinePassed();
        }

        permit2.permitWitnessTransferFrom(
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({token: address(stableToken), amount: order.amount}),
                nonce: order.nonce,
                deadline: order.deadline
            }),
            ISignatureTransfer.SignatureTransferDetails({to: feeRecipient, requestedAmount: order.amount}),
            order.buyer,
            order.hash(),
            BuyPointOrderLib.PERMIT2_ORDER_TYPE,
            sig
        );
    }
}
