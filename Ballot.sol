pragma solidity >=0.7.0 <0.9.0;

/* 
Porperties of a Voting System 
- Secret Ballot: there is no Way to find out the Voter by using the Ethereum Address
- An Address can only have one Vote
- The Ruleshave to be 
- The Rules  of the Voting System must be comprehensible to all Voters
*/

contract Ballot {
    struct Vote {
        address voterAddress;
        bool choice;
    }
    
    struct Voter {
        string voterName;
        bool hasVoted;
    }
    
    uint private countResult = 0;
    uint public finalResult = 0;
    uint public totalVoter = 0;
    uint public totalVote = 0;
    
    address ballotOfficialAddress;
    string public ballotOfficialName;
    string public proposal;
    
    mapping(uint => Vote) private votes;
    mapping(address => Voter) public voters;
    
    enum State {
        CREATED,
        VOTING,
        ENDED
    }
    State public state;
    
    modifier condicition(bool _condition) {
        require(_condition);
        _;
    }
    
    modifier onlyOfficial() {
        require(msg.sender == ballotOfficialAddress);
        _;
    }
    
    modifier inState(State _state) {
        require(state == _state);
        _;
    }
    
    constructor(string memory _ballotOfficialName, string memory _proposal) {
        ballotOfficialAddress = msg.sender;
        ballotOfficialName = _ballotOfficialName;
        proposal = _proposal;
        state = State.CREATED;
    }
    
    function addVoter(address _voterAddress, string memory _voterName) public inState(State.CREATED) onlyOfficial {
        Voter memory voter;
        voter.voterName = _voterName;
        voter.hasVoted = false;
        /* Adding Voter to Voter Registry(Mapping) */
        voters[_voterAddress] = voter;
        totalVoter++;
    }
    
    function startVote() public inState(State.CREATED) onlyOfficial {
        /* Now the Modifier condicition(State.VOTING) => require(1) is false so the Function addVoter() and startVote() are nto allowed */
        state = State.VOTING;
    }
    
    function doVote(bool _choice) public inState(State.VOTING) returns (bool hasVoted) {
        bool hasFoundAddress = false;
        /* Checking if Voter Name exists and Voter has not voted */
        if (bytes(voters[msg.sender].voterName).length > 0 && !voters[msg.sender].hasVoted) {
            voters[msg.sender].hasVoted = true;
            Vote memory voter;
            voter.voterAddress = msg.sender;
            voter.choice = _choice;
            /* Counting the Choices of the Voters that are true */
            if(_choice) {
                countResult++;
            }
            votes[totalVote] = voter;
            totalVote++;
            hasFoundAddress = true;
        }
        return hasFoundAddress;
    }
    
    function endVote() public inState(State.VOTING) onlyOfficial {
        state = State.ENDED;
        finalResult = countResult;
    }
}