// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../src/Blind-Auction-Factory.sol";
import "../src/Blind-Auction.sol";
import "../src/W3BNFT.sol";
import "../src/IBlindAuction.sol";

contract BlindAuctionTest is Test {
    BlindAuctionFactory public factory;
    BlindAuction public auction;
    W3BNFT public nftContract;

    function setUp() public {
        factory = new BlindAuctionFactory();
        auction = new BlindAuction(3600, address(this));
        nftContract = new W3BNFT("Web 3 Bridge", "W3B");
        // uint tokenId = nftContract.totalSupply();
        nftContract.mint(1);
    }

    function test_AuctionFactory() public {
        address _test = factory.createBlindAuction(3600);
        console.log(_test);
    }

    function test_createAuction() public {
        // uint tokenId = nftContract.totalSupply();
        address sampleAuction = factory.createBlindAuction(3600);
        IERC721(nftContract).approve(sampleAuction, 1);
        IBlindAuction(sampleAuction).createAuction(address(nftContract), 1);
        IBlindAuction(sampleAuction).CommitBid(10, "moneyman");
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        IBlindAuction(sampleAuction).CommitBid(20, "moniman");
        vm.warp(block.timestamp + 3600 minutes);
        IBlindAuction(sampleAuction).RevealBid(10, "moneyman");
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        IBlindAuction(sampleAuction).RevealBid(20, "moniman");
    }

}
