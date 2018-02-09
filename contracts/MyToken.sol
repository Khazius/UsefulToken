pragma solidity ^0.4.18;

import './token/UsefulToken.sol';


/**
 * @title Deploy My Useful Token
 */

contract MyToken is UsefulToken  {
  function MyToken() public {
    name = 'My Token';
    decimals = 18;
    symbol = 'MYTK';
  }
}
