pragma solidity ^0.4.18;

import './Trackable.sol';
import './Burnable.sol';

contract Stakeable is Trackable, Burnable {
  event DepositStake(address indexed owner, address indexed spender, uint256 value, uint256 id);
  event ReturnStake(address indexed owner, address indexed spender, uint256 value, uint256 id);
  event DestroyStake(address indexed owner, address indexed spender, uint256 value, uint256 id);

  enum StakeState { Deposited, Returned, Destroyed }

  /// @dev `Stake` is the structure that attaches a state to a
  ///  given value of stake
  struct Stake {
      // `fromBlock` is the block number that the value was generated from
      StakeState state;
      // `value` is the amount of tokens at a specific block number
      uint256 value;
      // `holder` is the address that holds the stake
      address holder;
  }

  // `deposits` tracks current stakes that have been deposited
  mapping (address => Stake[]) deposits;

  /**
   * @dev depositStake deposits a number of tokens with the holder
   *
   */
  function depositStake(address _holder, uint256 _value) public returns (uint256) {
    var stakeID = deposits[msg.sender].length;
    var tokens = balanceOfAt(_holder, block.number);
    var staked = totalDeposits(_holder);

    require(tokens.sub(staked) >= _value);

    var newStake = Stake({
      state: StakeState.Deposited,
      value: _value,
      holder: _holder
    });

    deposits[msg.sender].push(newStake);

    DepositStake(msg.sender, _holder, _value, stakeID);
    return stakeID;
  }

  function checkStake(address _owner, uint256 stakeID) public view returns (StakeState, uint256, address) {
    //Must be a possible stakeID
    require(deposits[_owner].length > stakeID);
    var deposit = deposits[_owner][stakeID];

    return (deposit.state, deposit.value, deposit.holder);
  }

  /**
   * @dev returnStake returns a number of tokens from the stake holder
   *
   */
  function returnStake(address _owner, uint256 stakeID) public returns (bool) {
    //Must be a possible stakeID
    require(deposits[_owner].length > stakeID);
    var theStake = deposits[_owner][stakeID];

    //The sender must be the deposit holder of this stake
    //and the stake must be in a deposited state
    require(theStake.holder == msg.sender && theStake.state == StakeState.Deposited);

    theStake.state = StakeState.Returned;
    return true;
  }

  /**
   * @dev returnStake returns a number of tokens from the stake holder
   *
   */
  function destroyStake(address _owner, uint256 stakeID) public returns (bool) {
    //Must be a possible stakeID
    require(deposits[_owner].length > stakeID);
    var theStake = deposits[_owner][stakeID];

    //The sender must be the deposit holder of this stake
    //and the stake must be in a deposited state
    //and the stake must not be returned
    require(theStake.holder == msg.sender
      && theStake.state == StakeState.Deposited
      && theStake.state != StakeState.Returned);

    theStake.state = StakeState.Destroyed;
    //run the burn command here
    doBurn(_owner,theStake.value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner has staked
   * @param _owner address The address which owns the funds.
   * @return A uint256 specifying the amount of tokens that are staked.
   */
  function totalDeposits(address _owner) public view returns (uint256) {

    //Has owner actually deposited before
    if(deposits[_owner].length == 0) {
      //nope
      return 0;
    }

    uint256 staked = 0;

    for(uint256 index = 0; index < deposits[_owner].length; index++) {
      var deposit = deposits[_owner][index];
      // only deposited stakes are held up
      if(deposit.state == StakeState.Deposited) {
        staked += deposit.value;
      }
    }

    return staked;
  }
}
