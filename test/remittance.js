const Remittance = artifacts.require("./Remittance.sol");
const truffleAssert = require('truffle-assertions');

contract('Remittance', (accounts) => {

    let remit;
    let owner = accounts[1];
    let depositor = accounts[2];
    let shopAddress = accounts[3];
    let plainPassword = "0xaaaaaa";
    let depositAmount = web3.toWei(0.1);
    let EXPIRE_PERIOD = 600;
    const FEE = 1000000;
    const GAS_PRICE = 1000;

    beforeEach("Create a new instance", async () => {
      remit = await Remittance.new({from: owner, gasPrice: GAS_PRICE})
    });

    it("Deposit - verify that a deposit can be made", async () => {
      //Create hashed password
      const hashedPassword = await remit.generateHashedPassword(shopAddress, plainPassword);  
      //Check starting balance owner
      const ownerStartingBalance = await remit.feeBalance(owner);
      //Check starting balance shop
      const shopStartingBalance = (await remit.deposits(hashedPassword))[2];
      //Submit deposit transaction
      const depositTxReceipt= await remit.deposit(hashedPassword, EXPIRE_PERIOD, {from: depositor, value: depositAmount});
      //Checking the transaction event logs
      assert.equal(depositTxReceipt.logs[0].args.sender, depositor, "Fee has not been paid to owner");
      assert.strictEqual(depositTxReceipt.logs[1].args.amount.toString(10), depositAmount.toString(10), "The deposit wasn't successfull");
      //Checking fee balance owner
      assert.equal(+FEE + +ownerStartingBalance.toString(10), (await remit.feeBalance(owner)).toString(10), "Fee balance is not correct");
      //Checking balance shop
      assert.equal(+shopStartingBalance + +depositAmount - +FEE, (await remit.deposits(hashedPassword))[2].toString(10), "Deposit balance is not correct");
    })

    it("Deposit - verify that a positive amount must be deposited", async () => {
      //Create hashed password
      const hashedPassword = await remit.generateHashedPassword(shopAddress, plainPassword);
      //Verify that a value < fee will result in the transaction being reverted
      await truffleAssert.fails(remit.deposit(hashedPassword, EXPIRE_PERIOD, {from: depositor, value: 0})), truffleAssert.ErrorType.REVERT,"The deposit needs to be larger than the fee"
    })

    it("Withdraw - verify that a withdrawal can be made", async () => {
      //Create hashed password
      const hashedPassword = await remit.generateHashedPassword(shopAddress, plainPassword);
      //Check starting balance shop blockchain
      const shopStartingBalance = await web3.eth.getBalance(shopAddress);
      //Submit transactions: Deposit and Withdraw
      const depositTxReceipt = await remit.deposit(hashedPassword, EXPIRE_PERIOD, {from: depositor, value: depositAmount});
      const withdrawTxReceipt = await remit.withdrawFunds(plainPassword, {from: shopAddress, gasPrice: GAS_PRICE });
      //Obtain gasUsed from receipt
      const gasUsed = withdrawTxReceipt.receipt.gasUsed;
      //Calculate transaction cost
      const transCost = +gasUsed.toString(10) * +GAS_PRICE.toString(10);
      //Checking the transaction event logs
      assert.equal(depositTxReceipt.logs[0].args.sender, depositor, "Fee has not been paid to owner");
      assert.strictEqual(depositTxReceipt.logs[1].args.amount.toString(10), depositAmount.toString(10), "The deposit wasn't successfull");
      assert.equal(withdrawTxReceipt.logs[0].args.amount.toString(10), +depositAmount - +FEE, "The withdrawn amount is incorrect" )
      //Checking the shop balance blockchain
      assert.equal(+shopStartingBalance + +depositAmount - +FEE + -transCost, (await web3.eth.getBalance(shopAddress)).toString(10), "The shop balance is incorrect")
      //Checking the shop balance contract
      assert.equal(0, (await remit.deposits(hashedPassword))[2], "The withdrawal has not reset the balance of the shop to 0 in the contract" )
    })
}) 
  