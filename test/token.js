// Specifically request an abstraction for MetaCoin
var Token = artifacts.require("MyToken");

contract('UsefulToken', function(accounts) {

  it("should have 0 tokens in the first account", function() {
    return Token.deployed().then(function(instance) {
      return instance.balanceOf.call(accounts[0]);
    }).then(function(balance) {
      assert.equal(balance.valueOf(), 0, "0 wasn't in the first account");
    });
  });

  it("should mint 10000 tokens in the first account", function() {
    var token;

    return Token.deployed().then(function(instance) {
      token = instance;
      return token.mint(accounts[0],10000);
    }).then(function () {
      return token.balanceOf.call(accounts[0]);
    }).then(function(balance) {
      assert.equal(balance.valueOf(), 10000, "10000 wasn't in the first account");
    });
  });

  it("should send token correctly", function() {
    var token;

    // Get initial balances of first and second account.
    var account_one = accounts[0];
    var account_two = accounts[1];

    var account_one_starting_balance;
    var account_two_starting_balance;
    var account_one_ending_balance;
    var account_two_ending_balance;

    var amount = 10;

    return Token.deployed().then(function(instance) {
      token = instance;
      return token.balanceOf.call(account_one);
    }).then(function(balance) {
      account_one_starting_balance = balance.toNumber();
      return token.balanceOf.call(account_two);
    }).then(function(balance) {
      account_two_starting_balance = balance.toNumber();
      return token.transfer(account_two, amount, {from: account_one});
    }).then(function() {
      return token.balanceOf.call(account_one);
    }).then(function(balance) {
      account_one_ending_balance = balance.toNumber();
      return token.balanceOf.call(account_two);
    }).then(function(balance) {
      account_two_ending_balance = balance.toNumber();

      assert.equal(account_one_ending_balance, account_one_starting_balance - amount, "Amount wasn't correctly taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance + amount, "Amount wasn't correctly sent to the receiver");

    });
  });

  it("should stake 5 tokens from the second account to the first", function() {
    var token;
    var account_one = accounts[0];
    var account_two = accounts[1];
    var amount = 5;

    var free_balance_of_two;
    var deposits_of_two;
    var stake_details;

    return Token.deployed().then(function(instance) {
      token = instance;
      return token.submitDeposit(account_one, amount, {from: account_two});
    }).then(function () {
      return token.getDeposit.call(account_two,0);
    }).then(function(stake) {
      stake_details = stake;
      return token.totalDeposits.call(account_two);
    }).then(function(balance) {
      deposits_of_two = balance.toNumber();
      return token.freeBalanceOf.call(account_two);
    }).then(function(balance) {
      free_balance_of_two = balance.toNumber();
      return token.balanceOf.call(account_two);
    }).then(function(balance) {
      assert.equal(stake_details[3].toNumber(), 0, "deposit wasn't in submitted state");
      assert.equal(stake_details[4].toNumber(), amount, "5 wasn't in the deposit");
      assert.equal(stake_details[2], account_one, "holder of deposit matches first account");
      assert.equal(deposits_of_two, amount, "5 wasn't in the second account total deposits");
      assert.equal(free_balance_of_two, amount, "5 wasn't in the second account free balance");
      assert.equal(balance.toNumber(), amount*2, "10 wasn't in the second account actual balance");
    });
  });

  it("should fail to send 10 token to first account", function() {

    var token;
    var err;
    // Get initial balances of first and second account.
    var account_one = accounts[0];
    var account_two = accounts[1];

    var account_one_starting_balance;
    var account_two_starting_balance;
    var account_one_ending_balance;
    var account_two_ending_balance;

    var amount = 10;


    return Token.deployed().then(function(instance) {
      token = instance;
      return token.balanceOf.call(account_one);
    }).then(function(balance) {
      account_one_starting_balance = balance.toNumber();
      return token.balanceOf.call(account_two);
    }).then(function(balance) {
      account_two_starting_balance = balance.toNumber();
      return token.transfer(account_one, amount, {from: account_two});
    }).catch(function(error) {
      err = error;
    }).then(function() {
      return token.balanceOf.call(account_one);
    }).then(function(balance) {
      account_one_ending_balance = balance.toNumber();
      return token.balanceOf.call(account_two);
    }).then(function(balance) {
      account_two_ending_balance = balance.toNumber();

      assert.ok(err instanceof Error,"The send should have errored");
      assert.equal(account_one_ending_balance, account_one_starting_balance, "Amount was taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance, "Amount was sent to the receiver");

    });
  });

  it("should succeed to send 5 token to first account", function() {

    var token;
    // Get initial balances of first and second account.
    var account_one = accounts[0];
    var account_two = accounts[1];

    var account_one_starting_balance;
    var account_two_starting_balance;
    var account_one_ending_balance;
    var account_two_ending_balance;

    var amount = 5;


    return Token.deployed().then(function(instance) {
      token = instance;
      return token.balanceOf.call(account_one);
    }).then(function(balance) {
      account_one_starting_balance = balance.toNumber();
      return token.balanceOf.call(account_two);
    }).then(function(balance) {
      account_two_starting_balance = balance.toNumber();
      return token.transfer(account_one, amount, {from: account_two});
    }).then(function() {
      return token.balanceOf.call(account_one);
    }).then(function(balance) {
      account_one_ending_balance = balance.toNumber();
      return token.balanceOf.call(account_two);
    }).then(function(balance) {
      account_two_ending_balance = balance.toNumber();

      assert.equal(account_one_ending_balance, account_one_starting_balance + amount, "Amount wasn't correctly taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance - amount, "Amount wasn't correctly sent to the receiver");

    });
  });

  it("should fail to burn 5 tokens in the second account", function() {
    var token;
    var err;
    var account_two = accounts[1];
    var amount = 5;

    return Token.deployed().then(function(instance) {
      token = instance;
      return token.burn(amount, {from: account_two});
    }).catch(function(error) {
      err = error;
    }).then(function () {
      return token.balanceOf.call(account_two);
    }).then(function(balance) {
      assert.ok(err instanceof Error,"The burn should have errored");
      assert.equal(balance.valueOf(), amount, "5 wasn't in the second account");
    });
  });
});
