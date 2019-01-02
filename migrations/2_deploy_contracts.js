var Remittance = artifacts.require("./Remittance.sol");

module.exports = function(deployer) {
 //deployer.deploy(ConvertLib);
 // deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(Remittance);
};
