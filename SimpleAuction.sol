pragma solidity >=0.7.0 <0.9.0;

contract SimpleAuction {
    /* Keyword "payable" make it possible to send some Ether to these Address */
    address payable public beneficiary;
    uint public auctionEndTime;
    address public highestBidder;
    uint public highestBid;
    
    mapping(address => uint) public pendingReturns;
    
    bool isEnded = false;
    
    event HighestBidIncreased(address bidder, uint amount);
    
    event AuctionEnded(address winner, uint amount);

    constructor(uint _biddingTime, address payable _beneficiary) {
        beneficiary = _beneficiary;
        auctionEndTime = block.timestamp + _biddingTime;
    }
    
    function bid() public payable {
        /* Checking if Auction is still going */
        if (block.timestamp > auctionEndTime) {
            revert("The Auction has already ended");
        }
        
        if (msg.value <= highestBid) {
            revert("There is already a higher ro equal Bid");
        }
        
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }
    
    function withdraw() public returns(bool) {
        /* Getting Amount of Bidder */
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            /* Setting Amount of Bidder to 0 */
            pendingReturns[msg.sender] = 0;
            /* Returning Amount to Bidder */
            /* Method send() returns a "False" if it false */
            if(!payable(msg.sender).send(amount)) {
                /* Setting Amount back if Transaktion (send) not work */
                pendingReturns[msg.sender] = amount;
                return false;
            }
            return true;
        }
    }
    
    function auctionEnd() public {
        if (block.timestamp < auctionEndTime) {
            revert("The Auction has not ended yet");
        }
        
        if (isEnded) {
            revert("The Auction ahs already been closed");
        }
        
        isEnded = true;
        emit AuctionEnded(highestBidder, highestBid);
        
        /* Sending the Prize to the Winner */
        /* Method transfer() returns anything if it not work - Method send() returns is this Case "False" and throw a Revert */
        beneficiary.transfer(highestBid);
    }
}