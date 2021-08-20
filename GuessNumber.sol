// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract GuessNumber {
    uint secretNumber;
    enum State {
        ACTIVE,
        COMPLETE
    }
    State public currentState;
    uint balance;
    
    constructor(uint _secretNumber) payable {
        require(msg.value >= 10 * (10**18), "At least 10 ETH needs to be funded");
        secretNumber = _secretNumber;
        balance = msg.value;
    }
    
    function getBalance() public view returns (uint) {
        return balance;
    }
    
    function guessNumber(address payable _guesser, uint _numberGuess) external payable returns (uint) {
        require(msg.value >= 1 * (10**18), "At least 1 ETH needs to be payed");
        require(currentState == State.ACTIVE, "Guess Number is completed");
        balance = balance + msg.value;
        if (_numberGuess == secretNumber) {
            /* Transferring all Amount of Smart Contract to the right Guesser */
            _guesser.transfer(address(this).balance);
            currentState = State.COMPLETE;
            return balance;
        } else {
            return balance;
        }
    }
}