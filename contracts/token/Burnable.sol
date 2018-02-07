pragma solidity ^0.4.18;

import './Trackable.sol';

contract Burnable is Trackable {
  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
      doBurn(msg.sender, _value);
  }

  function doBurn(address _burner, uint256 _value) internal {
    var previousBalanceBurner = balanceOfAt(_burner, block.number);

    //throw if trying to burn more than you have
    require(previousBalanceBurner >= _value);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure
    var previousTotalSupply = totalSupplyAt(block.number);

    //update the balance map for the burner
    updateValueAtNow(balances[_burner], previousBalanceBurner.sub(_value));
    //update the total supply
    updateValueAtNow(totalSupplyHistory, previousTotalSupply.sub(_value));

    Burn(_burner, _value);
  }
}
