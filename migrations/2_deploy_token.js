var MyToken = artifacts.require("../contracts/token/MyToken.sol");

module.exports = function(deployer) {
  deployer.deploy(MyToken);
};
