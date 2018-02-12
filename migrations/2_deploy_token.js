var MyToken = artifacts.require("../contracts/MyToken.sol");
var DividendManager = artifacts.require("../contracts/dividend/DividendManager.sol");

module.exports = function(deployer) {
  deployer.deploy(MyToken).then(function() {
    return deployer.deploy(DividendManager, MyToken.address, 1, 1);
  });
};
