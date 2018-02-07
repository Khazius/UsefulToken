pragma solidity ^0.4.18;

import './Stakeable.sol';
import './Mintable.sol';
import './Approvable.sol';


/**
 * @title Trackable ERC20 token
 *
 * @dev Implementation of the trackable token.
 * @dev Based on code by OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity
 * @dev Based on code by Giveth: https://github.com/Giveth/minime/blob/master/contracts/MiniMeToken.sol
 */

contract TrackableToken is Approvable, Stakeable, Mintable  {

    string public name;
    uint8 public decimals;
    string public symbol;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
      require(freeBalanceOf(msg.sender) >= _value);
      doTransfer(msg.sender, _to, _value);
      return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
      require(_value <= allowed[_from][msg.sender]);
      require(freeBalanceOf(_from) >= _value);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

      doTransfer(_from, _to, _value);
      return true;
    }

    /**
    * @dev Gets the free balance (balance - deposits) of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function freeBalanceOf(address _owner) public view returns (uint256 balance) {
      return balanceOfAt(_owner, block.number).sub(totalDeposits(_owner));
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
      return balanceOfAt(_owner, block.number);
    }

    /// @dev This function makes it easy to get the total number of tokens
    /// @return The total number of tokens
    function totalSupply() public constant returns (uint256) {
        return totalSupplyAt(block.number);
    }
}
