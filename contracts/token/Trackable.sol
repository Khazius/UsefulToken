pragma solidity ^0.4.18;

import '../SafeMath.sol';

contract Trackable {
  using SafeMath for uint256;
  event Transfer(address indexed from, address indexed to, uint256 value);

  /// @dev `Checkpoint` is the structure that attaches a block number to a
  ///  given value, the block number attached is the one that last changed the
  ///  value
  struct  Checkpoint {
      // `fromBlock` is the block number that the value was generated from
      uint256 fromBlock;
      // `value` is the amount of tokens at a specific block number
      uint256 value;
  }

  // `balances` is the map that tracks the balance of each address, in this
  //  contract when the balance changes the block number that the change
  //  occurred is also included in the map
  mapping (address => Checkpoint[]) balances;


  // Tracks the history of the `totalSupply` of the token
  Checkpoint[] totalSupplyHistory;

  /// @dev This is the actual transfer function in the token contract, it can
  ///  only be called by other functions in this contract.
  /// @param _from The address holding the tokens being transferred
  /// @param _to The address of the recipient
  /// @param _amount The amount of tokens to be transferred
  /// @return True if the transfer was successful
  function doTransfer(address _from, address _to, uint256 _amount
  ) internal {

         if (_amount == 0) {
             Transfer(_from, _to, _amount);    // Follow the spec to louch the event when transfer 0
             return;
         }

         // Do not allow transfer to 0x0 or the token contract itself
         require((_to != 0) && (_to != address(this)));

         // If the amount being transfered is more than the balance of the
         //  account the transfer throws
         var previousBalanceFrom = balanceOfAt(_from, block.number);

         require(previousBalanceFrom >= _amount);

         // First update the balance array with the new value for the address
         //  sending the tokens
         updateValueAtNow(balances[_from], previousBalanceFrom.sub(_amount));

         // Then update the balance array with the new value for the address
         //  receiving the tokens
         var previousBalanceTo = balanceOfAt(_to, block.number);
         require(previousBalanceTo.add(_amount) >= previousBalanceTo); // Check for overflow
         updateValueAtNow(balances[_to], previousBalanceTo.add(_amount));

         // An event to make the transfer easy to find on the blockchain
         Transfer(_from, _to, _amount);
  }

    ////////////////
    // Query balance and totalSupply in History
    ////////////////

    /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
    /// @param _owner The address from which the balance will be retrieved
    /// @param _blockNumber The block number when the balance is queried
    /// @return The balance at `_blockNumber`
    function balanceOfAt(address _owner, uint _blockNumber) public constant
        returns (uint) {
          return getValueAt(balances[_owner], _blockNumber);
    }

    /// @notice Total amount of tokens at a specific `_blockNumber`.
    /// @param _blockNumber The block number when the totalSupply is queried
    /// @return The total amount of tokens at `_blockNumber`
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {
          return getValueAt(totalSupplyHistory, _blockNumber);
    }

    ////////////////
    // Internal helper functions to query and set a value in a snapshot array
    ////////////////

    /// @dev `getValueAt` retrieves the number of tokens at a given block number
    /// @param checkpoints The history of values being queried
    /// @param _block The block number to retrieve the value at
    /// @return The number of tokens being queried
    function getValueAt(Checkpoint[] storage checkpoints, uint _block
    ) constant internal returns (uint256) {
        if (checkpoints.length == 0) return 0;

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

    /// @dev `updateValueAtNow` used to update the `balances` map and the
    ///  `totalSupplyHistory`
    /// @param checkpoints The history of data being updated
    /// @param _value The new number of tokens
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint256 _value
    ) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint256(block.number);
               newCheckPoint.value = uint256(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint256(_value);
           }
    }
}
