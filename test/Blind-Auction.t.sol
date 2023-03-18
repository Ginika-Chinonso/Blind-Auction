// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../src/Blind-Auction-Factory.sol";
import "../src/Blind-Auction.sol";
import "../src/W3BNFT.sol";
import "../src/IW3BNFT.sol";
import "../src/IBlindAuction.sol";

contract BlindAuctionTest is Test {
    BlindAuctionFactory public factory;
    BlindAuction public auction;
    W3BNFT public nftContract;

    function setUp() public {
        factory = new BlindAuctionFactory();
        auction = new BlindAuction(3600, address(this));
        nftContract = new W3BNFT("Web 3 Bridge", "W3B");
        nftContract.mint(1);
    }

    function test_AuctionFactory() public {
        factory.createBlindAuction(3600 minutes);
    }


    function test_createAuction() public {
        address sampleAuction = factory.createBlindAuction(3600 minutes);
        IERC721(nftContract).approve(sampleAuction, 1);
        IBlindAuction(sampleAuction).createAuction(address(nftContract), 1);
    }


    function test_cancelAuction() public{
        address sampleAuction = factory.createBlindAuction(3600);
        IERC721(nftContract).approve(sampleAuction, 1);
        IBlindAuction(sampleAuction).createAuction(address(nftContract), 1);
        IBlindAuction(sampleAuction).cancelAuction();
    }


    function testFail_commitAfterCancelAuctionBeforeAuctionEnd() public{
        address sampleAuction = factory.createBlindAuction(3600);
        IERC721(nftContract).approve(sampleAuction, 1);
        IBlindAuction(sampleAuction).createAuction(address(nftContract), 1);
        IBlindAuction(sampleAuction).cancelAuction();
        IBlindAuction(sampleAuction).CommitBid(20, "money");
    }


    function test_CancelIfNoBidorAddressZeroWinner() public{
        address sampleAuction = factory.createBlindAuction(3600);
        IERC721(nftContract).approve(sampleAuction, 1);
        IBlindAuction(sampleAuction).createAuction(address(nftContract), 1);
        vm.warp(block.timestamp + 3600 minutes);
        IBlindAuction(sampleAuction).getWinner();
    }


    function testFail_withdrawAfterCancelAuctionAfterAuctionEnd() public{
        address sampleAuction = factory.createBlindAuction(3600);
        IERC721(nftContract).approve(sampleAuction, 1);
        IBlindAuction(sampleAuction).createAuction(address(nftContract), 1);
        IBlindAuction(sampleAuction).CommitBid(20, "money");
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        IBlindAuction(sampleAuction).CommitBid(10, "moni");
        vm.warp(block.timestamp + 3600 minutes);
        IBlindAuction(sampleAuction).RevealBid(20, "money");
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        IBlindAuction(sampleAuction).RevealBid(10, "moni");
        IBlindAuction(sampleAuction).getWinner();
        IBlindAuction(sampleAuction).cancelAuction();
        IBlindAuction(sampleAuction).withdrawFunds();
    }



     function test_FullAuction() public {
        address sampleAuction = factory.createBlindAuction(3600);
        IERC721(nftContract).approve(sampleAuction, 1);
        IBlindAuction(sampleAuction).createAuction(address(nftContract), 1);
        IBlindAuction(sampleAuction).CommitBid(10 ether, "moneyman");
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        IBlindAuction(sampleAuction).CommitBid(20 ether, "moniman");
        vm.warp(block.timestamp + 3600 minutes);
        IBlindAuction(sampleAuction).RevealBid(10 ether, "moneyman");
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        IBlindAuction(sampleAuction).RevealBid(20 ether, "moniman");
        IBlindAuction(sampleAuction).getWinner();
        vm.deal(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 10000 ether);
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        IBlindAuction(sampleAuction).claimItem{value: 20 ether}();
        IBlindAuction(sampleAuction).withdrawFunds();
    }

}
