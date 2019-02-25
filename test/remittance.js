const Remittance = artifacts.require("./Remittance.sol");
const truffleAssert = require('truffle-assertions');

contract('Remittance', (accounts) => {

    let remit;
    let owner = accounts[1]
    let depositor = accounts[2]
    let shopAddress = accounts[3]
    let plainPassword = "0xaaaaaa"
    let expirePeriod = 600
    let depositAmount = 100000000000000000
    let fee = 1000000
    let gas = 210000

    beforeEach("Create a new instance", function () {
      return Remittance.new({from: owner})
        .then(function (instance) {
          remit = instance;
        });
    });

    it("Deposit - verify that a deposit can be made", async () => {
        const hashedPassword = await remit.generateHashedPassword(shopAddress, plainPassword);
        const deposit = await remit.deposit(hashedPassword, expirePeriod, {from: depositor, value: depositAmount, gas: 210000})
        assert.equal(deposit.logs[0].args.sender, depositor, "Fee has not been paid to owner");
        assert.equal(deposit.logs[1].args.amount, depositAmount, "The deposit wasn't successfull");
    })

    it("Deposit - verify that a positive amount must be deposited", async () => {
        const hashedPassword = await remit.generateHashedPassword(shopAddress, plainPassword);
        await truffleAssert.fails(remit.deposit(hashedPassword, expirePeriod, {from: depositor, value: 0, gas: 210000})), truffleAssert.ErrorType.REVERT,"You can't deposit 0 or less"
    })

    it("Withdraw - verify that a withdrawal can be made", async () => {
      const shop_starting_balance = await web3.eth.getBalance(shopAddress);
      console.log(shop_starting_balance.valueOf())
      const hashedPassword = await remit.generateHashedPassword(shopAddress, plainPassword);
      const deposit = await remit.deposit(hashedPassword, expirePeriod, {from: depositor, value: depositAmount})
      const Withdraw = await remit.withdrawFunds(plainPassword, {from: shopAddress, gas: 210000})
      const shop_end_balance = await web3.eth.getBalance(shopAddress);
      console.log(shop_end_balance.valueOf());
      assert.equal(shop_end_balance, shop_starting_balance + depositAmount - fee - gas), "Incorrect balance";
    })
}) 
  