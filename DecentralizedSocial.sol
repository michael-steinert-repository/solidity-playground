// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// Deployed on BSC Testnet: 0x97F5Ab844C0eAfa22eEF85480Bf9f5BfD70deaE7
contract DecentralizedSocial {

    event PostCreated (bytes32 indexed postId, address indexed postOwner, bytes32 indexed parentId, bytes32 contentId, bytes32 categoryId);
    event ContentAdded (bytes32 indexed contentId, string contentUri);
    event CategoryCreated (bytes32 indexed categoryId, string category);
    event Voted (bytes32 indexed postId, address indexed postOwner, address indexed voter, uint80 reputationPostOwner, uint80 reputationVoter, int40 postVotes, bool up, uint8 reputationAmount);

    struct post {
        address postOwner;
        bytes32 parentPost;
        bytes32 contentId;
        int40 votes;
        bytes32 categoryId;
    }

    // Each User (address) has a Reputation (uint80) for each Category (bytes32)
    mapping(address => mapping(bytes32 => uint80)) reputationRegistry;
    mapping(bytes32 => string) categoryRegistry;
    mapping(bytes32 => string) contentRegistry;
    mapping(bytes32 => post) postRegistry;
    // Each User (address) has a Voted-Flag (bool) for each Post (byte32)
    mapping(address => mapping(bytes32 => bool)) voteRegistry;

    function createPost(bytes32 _parentId, string calldata _contentUri, bytes32 _categoryId) external {
        address _owner = msg.sender;
        bytes32 _contentId = keccak256(abi.encode(_contentUri));
        bytes32 _postId = keccak256(abi.encodePacked(_owner, _parentId, _contentId));
        contentRegistry[_contentId] = _contentUri;
        postRegistry[_postId].postOwner = _owner;
        postRegistry[_postId].parentPost = _parentId;
        postRegistry[_postId].contentId = _contentId;
        postRegistry[_postId].categoryId = _categoryId;
        emit ContentAdded(_contentId, _contentUri);
        emit PostCreated(_postId, _owner, _parentId, _contentId, _categoryId);
    }

    function voteUp(bytes32 _postId, uint8 _reputationAdded) external {
        address _voter = msg.sender;
        bytes32 _category = postRegistry[_postId].categoryId;
        address _contributor = postRegistry[_postId].postOwner;
        require(postRegistry[_postId].postOwner != _voter, "Not possible to vote on own Posts");
        require(voteRegistry[_voter][_postId] == false, "Sender already voted in this Post");
        require(validateReputationChange(_voter, _category, _reputationAdded) == true, "This Address cannot add this Amount of Reputation Points");
        postRegistry[_postId].votes += 1;
        reputationRegistry[_contributor][_category] += _reputationAdded;
        // If true the User can not vote a second Time in the Future
        voteRegistry[_voter][_postId] = true;
        emit Voted(_postId, _contributor, _voter, reputationRegistry[_contributor][_category], reputationRegistry[_voter][_category], postRegistry[_postId].votes, true, _reputationAdded);
    }

    function voteDown(bytes32 _postId, uint8 _reputationTaken) external {
        address _voter = msg.sender;
        bytes32 _category = postRegistry[_postId].categoryId;
        address _contributor = postRegistry[_postId].postOwner;
        require(voteRegistry[_voter][_postId] == false, "Sender already voted in this Post");
        require(validateReputationChange(_voter, _category, _reputationTaken) == true, "This Address cannot take this Amount of Reputation Points");
        // If Votes are already 0 then do not change it (no negative Votes)
        (postRegistry[_postId].votes >= 1) ? (postRegistry[_postId].votes -= 1) : (postRegistry[_postId].votes = 0);
        reputationRegistry[_contributor][_category] >= _reputationTaken ? reputationRegistry[_contributor][_category] -= _reputationTaken : reputationRegistry[_contributor][_category] = 0;
        // If true the User can not vote a second Time in the Future
        voteRegistry[_voter][_postId] = true;
        emit Voted(_postId, _contributor, _voter, reputationRegistry[_contributor][_category], reputationRegistry[_voter][_category], postRegistry[_postId].votes, false, _reputationTaken);
    }

    function validateReputationChange(address _sender, bytes32 _categoryId, uint8 _reputationAdded) internal view returns (bool _result){
        uint80 _reputation = reputationRegistry[_sender][_categoryId];
        if (_reputation < 2) {
            // If Voter has a Reputation of less then 2, he only can vote with one Vote
            (_reputationAdded == 1) ? (_result = true) : (_result = false);
        }
        else {
            // If Voter has a Reputation greater then 2, he only can vote with Logarithmic Arithmetic times Vote
            // For Example: User has 16 Reputations he can vote with 4 Votes
            (2 ** _reputationAdded <= _reputation) ? (_result = true) : (_result = false);
        }
    }

    function addCategory(string calldata _category) external {
        bytes32 _categoryId = keccak256(abi.encode(_category));
        categoryRegistry[_categoryId] = _category;
        emit CategoryCreated(_categoryId, _category);
    }

    function getContent(bytes32 _contentId) public view returns (string memory) {
        return contentRegistry[_contentId];
    }

    function getCategory(bytes32 _categoryId) public view returns (string memory) {
        return categoryRegistry[_categoryId];
    }

    function getReputation(address _address, bytes32 _categoryID) public view returns (uint80) {
        return reputationRegistry[_address][_categoryID];
    }

    function getPost(bytes32 _postId) public view returns (address, bytes32, bytes32, int72, bytes32) {
        return (postRegistry[_postId].postOwner, postRegistry[_postId].parentPost, postRegistry[_postId].contentId, postRegistry[_postId].votes, postRegistry[_postId].categoryId);
    }
}
