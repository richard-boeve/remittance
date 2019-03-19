
const Remittance = artifacts.require("./Remittance.sol");
const truffleAssert = require('truffle-assertions');
const BN = require('bn.js');

contract('Remittance', (accounts) => {

    let remit;
    let owner = accounts[0];
    let depositor = accounts[1];
    let shopAddress = accounts[2];
    let plainPassword = "0xaaaaaa";
    let depositAmount = web3.utils.toBN(web3.utils.toWei('0.1', 'ether'));
    let EXPIRE_PERIOD = new BN(600);
    const FEE = new BN(1000000);
    const GAS_PRICE = new BN(1000);

    beforeEach("Create a new instance", async () => {
      remit = await Remittance.new({from: owner, gasPrice: GAS_PRICE})
    });

    it("Verify that starting balances are zero", async () => {
      //Create hashed password
      const hashedPassword = await remit.generateHashedPassword(shopAddress, plainPassword);  
      //Check starting balances
      const ownerFeeStartingBalance = await remit.feeBalance(owner);
      const shopDepositStartingBalance = (await remit.deposits(hashedPassword))[2];
      //Verify starting balances are zero
      assert.equal(ownerFeeStartingBalance, 0, "Owner starting balance is not zero");
      assert.equal(shopDepositStartingBalance, 0, "Shop starting balance is not zero");
    })

    it("Deposit - verify that a deposit can be made", async () => {
      //Create hashed password
      const hashedPassword = await remit.generateHashedPassword(shopAddress, plainPassword);  
       //Submit deposit transaction
      const depositTxReceipt= await remit.deposit(hashedPassword, EXPIRE_PERIOD, {from: depositor, value: depositAmount});
      //Checking the transaction event logs
      assert.strictEqual(depositTxReceipt.logs[0].args.sender, depositor, "Fee has not been paid to owner");
      assert.strictEqual(depositTxReceipt.logs[1].args.amount.toString(10), depositAmount.toString(10), "The deposit wasn't successfull");
      //Checking fee balance owner
      assert.strictEqual(FEE.toString(10), (await remit.feeBalance(owner)).toString(10), "Fee balance is not correct");
      //Checking balance shop
      assert.strictEqual((depositAmount.sub(FEE)).toString(10), (await remit.deposits(hashedPassword))[2].toString(10), "Deposit balance is not correct");
    })

    it("Deposit - verify deposit fails if fee is higher than deposit value", async () => {
      //Create hashed password
      const hashedPassword = await remit.generateHashedPassword(shopAddress, plainPassword);
      //Verify that a value < fee will result in the transaction being reverted
      await truffleAssert.reverts(
        remit.deposit(hashedPassword, EXPIRE_PERIOD, {from: depositor, value: 0}), 
        "Fee is higher than deposit"
      )
    })

    it("Withdraw - verify that a withdrawal can be made", async () => {
      //Create hashed password
      const hashedPassword = await remit.generateHashedPassword(shopAddress, plainPassword);
      //Check starting balance shop blockchain
      const shopStartingBalance = new BN(await web3.eth.getBalance(shopAddress));
      //Submit transactions: Deposit and Withdraw
      const depositTxReceipt = await remit.deposit(hashedPassword, EXPIRE_PERIOD, {from: depositor, value: depositAmount});
      const withdrawTxReceipt = await remit.withdrawFunds(plainPassword, {from: shopAddress, gasPrice: GAS_PRICE });
      //Obtain gasUsed from receipt
      const gasUsed = new BN(withdrawTxReceipt.receipt.gasUsed);
      //Calculate transaction cost
      const transCost = new BN(gasUsed.mul(GAS_PRICE));
      //Checking the transaction event logs
      assert.equal(depositTxReceipt.logs[0].args.sender, depositor, "Fee has not been paid to owner");
      assert.strictEqual(depositTxReceipt.logs[1].args.amount.toString(10), depositAmount.toString(10), "The deposit wasn't successfull");
      assert.strictEqual(withdrawTxReceipt.logs[0].args.amount.toString(10), (depositAmount.sub(FEE)).toString(10), "The withdrawn amount is incorrect" )
      //Checking the shop balance blockchain
      assert.strictEqual(shopStartingBalance.add(depositAmount).sub(FEE).sub(transCost).toString(10), (await web3.eth.getBalance(shopAddress)).toString(10), "The shop balance is incorrect")
      //Checking the shop balance contract
      assert.equal(0, (await remit.deposits(hashedPassword))[2], "The withdrawal has not reset the balance of the shop to 0 in the contract" )
    })
}) 
  