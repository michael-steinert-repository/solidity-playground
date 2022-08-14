// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// Custom Error cost less Gas to store on Blochcain than Strings from Function `require()`
error Raffle__NotEnoughEthToEnterRaffle();
error Raffle_RaffleNotOpen();
error Raffle__UpkeepNotNeeded();
error Raffle_TransferFailed();

contract Raffle is VRFConsumerBaseV2 {
    enum RaffleState {
        Open,
        Chossing_Winner
    }

    // `storage` Variable are expensive in Gas to work with
    RaffleState public s_raffleState;
    address payable[] public s_players;
    uint256 public s_lastTimeStamp;
    address public s_currentWinner;

    // `immutable` Variables can only be initialized once in the Constructor therefore they are unchangable
    // `immutable` Variables are Gas-cheaper than normal Variables
    uint256 public immutable i_entranceFee;
    uint256 public immutable i_interval;
    VRFCoordinatorV2Interface public immutable i_vrfCoordinator;
    bytes32 public immutable i_keyHash;
    uint64 public immutable i_subsprictionId;
    uint32 public immutable i_callbackGasLimit;

    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant NUM_WORDS = 1;

    event PlayerEnteredRafle(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed currentWinner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinatorV2,
        // How much Gas can be spent to call a random Number
        bytes32 keyHash,
        uint64 subsprictionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_keyHash = keyHash;
        i_subsprictionId = subsprictionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterRaffle() external payable {
        // Function `require()` cost more Gas than Custom Exceptions
        // require(msg.value >= i_entranceFee, "Not enough ETH to enter Raffle");
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthToEnterRaffle();
        }
        // Raffle is not open
        if (s_raffleState != RaffleState.Open) {
            revert Raffle_RaffleNotOpen();
        }
        // Add Player to Raffle
        s_players.push(payable(msg.sender));
        // Emit Event
        emit PlayerEnteredRafle(msg.sender);
    }

    // Check Raffle if Interval has passed to trigger a new Winner
    function checkUpkeep(bytes memory)
        public
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // Check that Raffle is open
        bool isRaffleOpen = RaffleState.Open == s_raffleState;
        // Check that Raffle has passed Interval
        bool isTimePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        // Check that Raffle has Players
        bool hasRafflePlayers = s_players.length > 0;
        // Check that Raffle has Balance
        bool hasRaffleBalance = address(this).balance > 0;

        upkeepNeeded = (isRaffleOpen &&
            isTimePassed &&
            hasRafflePlayers &&
            hasRaffleBalance);

        return (upkeepNeeded, "0x0");
    }

    // Function `performUpkeep` is treiggered when Function `checkUpkeep` returns true
    // Chose a new Winner
    function performUpkeep(bytes calldata) external {
        // Check if Interval has passed to chose a new Winner
        (bool upkeepNeeded, ) = checkUpkeep("");
        // Check if `upkeepNeeded` when not then not execute Function
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded();
        }
        // Set Raffle to choosing Winner, so no more Player can join it
        s_raffleState = RaffleState.Chossing_Winner;
        // Request a random Number
        // Assumes the Chainlink Subscription is funded sufficiently
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subsprictionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    // VRF Coordinator Contract will call Function `fullfillRandomWords`
    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        internal
        override
    {
        // Chose Winer
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable currentWinner = s_players[indexOfWinner];
        s_currentWinner = currentWinner;
        // Reset Raffle State
        s_players = new address payable[](0);
        s_raffleState = RaffleState.Open;
        s_lastTimeStamp = block.timestamp;
        // Pay Winer by using Function `call` instead of Function `transfer`
        // Function `call` can call every Function on a Contract / Address and passing the Value as an Object
        // Function `call` is calling no Function / the Callback Function `("")`
        (bool success, ) = currentWinner.call{value: address(this).balance}("");
        // If Transfer failed
        if (!success) {
            revert Raffle_TransferFailed();
        }
        emit WinnerPicked(currentWinner);
    }
}
