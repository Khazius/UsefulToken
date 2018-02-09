pragma solidity ^0.4.18;

import './Burnable.sol';

/**
 * @title Stakeable token
 *
 * @dev Provide an ability to deposit tokens as a stake without losing access dividends and voting rights
 * @dev To avoid tokens being permanents in limbo by depositing them with uncooperating contracts/people
 * we utilize a submit -> accept/reject/cancel workflow. Once accepted the deposit may be returned/destroyed.
 */

contract Stakeable is Burnable {
  event SubmitDeposit(address indexed owner, address indexed holder, uint256 value, uint256 id);
  event AcceptDeposit(address indexed owner, address indexed holder, uint256 value, uint256 id);
  event RejectDeposit(address indexed owner, address indexed holder, uint256 value, uint256 id);
  event CancelDeposit(address indexed owner, address indexed holder, uint256 value, uint256 id);
  event ReturnDeposit(address indexed owner, address indexed holder, uint256 value, uint256 id);
  event DestroyDeposit(address indexed owner, address indexed holder, uint256 value, uint256 id);

  enum DepositState { Submitted, Staked, Cancelled, Rejected, Returned, Destroyed }

  /// @dev `Deposit` is the structure that attaches a state to a
  ///  given value of stake
  struct Deposit {
    // `id` is the id of this deposit
    uint256 id;
    // `owner` is the address that submitted the stake
    address owner;
    // `holder` is the address that holds the stake
    address holder;
    // `state` is the current state of this stake
    DepositState state;
    // `value` is the amount of tokens placed as a stake
    uint256 value;
  }

  // `deposits` tracks current stakes that have been deposited
  mapping (address => Deposit[]) deposits;

  /**
   * @dev Burns a specific amount of tokens - override so we dont burn staked coins
   * @param _value The amount of token to be burned.
   * @return A bool specifying the burn was successful
   */
  function burn(uint256 _value) public returns (bool) {
    var tokenBalance = balanceOfAt(msg.sender, block.number);
    var depositBalance = totalDeposits(msg.sender);
    //free balance must be greater than value to allow a burn
    require(tokenBalance.sub(depositBalance) >= _value);
    //proceed with the parent burn
    return super.burn(_value);
  }

  /**
   * @dev submitDeposit submits a deposit of number of tokens with the holder
   * pending acceptance by the holder
   * @param _holder address The address which holds the deposit
   * @param _value uint256 The value of the deposit
   * @return A uint256 specifying the ID of the deposit
   */
  function submitDeposit(address _holder, uint256 _value) public returns (uint256 id) {
    var depositID = deposits[msg.sender].length;
    var tokenBalance = balanceOfAt(msg.sender, block.number);
    var depositBalance = totalDeposits(msg.sender);
    //free balance must be greater than value to allow a burn
    require(tokenBalance.sub(depositBalance) >= _value);
    //build deposit and push to mapping
    var deposit = Deposit({
      id: depositID,
      owner: msg.sender,
      holder: _holder,
      state: DepositState.Submitted,
      value: _value
    });
    deposits[msg.sender].push(deposit);
    //fire event
    SubmitDeposit(deposit.owner, deposit.holder, deposit.value, deposit.id);
    return depositID;
  }

  /**
   * @dev cancelDeposit allows the owner to cancel a submitted deposit
   * @param _depositID uint256 The ID of the deposit being returned
   * @return A bool specifying the accept was successful
   */
  function cancelDeposit(uint256 _depositID) public returns (bool) {
    //Must be a possible depositID
    require(deposits[msg.sender].length > _depositID);
    var deposit = deposits[msg.sender][_depositID];
    //The sender must be the deposit owner of this stake
    //and the deposit must be in a valid state
    require(deposit.owner == msg.sender && deposit.state == DepositState.Submitted);
    //set state and fire event
    deposit.state = DepositState.Cancelled;
    CancelDeposit(deposit.owner, deposit.holder, deposit.value, deposit.id);
    return true;
  }

  /**
   * @dev acceptDeposit allows the holder to accept a submitted deposit
   * @param _owner address The address which owns the funds.
   * @param _depositID uint256 The ID of the deposit being accepted
   * @return A bool specifying the accept was successful
   */
  function acceptDeposit(address _owner, uint256 _depositID) public returns (bool) {
    //Must be a possible depositID
    require(deposits[_owner].length > _depositID);
    var deposit = deposits[_owner][_depositID];
    //The sender must be the deposit holder of this stake
    //and the deposit must be in a valid state
    require(deposit.holder == msg.sender && deposit.state == DepositState.Submitted);
    //set state and fire event
    deposit.state = DepositState.Staked;
    AcceptDeposit(deposit.owner, deposit.holder, deposit.value, deposit.id);
    return true;
  }

  /**
   * @dev rejectDeposit allows the holder to reject a submitted deposit
   * @param _owner address The address which owns the funds.
   * @param _depositID uint256 The ID of the deposit being rejected
   * @return A bool specifying the accept was successful
   */
  function rejectDeposit(address _owner, uint256 _depositID) public returns (bool) {
    //Must be a possible depositID
    require(deposits[_owner].length > _depositID);
    var deposit = deposits[_owner][_depositID];
    //The sender must be the deposit holder of this stake
    //and the deposit must be in a valid state
    require(deposit.holder == msg.sender && deposit.state == DepositState.Submitted);
    //set state and fire event
    deposit.state = DepositState.Rejected;
    RejectDeposit(deposit.owner, deposit.holder, deposit.value, deposit.id);
    return true;
  }

  /**
   * @dev returnDeposit returns a number of tokens from the stake holder
   * @param _owner address The address which owns the funds.
   * @param _depositID uint256 The ID of the deposit being returned
   * @return A bool specifying the return was successful
   */
  function returnDeposit(address _owner, uint256 _depositID) public returns (bool) {
    //Must be a possible depositID
    require(deposits[_owner].length > _depositID);
    var deposit = deposits[_owner][_depositID];
    //The sender must be the deposit holder of this stake
    //and the deposit must be in a valid state
    require(deposit.holder == msg.sender && deposit.state == DepositState.Staked);
    //set state and fire event
    deposit.state = DepositState.Returned;
    ReturnDeposit(deposit.owner, deposit.holder, deposit.value, deposit.id);
    return true;
  }

  /**
   * @dev destroyDeposit destroys a number of tokens by the stake holder
   * @param _owner address The address which owns the funds.
   * @param _depositID uint256 The ID of the deposit being destroyed
   * @return A bool specifying the destroy was successful
   */
  function destroyDeposit(address _owner, uint256 _depositID) public returns (bool) {
    //Must be a possible depositID
    require(deposits[_owner].length > _depositID);
    var deposit = deposits[_owner][_depositID];
    //The sender must be the deposit holder of this stake
    //and the deposit must be in a valid state
    require(deposit.holder == msg.sender && deposit.state == DepositState.Staked);
    //run the internal burn command here
    doBurn(deposit.owner,deposit.value);
    //set state and fire event
    deposit.state = DepositState.Destroyed;
    DestroyDeposit(deposit.owner, deposit.holder, deposit.value, deposit.id);
    return true;
  }

  /**
   * @dev getDeposit returns the deposit details for a specific deposit
   * @param _owner address The address which owns the funds.
   * @param _depositID uint256 The ID of the deposit being destroyed
   * @return A bool specifying the destroy was successful
   */
  function getDeposit(address _owner, uint256 _depositID) public view
    returns (uint256, address, address, DepositState, uint256) {
    //Must be a possible stakeID
    require(deposits[_owner].length > _depositID);
    var deposit = deposits[_owner][_depositID];
    return (deposit.id, deposit.owner, deposit.holder, deposit.state, deposit.value);
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
    //get the total deposits made
    uint256 depositBalance = 0;
    for(uint256 index = 0; index < deposits[_owner].length; index++) {
      var deposit = deposits[_owner][index];
      // only pending and staked deposits are tallied
      if(deposit.state == DepositState.Staked || deposit.state == DepositState.Submitted) {
        depositBalance = depositBalance.add(deposit.value);
      }
    }
    return depositBalance;
  }
}
