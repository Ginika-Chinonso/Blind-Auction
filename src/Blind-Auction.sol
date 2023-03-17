// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract BlindAuction {

    uint256 public AuctionStart;
    uint256 public AuctionDuration;
    uint256 public AuctionEnd;
    address public Owner;
    address public Admin;
    address public winner;
    bool public AuctionCancelled;

    mapping(address => Bid) public Bids;

    address[] public Bidders;

    struct Bid {
        bytes32 CommitHash;
        uint256 Amount;
        uint timeofBid;
    }

    struct AuctionedItem {
        address nftAddress;
        uint256 tokenId;
        address owner;
    }

    AuctionedItem public ItemtobeAuctioned;

    event AuctionStarted(uint256 _starttime, address _owner);

    constructor(uint256 _AuctionDuration, address _Admin){
        AuctionDuration = _AuctionDuration;
        Owner = tx.origin;
        Admin = _Admin;
    }

    function CommitBid(uint _amount, bytes32 _salt) public {
        require(block.timestamp < AuctionEnd, "Auction has ended");
        uint256 _amountinEther = _amount * 1 ether;
        bytes32 _commitedHash = keccak256(abi.encodePacked(_amountinEther, _salt));
        Bids[msg.sender].CommitHash = _commitedHash;
        Bids[msg.sender].timeofBid = block.timestamp;
        Bidders.push(msg.sender);
    }


    function RevealBid(uint _amount, bytes32 _salt) public {
        require(block.timestamp > AuctionEnd, "Auction is still ongoing");
        uint256 _amountinEther = _amount * 1 ether;
        bytes32 _commitedHash = keccak256(abi.encodePacked(_amountinEther, _salt));
        require(_commitedHash == Bids[msg.sender].CommitHash, "Invalid amount or salt");
        Bids[msg.sender].Amount = _amount;
    }

    function createAuction(address _nftContract,uint _tokenId) public {
        // require (msg.sender == Owner, "Only owner can start auction");
        require(IERC721(_nftContract).ownerOf(_tokenId) == msg.sender, "Only the owner of an NFT can auction it");
        ItemtobeAuctioned = AuctionedItem(_nftContract, _tokenId, msg.sender);
        AuctionStart = block.timestamp;
        AuctionEnd = AuctionStart + AuctionDuration;
        IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);
        emit AuctionStarted(block.timestamp, Owner);
    }

    function getWinner() public returns (address _winner) {
        require(msg.sender == Admin, "Only Admin can call this function");
        _winner;
        // address[] memory _winners = new address[](Bidders.length);
        address[] memory _winners = new address[](2);
        _winners[0] = address(0);
        for (uint i; i < Bidders.length; i++){
            if (Bids[Bidders[i]].Amount == Bids[_winners[0]].Amount){
                _winners[1] = Bidders[i];
            } 
            if (Bids[Bidders[i]].Amount > Bids[_winners[0]].Amount){
                // _winners = new address[](Bidders.length - i);
                _winners = new address[](2);
                _winners[0] = Bidders[i];
            } 
        }
        if (_winners[1] != address(0)){
            revert("We have a tie");
        }
        if (_winners.length == 1){
            winner = _winners[0];
        }
        if (_winner == address(0)){
            cancelAuction();
        }
    }


    function claimItem() public payable {
        require(block.timestamp > AuctionEnd, "Auction still ongoing");
        require(msg.sender == winner, "Only winner can claim NFT");
        require(msg.value == Bids[msg.sender].Amount, "Send the amount you used to bid");
        IERC721(ItemtobeAuctioned.nftAddress).transferFrom(address(this), winner, ItemtobeAuctioned.tokenId);
    }

    function withdrawFunds() public {
        require(msg.sender == ItemtobeAuctioned.owner, "Only Item owner can withdraw funds");
        (bool success,) = payable(ItemtobeAuctioned.owner).call{value: Bids[winner].Amount}("");
        require(success, "Failed to send funds");
    }

    function cancelAuction() public {
        require(msg.sender == Admin, "Only Admin can cancel an auction");
        AuctionCancelled = true;
        IERC721(ItemtobeAuctioned.nftAddress).transferFrom(address(this), ItemtobeAuctioned.owner, ItemtobeAuctioned.tokenId);
    }

    function reclaimFunds() public payable {
        require(block.timestamp > AuctionEnd);
        require(AuctionCancelled, "Auction was not cancelled");
        uint bid = Bids[msg.sender].Amount;
        Bids[msg.sender].Amount = 0;
        (bool success,) = payable(address(msg.sender)).call{value: bid}("");
        require(success, "Failed to send funds");
    }

    fallback() external payable {}

    receive() external payable {}
}