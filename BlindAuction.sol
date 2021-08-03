pragma solidity >=0.7.0 <0.9.0;

contract BlindAuction {
	struct Bid {
		bytes32 blindedBid;
		uint deposit;
	}
	address payable public beneficiary;
	uint public biddingEnd;
	uint public revealEnd;
	bool public isEnded;
	address public highestBidder;
	uint public highestBid;
	/* Each Bidder can have more then one Bid */
	mapping(address => Bid[]) public bids;
	/* Allow Users to withdraw previous Bids */
	mapping(address => uint) pendingReturns;

	event AuctionEnded(address winner, uint highestBid);

    modifier onlyBeforeTime(uint _time) {
        require(block.timestamp < _time);
        _;
    }
    
    modifier onlyAfterTime(uint _time) {
        require(block.timestamp > _time);
        _;
    }

	constructor(uint _biddingTime, uint _revealTime, address payable _beneficiary) {
		beneficiary = _beneficiary;
		biddingEnd = block.timestamp + _biddingTime;
		revealEnd = biddingEnd + _revealTime;
	}

	/* Returns a Hash Byte32 of the Bid */
	function generateBlindedBidBytes32(uint value, bool isFake) public view returns (bytes32) {
        return keccak256(abi.encodePacked(value, isFake));
	}

	function bid(bytes32 _blindedBid) public payable onlyBeforeTime(biddingEnd) {
	    bids[msg.sender].push(Bid({
	        blindedBid: _blindedBid,
	        deposit: msg.value
	    }));
	}

	function reveal(uint[] memory _values, bool[] memory _isFake) public onlyAfterTime(biddingEnd) onlyBeforeTime(revealEnd) {
	    uint length = bids[msg.sender].length;
	    require(_values.length == length);
	    require(_isFake.length == length);
	    /* Bid that is smaller then the highest Bid */
	    //uint refund;
	    for (uint i = 0; i < length; i++) {
	        Bid storage bidToCheck = bids[msg.sender][i];
	        (uint value, bool isFake) = (_values[i], _isFake[i]);
	        /* Verifie the Hash */
	        if (bidToCheck.blindedBid != keccak256(abi.encodePacked(value, isFake))) {
	            /* Going to the next Iteration in the For-Loop */
	            continue;
	        }
	        //refund += bidToCheck.deposit;
	        if(!isFake && bidToCheck.deposit >= value) {
	            /*
	            if (placeBid(msg.sender, value)) {
	                refund -= value;
	            }
	            */
	            if (!placeBid(msg.sender, value)) {
	                /* Transferring Refund to Bidder */
	               payable(msg.sender).transfer(bidToCheck.deposit * (1 ether));
	            }
	        }
	        bidToCheck.blindedBid = bytes32(0);
	    }
	    //payable(msg.sender).transfer(refund);
	}

	function auctionEnd() public payable onlyAfterTime(revealEnd) {
		require(!isEnded);
		emit AuctionEnded(highestBidder, highestBid);
		isEnded = true;
		beneficiary.transfer(highestBid * (1 ether));
	}

	function withdraw() public {
		uint amount = pendingReturns[msg.sender];
		if (amount > 0) {
		    pendingReturns[msg.sender] = 0;
		    payable(msg.sender).transfer(amount * (1 ether));
		}
	}

	function placeBid(address bidder, uint value) internal returns(bool isSuccess) {
	    if (value <= highestBid) {
	        return false;
	    }
	    if (highestBidder != address(0x0)) {
	        pendingReturns[highestBidder] += highestBid;
	        highestBid = value;
	        highestBidder = bidder;
	        return true;
	    }
	}
}