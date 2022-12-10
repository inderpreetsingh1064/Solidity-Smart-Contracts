// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.8;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Bidding is AccessControl, Pausable {
    uint minBidAmount = 10;
    uint public auctionEndTime;
    uint public auctionStartTime;
    address payable public beneficiary;
    IERC20 public paymentToken;
    IERC721 public nft;

    event AddMember(bytes32 indexed role, address account);
    event RemoveMember(bytes32 indexed role, address account);
    event BidAdded(address indexed account, address paymentToken, uint amount);
    event BidRefunded(address indexed account, address paymentToken, uint amount);
    event Withdraw(address indexed by, address beneficiary, uint amount);
    event PrizeDeposited(address indexed account, address indexed nftAddress, uint indexed tokenId);
    event AuctionProcessed(address indexed winner, address indexed nftAddress, uint indexed tokenId);

    constructor(address payable _beneficiary, address _paymentToken, uint startTime, uint endTime) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        require(_beneficiary != address(0), "Zero address is not allowed");
        beneficiary = _beneficiary;
        require(_paymentToken != address(0), "Zero address is not allowed");
        paymentToken = IERC20(_paymentToken);
        require(startTime > block.timestamp, "start time should be future");
        require(startTime < endTime, "Invalid auction duration");
        auctionStartTime = startTime;
        auctionEndTime = endTime;
    }

    modifier onlyOnRunningAuction() {
        require(block.timestamp >= auctionStartTime && block.timestamp <= auctionEndTime, "Auction is not running");
        _;
    }

    modifier onlyAfterAuctionEnded() {
        require(block.timestamp > auctionEndTime, "Auction is still running");
        _;
    }

    modifier onlyAfterPrizeDeposited() {
        require(isPrizeDeposited == true, "Prize is not deposited yet");
        _;
    }

    bytes32 public constant MAINTAINER = keccak256("MAINTAINER");

    mapping(address => Bid) public biddings;

    bool public auctionProcessed = false;
    bool public isPrizeDeposited = false;

    struct Bid {
        address bidder;
        uint amount;
        uint timestamp;
    }

    address payable public highestBidder;
    uint public highestBid;
    uint private _tokenId;

    function depositPrize(address _nftAddress, uint tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(isPrizeDeposited == false, "Prize is already deposited");
        require(_nftAddress != address(0), "Zero address is not allowed");
        nft = IERC721(_nftAddress);
        _tokenId = tokenId;
        isPrizeDeposited = true;
        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        emit PrizeDeposited(msg.sender, address(nft), tokenId);
    }

    function addMember(bytes32 role, address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
        emit AddMember(role, account);
    }

    function removeMember(bytes32 role, address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
        emit RemoveMember(role, account);
    }

    function pause() external onlyRole(MAINTAINER) {
        _pause();
    }

    function unpause() external onlyRole(MAINTAINER) {
        _unpause();
    }

    function bid(uint amount) external onlyOnRunningAuction onlyAfterPrizeDeposited {
        require(tx.origin == msg.sender, "Contract not allowed to bid");
        require(amount > highestBid + minBidAmount, "Bid must be higher than highest bidder");
        require(paymentToken.allowance(msg.sender, address(this)) >= amount, "Bidding contract is not approved to spend amount");

        Bid memory newBid = Bid({
            bidder: msg.sender,
            amount: amount,
            timestamp: block.timestamp
        });

        biddings[msg.sender] = newBid;

        if (highestBid != 0) {
            // delete biddings[highestBidder];
            paymentToken.transferFrom(address(this), highestBidder, amount);
            emit BidRefunded(highestBidder, address(paymentToken), amount);
        }

        paymentToken.transferFrom(msg.sender, address(this), amount);

        highestBidder = payable(msg.sender);
        highestBid = amount;
        emit BidAdded(msg.sender, address(paymentToken), amount);
    }

    function processAuction() external onlyAfterAuctionEnded onlyAfterPrizeDeposited onlyRole(DEFAULT_ADMIN_ROLE) {
        require(auctionProcessed == false, "Auction has already been processed");
        address winner = (highestBidder == address(0)) ? address(beneficiary) : address(highestBidder);
        nft.approve(winner, _tokenId);
        nft.safeTransferFrom(address(this), winner, _tokenId);
        auctionProcessed = true;
        emit AuctionProcessed(winner, address(nft), _tokenId);
    }

    function withdraw(uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount <= paymentToken.balanceOf(address(this)), "Insufficient balance");
        paymentToken.transferFrom(address(this), beneficiary, amount); 
        emit Withdraw(msg.sender, beneficiary, amount);
    }
}