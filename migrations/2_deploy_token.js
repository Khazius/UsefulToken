var MyToken = artifacts.require("../contracts/MyToken.sol");

module.exports = function(deployer) {
  deployer.deploy(MyToken);
};
