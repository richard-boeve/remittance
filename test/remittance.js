const Remittance = artifacts.require("./Remittance.sol");
const truffleAssert = require('truffle-assertions');

contract('Remittance', (accounts) => {

    let remit;
    let owner = accounts[1]
    let depositor = accounts[2]
    let shopAddress = accounts[3];
    let hashedPassword = "0x2b7efd1355e34ed7eced559b2ffff6ef96472a0dbaba6c0d1ce3b651fa474cd6"
    let expirePeriod = 600
    let depositAmount = 100
  
    beforeEach(function () {
      return Remittance.new()
        .then(function (instance) {
          remit = instance;
        });
    });

    it("Deposit - verify that a deposit can be made", async () => {
        const receipt = await remit.deposit(shopAddress, hashedPassword, expirePeriod, {from: depositor, value: depositAmount, gas: 210000})
        assert.equal(receipt.logs[1].args.amount, depositAmount, "The deposit wasn't successfull");
    })

    it("Deposit - verify that a positive amount must be deposited", async () => {
        await truffleAssert.fails(remit.deposit(shopAddress, hashedPassword, expirePeriod, {from: depositor, value: 0, gas: 210000})), truffleAssert.ErrorType.REVERT,"You can't deposit 0 or less"
    })
}) 
  