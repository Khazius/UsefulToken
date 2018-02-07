var ActualToken = artifacts.require("../contracts/token/ActualToken.sol");

module.exports = function(deployer) {
  deployer.deploy(ActualToken);
};
