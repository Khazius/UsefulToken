pragma solidity ^0.4.20;

import './Trackable.sol';
import './Ownable.sol';

contract Mintable is Trackable, Ownable {
  event Mint(address indexed recipient, uint256 value);

  /**
   * @dev Mints a specific amount of tokens and gives them to the _recipient.
   * @param _recipient The recipient of the minted tokens.
   * @param _value The amount of token to be minted.
   */
  function mint(address _recipient, uint256 _value) public onlyOwner {
      doMint(_recipient, _value);
  }

  function doMint(address _recipient, uint256 _value) internal {
    var previousBalance = balanceOfAt(_recipient, block.number);
    var previousTotalSupply = totalSupplyAt(block.number);

    //update the balance map for the burner
    updateValueAtNow(balances[_recipient], previousBalance.add(_value));
    //update the total supply
    updateValueAtNow(totalSupplyHistory, previousTotalSupply.add(_value));

    Mint(_recipient, _value);
  }
}
