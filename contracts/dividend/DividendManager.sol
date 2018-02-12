pragma solidity ^0.4.18;

import '../common/SafeMath.sol';
import '../common/Ownable.sol';
import '../token/UsefulToken.sol';

contract DividendManager is Ownable {
  using SafeMath for uint256;
  event IssuedDividend(uint256 value, uint256 id);
  event ClaimedDividend(address indexed owner, uint256 value);
  //Dividend structure attaches history to an issued dividend
  struct Dividend {
    uint256 id;
    uint256 issuedBlock;
    uint256 issuedTime;
    uint256 value;
  }

  //claimHistory maps the latest dividend id that has been claimed
  //by a token holder
  mapping(address=>uint256) claimHistory;
  //dividends keeps track of all dividends issued
  Dividend[] dividends;
  //unclaimedDividends tracks how much dividend has been issued
  //that has not yet been claimed
  uint256 unclaimedDividends;
  //dividend may be issued when the balance-unclaimedDividends > dividendThreshold
  //or when the dividendTimer seconds has elapsed since the last issued dividend
  //whichever occurs first.
  uint256 dividendThreshold;
  uint256 dividendTimer;
  //token that dividends are issued to
  UsefulToken token;

  //construct dividend manager with an existing token
  function DividendManager(address _token, uint256 _etherThreshold, uint256 _daysPerDividend) public {
    token = UsefulToken(_token);
    dividendThreshold = _etherThreshold * 1 ether;
    dividendTimer = _daysPerDividend * 1 days;
    unclaimedDividends = 0;
  }

  //dividend manager can receive ether from anyone
  function() public payable { }

  //returns the ether balance that hasn't yet been issued as a dividend
  function unissuedBalance() public view returns (uint256) {
    return this.balance.sub(unclaimedDividends);
  }

  //return the last time a dividend was issued
  function lastIssuedTime() public view returns (uint256) {
    //dividend has never been issued before
    if(dividends.length == 0) {
      return 0;
    }
    //get the most recent dividend
    var lastDividend = dividends[dividends.length-1];
    return lastDividend.issuedTime;
  }

  //series of helpers to provide unclaimed, claimed, and issued dividends for a given token holder
  function unclaimedFor(address _owner) public view returns (uint256) {
    //dividend has never been issued before
    if(dividends.length == 0) {
      return 0;
    }
    uint256 lastClaim = claimHistory[_owner];
    uint256 total = 0;
    for(uint256 index = lastClaim; index < dividends.length; index++) {
      total = total.add(issuedFor(_owner,index));
    }
    return total;
  }

  function claimedFor(address _owner) public view returns (uint256) {
    //dividend has never been issued before
    if(dividends.length == 0) {
      return 0;
    }
    uint256 lastClaim = claimHistory[_owner];
    uint256 total = 0;
    for(uint256 index = 0; index < lastClaim; index++) {
      total = total.add(issuedFor(_owner,index));
    }
    return total;
  }

  function totalIssuedFor(address _owner) public view returns (uint256) {
    //dividend has never been issued before
    if(dividends.length == 0) {
      return 0;
    }
    uint256 total;
    for(uint256 index = 0; index < dividends.length; index++) {
      total = total.add(issuedFor(_owner,index));
    }
    return total;
  }

  function issuedFor(address _owner, uint256 _dividendID) public view returns (uint256) {
    require(_dividendID < dividends.length);
    var dividend = dividends[_dividendID];
    uint256 tokensOwned = token.balanceOfAt(_owner,dividend.issuedBlock);
    uint256 tokensSupply = token.totalSupplyAt(dividend.issuedBlock);
    return tokensOwned.mul(dividend.value).div(tokensSupply);
  }

  //anyone can cause a dividend to be issued if the conditions are met
  function issueDividend() public returns (bool) {
    require(dividendThreshold <= unissuedBalance() || now >= lastIssuedTime() + dividendTimer);
    doIssue();
    return true;
  }

  //the owner can force a dividend to be issued if conditions are not yet met
  function forceDividend() public onlyOwner returns (bool) {
    doIssue();
    return true;
  }

  //anyone can attempt to claim their dividend
  function claimDividend() public returns (bool) {
    var totalUnclaimed = unclaimedFor(msg.sender);
    //enough funds must be available to payout
    require(totalUnclaimed <= unclaimedDividends && totalUnclaimed <= this.balance);
    //update claim history to latest dividend
    claimHistory[msg.sender] = dividends.length - 1;
    //reduce unclaimed dividends
    unclaimedDividends = unclaimedDividends.sub(totalUnclaimed);
    //send the payment
    msg.sender.transfer(totalUnclaimed);
    ClaimedDividend(msg.sender,totalUnclaimed);
    return true;
  }

  //internal function to generate the actual dividend
  function doIssue() internal {
    var issueValue = unissuedBalance();
    require(issueValue > 0);

    var dividendID = dividends.length++;
    Dividend storage d = dividends[dividendID];
    d.id = dividendID;
    d.issuedBlock = block.number;
    d.issuedTime = now;
    d.value = issueValue;
    unclaimedDividends = unclaimedDividends.add(issueValue);
    IssuedDividend(issueValue,dividendID);
  }
}
