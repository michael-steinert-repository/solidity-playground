// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;

/* Interfaces are compiled down to an ABI */
/* ABIs tell the Contract how it can interact with another Contract */
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

/* Libraries are similar to Contracts, but their are deployed only once at a specific Address and their Code is reused */
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    /* Safe Math Check Link is attached to all Integer of Type uint256 in the Context of these Contract */
    /* Solidity 0.8 and greater checks for Overflows */
    using SafeMathChainlink for uint256;

    /* Mapping to store which Address deposited how much Ether */
    mapping(address => uint256) public addressToAmountFunded;
    /* Array of Addresses who deposited into the Contract */
    address[] public funders;
    /* Address of the Owner (who deployed the Contract) */
    address public owner;

    /* The first Person to deploy the Contract is the Owner */
    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        /* 18 Digit Number to be compared with donated Amount - 50$ */
        uint256 minimumUSD = 50 * 10 ** 18;
        require(getConversionRate(msg.value) >= minimumUSD, "More Ether is needed");
        /* Adding Donation to Mapping and Funders Array */
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    /* Getting  the Version of the Chainlink Pricefeed */
    function getVersion() public view returns (uint256){
        /* Address is the Location of the Price Feed on the Kovan Network */
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (
        /* `roundId` defines how many Times the Price Feed was updated */
        uint80 roundID,
        /* `price` contains the Conversion Rate of the Asset */
        int price,
        /* `startedAt` defines when the Price Feed was latest updated */
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        /* ETH/USD Conversion Rate in 18 Digit and type-casted */
        return uint256(price * 10000000000);
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        /* Actual ETH/USD Conversation Rate, after adjusting the extra Zeros */
        return ethAmountInUsd;
    }

    /* Modifier are used to change the Behavior of a Function in an declarative Way */
    modifier onlyOwner {
        /* Checking that the `message.sender` is Owner of these Contract */
        require(msg.sender == owner);
        /* After Checking running the rest of Code */
        _;
    }

    /* Modifier `onlyOwner` will first check the Condition inside it and if true, Function `withdraw` will be executed `_` */
    function withdraw() payable onlyOwner public {
        /* Chainlink Aggregator Interface Version v0.8 needs to be payable: payable(msg.sender).transfer(address(this).balance); */
        /* Transfer all Ether to `msg.sender` from these Contract `address(this)` */
        msg.sender.transfer(address(this).balance);

        /* Iterating through all the Mappings and making them to Zero since all the deposited Amount has been withdrawn */
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        /* Funders Array will be initialized to Zero */
        funders = new address[](0);
    }
}
