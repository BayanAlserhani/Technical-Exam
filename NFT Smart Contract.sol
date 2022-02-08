// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//1. An Auction Dealer smart contract.//

// the following interface is used to verify that the contract passed to this auction does represent an NFT.
// meaning that we want to treat the contract as an ERC721 type contract which has a transfer and a transfer from functions.
interface ERC721 {
    function transfer(address, uint) external; // takes the NFT Id and transfer it to an address.

    function transferFrom(
        address, // transfer NFT from this address.
        address, // transfer NFT to this address.
        uint // the NFT Id to transfer.
    ) external;
}

contract AuctionDealer {

    event Start(); // to be able to take a look at data in the details of the contract once it deployed.
    event End(address highestBidder, uint highestBid); // to be able to know who won the auction and what was the highest bid amount.
    event Bid(address sender, uint amount); // to be able to know the bid sender and the bid amount.
    event Withdraw(address bidder, uint amount); // to be able to know the address of the bidder who want to withdraw and the amount of the withdraw.
  
    address payable public seller; // the owner of the NFT.
    bool public started; // checks if the auction has started or not.
    bool public ended; // checks if the auction has ended or not.
    uint public endAt; // specifies how much time is left for the auction to end.
    uint public highestBid; // specifies the amount of the highest bid.
    address public highestBidder; // the address of the winner.
    mapping(address => uint) public bids; // to keep track of all bids in this contract.

    ERC721 public nft; // stores the contract of the NFT address as a type of ERC721.
    uint public nftId; // the unique Id of the NFT.

    constructor () {
        seller = payable(msg.sender); // assigning the seller "whoever deployed the contract will be the seller".
    }
  // the following function will allow only the seller of the NFT to start the auction.
    function start(ERC721 _nft, uint _nftId,uint startBid) external {
        require(!started, "Auction already started!"); // we can not start the contract if it already started.
        require(msg.sender == seller, "You did not start the auction!"); // to make sure the address of whoever started the contract matches the address of the seller.
        started = true; // to start the auction.
        highestBid = startBid; // bidders have to bid a higher bid than the starting bid to win.
        
        nft = _nft; // _nft equals to nft.
        nftId = _nftId; // _nftId equals to nftId.

        nft.transferFrom(msg.sender, address(this), nftId); // transfers the NFT from the address of the seller to the address of the winner.

        endAt = block.timestamp + 4 days; // the auction will start from the time the block was ctreated and last for 4 days.
        emit Start(); // emitting the event.
    }
// the following function will allow contributors to bid.
    function bid() external payable {
        require(started, "Auction is not started yet"); // to make sure the auction has started.
        require(block.timestamp < endAt, "Sorry, auction is already ended!"); // to make sure auction is still ongoing.
        require(msg.value > highestBid); // to make sure the amount of the bid is higher than the current highest bid.

        // the following if statement is going to allow bidders who got out bid to withdraw their bids in order to bid again. 
        if (highestBidder != address(0)) { // address(0) is a zero filled address which is the default address.
            bids[highestBidder] += highestBid; // incrementing the original bids of bidders who want to continue bidding.
        }

        highestBid = msg.value; // to update the amount of the highest bid.
        highestBidder = msg.sender; // to update the address of the highest bidder.

        emit Bid(highestBidder, highestBid); // emitting the event above.
    }

    function withdraw() external payable {
        uint balance = bids[msg.sender]; // store the address in balance as a uint variable.  
        bids[msg.sender] = 0; // reset the address.
        bool sent;
        msg.sender.call{value: balance}; // to send the amount in balance to bidders who want to withdraw.
                                        // or maybe we could use "payable(msg.sender).transfer(balance);".        
        emit Withdraw(msg.sender, balance); // emitting the event above.
    
    }
// the following function will allow the auction to end.
    function end() external {
        require(started, "You need to start the auction in order to end it!"); // we can not end the auction unless we started it first.
        require(block.timestamp >= endAt, "Auction has not ended yet!"); // to not allow someone to end the auction if the end at time is not yet reached.
        require(!ended, "Auction already ended!"); // to make sure the auction is still ongoing.

        // the following if statment transfers the NFT to the winner.
        if(highestBidder != address(0)) {  // to make sure that at least someone bid on this item.
            nft.transfer(highestBidder, nftId); // transfers the NFT to the highest bidder.

            // figuring out what was the highest bid and transfering it to the seller.
            bool sent;
            seller.call{value: highestBid};
            require(sent, "could not pay the seller");
        } 
        else {
            nft.transfer(seller, nftId); // if no one bid then return the NFT to the seller.
        }


        ended = true; // to end the auction.
        emit End(highestBidder, highestBid); // when the auction ends, we want to know these information.
  
    }   


}

//2. The definition for an Auction smart contract.//

// First let's define an Auction contract, it is an agreement between a seller and a buyer where
// the seller agrees to sell a property for the highest bid and the buyer agrees to pay the bid
// all of which are enforced by laws.(centralized).
// Now let's define an Auction smart contract, it is an agreement between a seller and a buyer where
// the seller agrees to sell a property for the highest bid and the buyer agrees to pay the bid
// all of which are enforced by computer codes.(decentralized).
// in other words we can say that Auction smart contract is a decentralized auction blockchain based contract 
// which enforce an agreement between two parties without involving a third one.


//3. An ERC 721 based smart contract to create and award NFTs to the address of the winner.//


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract BayanToken is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private nftId;

    constructor() ERC721("BayanToken", "BTK") {}

    function awardItem (highestBidder , string memory tokenURI) public returns (uint256)

    {
        nftId.increment();

        uint256 newItemId = nftId.current();
        _mint(highestBidder, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;

    }    
}
