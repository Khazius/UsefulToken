// Specifically request an abstraction for MetaCoin
var Token = artifacts.require("MyToken");
var Dividend = artifacts.require("DividendManager");

contract('UsefulToken DividendManager', function(accounts) {

  it("should mint 750 and 250 tokens in the first and second account ", async () => {
    let token = await Token.deployed();
    await token.mint(accounts[0],750);
    await token.mint(accounts[1],250);
    var first_balance = await token.balanceOf.call(accounts[0]);
    var second_balance = await token.balanceOf.call(accounts[1]);

    assert.equal(first_balance.valueOf(), 750, "750 wasn't in the first account");
    assert.equal(second_balance.valueOf(), 250, "250 wasn't in the second account");
  });

  it("should check for zero dividends", async () => {
    let div = await Dividend.deployed();
    let div_balance = await web3.eth.getBalance(div.address);
    var first_div = await div.unclaimedFor.call(accounts[0]);
    var second_div = await div.unclaimedFor.call(accounts[1]);
    assert.equal(div_balance.valueOf(), 0, "0 wasn't in the div account");
    assert.equal(first_div.valueOf(), 0, "0 wasn't in the first account");
    assert.equal(second_div.valueOf(), 0, "0 wasn't in the second account");
  });

  it("should issue dividend for 1 ether", async () => {
    let div = await Dividend.deployed();
    await web3.eth.sendTransaction({
      from: accounts[0],
      to: div.address,
      value: web3.toWei(0.00000001,'ether')
    });
    let div_balance = await web3.fromWei(web3.eth.getBalance(div.address),'ether');
    let un_balance = web3.fromWei(await div.unissuedBalance.call(),'ether');
    let timer = await div.lastIssuedTime.call();

    assert.equal(div_balance.valueOf(), 0.00000001, "1 wasn't in the div account");
    assert.equal(un_balance.valueOf(), 0.00000001, "1 wasn't in the div account");

    await div.issueDividend();

    let person_one = await div.unclaimedFor.call(accounts[0]);
    assert.equal(web3.fromWei(person_one.toNumber(),'ether'), 0.0000000075, "1 wasn't in the div account");

    await div.claimDividend();

    person_one = await div.claimedFor.call(accounts[0]);
    assert.equal(web3.fromWei(person_one.toNumber(),'ether'), 0, "1 wasn't in the div account");

    person_one = await div.unclaimedFor.call(accounts[0]);
    assert.equal(web3.fromWei(person_one.toNumber(),'ether'), 0.0000000075, "1 wasn't in the div account");

    div_balance = await web3.fromWei(web3.eth.getBalance(div.address),'ether');
    un_balance = web3.fromWei(await div.unissuedBalance.call(),'ether');
    timer = await div.lastIssuedTime.call();
    console.log(timer.toNumber());

    try {
      await div.issueDividend();
    } catch(e) {
      console.log("Issue failed");
    }

    person_one = await div.issuedFor.call(accounts[0],0);
    console.log(person_one.toNumber());

    assert.equal(div_balance.valueOf(), 0.0000000025, "1 wasn't in the div account");
    assert.equal(un_balance.valueOf(), 0, "0 wasn't in the div unissued account");

  });



});
