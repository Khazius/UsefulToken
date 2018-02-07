pragma solidity ^0.4.18;

import './TrackableToken.sol';


/**
 * @title Trackable ERC20 token
 *
 * @dev Implementation of the trackable token.
 * @dev Based on code by OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity
 * @dev Based on code by Giveth: https://github.com/Giveth/minime/blob/master/contracts/MiniMeToken.sol
 */

contract ActualToken is TrackableToken  {

  function ActualToken() public {
    name = 'YAC Lotto Token';
    decimals = 18;
    symbol = 'YACL';
  }

}
