// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Token {
    /* Keyword cause the Wallet have to read the Variable */
    string public name = "My Token";
    string public symbol = "MTK";
    /* Decimal Representation: 1.000 000 000 000 000 000 */
    uint256 public decimals = 18;
    /* Total Tokens: 42 */
    uint256 public totalSupply = 42 * (10**18);

    // Keep track Balances and Allowances approved
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Events - fire Events on State Changes
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply; 
        balanceOf[msg.sender] = totalSupply;
    }

    /// @notice transfer Amount of Tokens to an Address
    /// @param _to Receiver of Token
    /// @param _value Amount Value of Token to send
    /// @return success as true, for Transfer 
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /// @dev internal Helper transfer Function with required Safety Checks
    /// @param _from, where Funds coming the Sender
    /// @param _to Receiver of Token
    /// @param _value Amount Value of Token to send
    //  Internal Function transfer can only be called by this Contract
    //  Emit Transfer Event event 
    function _transfer(address _from, address _to, uint256 _value) internal {
        // Ensure sending is to valid address! 0x0 address cane be used to burn() 
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }

    /// @notice Approve other to spend on your Behalf eg an Exchange 
    /// @param _spender allowed to spend and a max Amount allowed to spend
    /// @param _value Amount Value of Token to send
    /// @return true, success once Address approved
    //  Emit the Approval Event  
    //  Allow _spender to spend up to _value on your Behalf
    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @notice transfer by approved Person from original Address of an Amount within approved Limit 
    /// @param _from, Address sending to and the Amount to send
    /// @param _to Receiver of Token
    /// @param _value Amount Value of Token to send
    /// @dev internal Helper transfer Function with required safety Checks
    /// @return true, success once transfered from original Account    
    //  Allow _spender to spend up to _value on your behalf
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }
}