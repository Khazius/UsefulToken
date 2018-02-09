# UsefulToken
The UsefulToken is a standard ERC20 token with some cool extra functionality.
### The token has a Balance History (thanks MiniMeToken)
UsefulToken maintains a history of the balance changes that occur during each block. Two calls are introduced to read the totalSupply and the balance of any address at any block in the past. This functionality has been taken from the MiniMeToken (with the code relating to clones removed).
```
function totalSupplyAt(uint _blockNumber) constant returns(uint)

function balanceOfAt(address _holder, uint _blockNumber) constant returns (uint)
```
While this may add some overhead to the token the intent is to allow functionality such as dividends, votes, and anything else imaginable that requires a token balance at a point in time without the usual draw backs such as modifying the token contract itself or restricting transfers.
### The token is Burnable
Anyone can burn their tokens at any time if they want to with this function
```
function burn(uint256 _value) public returns (bool)
```
### The token is Stakeable
UsefulToken allows a token owner to deposit (or stake) a number of tokens to another address. What makes this different from simply sending the tokens to someone is that the deposit state is clearly tracked, and depositing a stake does not remove the ability to receive dividends, participate in votes, etc. while simultaneously locking those tokens and preventing them from being transferred.

Staking UsefulToken tokens is **dangerous**. The address you stake the tokens to has the ultimate power to either return your stake or burn those coins permanently.

To minimize the danger and increase the accountability of staking UsefulTokens several functions are introduced.

```
function submitDeposit(address _holder, uint256 _value) public returns (uint256 id)

function cancelDeposit(uint256 _depositID) public returns (bool)

function acceptDeposit(address _owner, uint256 _depositID) public returns (bool)

function rejectDeposit(address _owner, uint256 _depositID) public returns (bool)

function returnDeposit(address _owner, uint256 _depositID) public returns (bool)

function destroyDeposit(address _owner, uint256 _depositID) public returns (bool)
```

The owner of the tokens may submit a deposit to a holder. Until the deposit is accepted or rejected the owner may decide to cancel the deposit. (To prevent losing those tokens forever if they were sent to an address that doesn't cooperate).

The holder may decide to accept or reject. If they accept the deposit they may finally return the deposit (presumably on some conditions being met) or destroy the deposit, causing the tokens to be burnt.

Three additional calls are provided to get stake based information: the details of a specific deposit id, the total deposits made (submitted or staked) and the owners transferable token balance.

```
function getDeposit(address _owner, uint256 _depositID) public view
  returns (uint256, address, address, DepositState, uint256)

function totalDeposits(address _owner) public view returns (uint256)

function freeBalanceOf(address _owner) public view returns (uint256 balance)
```  

### Applications
The goal is that UsefulToken provides a robust platform that can be extended through new contracts. The combination of balance history and staking functionality allow the sky to be the limit of token and contract interactions.

For those who want just a balance history for easy dividends and voting rights the staking functionality can be easily removed by changing the inheritance on the UsefulToken itself.
