// SPDX-License-Identifier: GPL-3.0

pragma solidity  ^0.8.0;

contract Auction{

    address payable public auctioneer;
    uint public stblock; //start time
    uint public etblock; //end time

    enum Auc_state {Started, Running, Ended , Cancelled}

    Auc_state public auctionState;

    uint public highestBit;
    uint public highestPayableBit;
    uint public bidInc;

    address payable public highestBidder;

    mapping (address => uint) public bids;

    constructor(){
       auctioneer = payable(msg.sender);
       auctionState = Auc_state.Running;
       stblock = block.number;
       etblock= stblock + 240;
       bidInc = 1 ether;
    }

    modifier notOwner(){
        require(msg.sender != auctioneer,"Owner can not bid");
        _;
    }

     modifier Owner(){
        require(msg.sender == auctioneer,"Owner can not bid");
        _;
    }

     modifier started(){
        require(block.number>stblock);
        _;
    }

     modifier beforeEnding(){
        require(block.number<etblock);
        _;
    }

    function cancelAuc() public Owner{
        auctionState =Auc_state.Cancelled;
    }

    function endAuc() public Owner{
        auctionState =Auc_state.Ended;
    }

    function min(uint a , uint b) private pure returns (uint){
        if(a<=b)
        return a;
        else 
        return b;
    }
    function bid() public payable notOwner started beforeEnding{

        require(auctionState == Auc_state.Running);
        require(msg.value>=1 ether);

        uint currentBid = bids[msg.sender] + msg.value;

        require(currentBid > highestPayableBit);

        bids[msg.sender] = currentBid;

        if(currentBid < bids[highestBidder]){
            highestPayableBit = min(currentBid+bidInc ,bids[highestBidder]);
        }else{
            highestPayableBit = min(currentBid , bids[highestBidder]+bidInc);
            highestBidder = payable(msg.sender);
        }

    }

    function finalizeAuc() public {
        require(auctionState==Auc_state.Cancelled || block.number>etblock);
        require(msg.sender == auctioneer || auctionState == Auc_state.Ended || bids[msg.sender]>0);

        address payable person;
        uint value;

        if(auctionState == Auc_state.Cancelled){
            person = payable(msg.sender);
            value = bids[msg.sender];
        }else{
            if(msg.sender == auctioneer){
                person = auctioneer;
                value = bids[highestBidder]-highestPayableBit;
                
            }else {
               if(msg.sender == highestBidder){
                person = highestBidder;
                value = bids[highestBidder] - highestPayableBit;
               }else{
                person = payable(msg.sender);
                value = bids[msg.sender];
               }
            }
        }
        bids[msg.sender]=0;
        person.transfer(value);
    }

}
