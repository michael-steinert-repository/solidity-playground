pragma solidity >=0.7.0 <0.9.0;

contract Escrow {
    enum State {
        NOT_INITIATED,
        AWAITING_PAYMENT,
        AWITING_DELIVERY,
        COMPLETE
    }
    State public currentState;
    
    bool public isBuyerIn;
    bool public isSellerIn;
    
    uint public price;
    
    address public buyer;
    address payable public seller;
    
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only Buyer can call this Function");
        _;
    }
    
    modifier escrowNotStarted() {
        require(currentState == State.NOT_INITIATED);
        _;
    }
    
    constructor(address _buyer, address payable _seller, uint _price) {
        buyer = _buyer;
        seller = _seller;
        price = _price * (1 ether);
    }
    
    function initContract() escrowNotStarted public {
        if (msg.sender == buyer) {
            isBuyerIn = true;
        }
        
        if (msg.sender == seller) {
            isSellerIn = true;
        }
        
        if (isBuyerIn && isSellerIn) {
            currentState = State.AWAITING_PAYMENT;
        }
    }
    
    function deposit() onlyBuyer public payable {
        require(currentState == State.AWAITING_PAYMENT, "Already paid");
        require(msg.value == price, "Wrong Deposit Amount");
        currentState = State.AWITING_DELIVERY;
    }
    
    function confirmDelivery() onlyBuyer public payable {
        require(currentState == State.AWITING_DELIVERY, "Cannot confirm Delivery");
        seller.transfer(price);
        currentState = State.COMPLETE;
    }
    
    function withdraw() onlyBuyer public payable {
        require(currentState == State.AWITING_DELIVERY, "Cannot withdraw at this Stage");
        payable(msg.sender).transfer(price);
        currentState = State.COMPLETE;
    }
}