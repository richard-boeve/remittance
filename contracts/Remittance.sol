pragma solidity 0.4.24;

import "./Stoppable.sol";
import "./SafeMath.sol";

contract Remittance is Stoppable {

    //Using the SafeMath library
    using SafeMath for uint256;

    //State Variables
    uint256 constant maxExpiryInSeconds = 604800;
    uint256 constant fee = 1000000;
    
    //All events to be logged
    event LogDeposit(address indexed sender, uint indexed amount, uint time, uint expiry);
    event LogFee(address indexed sender, uint time);
    event LogWithdrawFunds (address indexed sender, uint indexed amount);
    event LogDepositorWithdraws(address indexed sender, uint indexed amount, uint time);
    event LogOwnerWithdrawsFees(uint fees, uint time);
    
    //Struct that contains the users of the contract
    struct Deposit {
        address depositor;
        uint256 expiry;
        uint256 amount;
    }
    
    //Mapping of deposits
    mapping(bytes32 => Deposit) public deposits;
    
    //Mapping of fees
    mapping(address => uint256) public feeBalance;
    
    //Allow for deposits of Ether to be made. Deposists will be stored against a unique hash. 
    function deposit (bytes32 _hashedPassword, uint256 _expirePeriodInSeconds) payable public onlyIfRunning {
        //Verify that the message value is higher than the fee 
        require(msg.value > fee, "Fee is higher than deposit");
        //Verify that an expiry period is entered 
        require(_expirePeriodInSeconds != 0, "Expiry period in seconds is mandatory");
        //Verify that the deadline does not exceed the maximum expiry
        require(_expirePeriodInSeconds <= maxExpiryInSeconds, "Deadline exceeds the maximum expiry");
        //Verify that the storage hash hasn't been used before
        require(deposits[_hashedPassword].depositor == address(0), "Password / Shop combination has been used before");
        //Take a fee out of the msg.value 
        uint256 amount = msg.value.sub(fee);
        //Set expiry
        uint256 expiry = _expirePeriodInSeconds.add(now);
        //Write the arguments to storage
        Deposit storage currentDeposit = deposits[_hashedPassword];
        currentDeposit.depositor = msg.sender;
        currentDeposit.expiry = expiry;
        currentDeposit.amount = amount;
        //Create log for fee payment
        emit LogFee (msg.sender, now);
        //Increase the fee balance of the contract owner
        address owner = getOwner();
        feeBalance[owner] += fee;
        //Create log
        emit LogDeposit (msg.sender, msg.value, now, expiry);
    }
    
    //Retuns the balance in Ether for the contract - Here just for Remix purposes
    function getContractBalance() public view returns (uint256) { 
        return address(this).balance; 
    }
    
    //Function that allows the passwords to be set - Off chain
    function generateHashedPassword(address _shopAddress, bytes32 _plainPasswordBeneficiary) view public returns (bytes32) {
        //Verify that the shop address can't be null
        require(_shopAddress != 0, "Shop address is mandatory");
        //Verify that the password can't be null
        require(_plainPasswordBeneficiary != 0, "Benificiary password is mandatory");
        //Hash it all
        return keccak256(abi.encodePacked(this, _shopAddress, _plainPasswordBeneficiary));
    }
    
    //Withdraw all funds that the depositor has deposited for the benificiary. 
    function withdrawFunds (bytes32 _plainPasswordBeneficiary) public onlyIfNotPaused {
        //Calculate the hashed password
        bytes32 hashedPassword = generateHashedPassword(msg.sender, _plainPasswordBeneficiary);
        //Write storage record to memory for re-usage
        uint256 depositAmount = deposits[hashedPassword].amount;
        //Verify that stored deposit amount is larger than zero
        require(depositAmount > 0, "There is no balance to withdraw");
        //Set amount to zero
        deposits[hashedPassword].amount = 0;
        //Create log
        emit LogWithdrawFunds (msg.sender, depositAmount);
        //transfer the funds to the msg.sender so he/she can pay out to the benificiary
        address(msg.sender).transfer(depositAmount);
    }
    
    //Allow depositor to retrieve funds if not withdrawn by benifiary after the withdrawal expiry period has passed
    function depositorWithdraws (bytes32 _hashedPassword) public onlyIfNotPaused {
        //Write storage record to memory for re-usage
        Deposit memory depositMem = deposits[_hashedPassword];
        //Verify that the msg.sender is the depositor
        require(depositMem.depositor == msg.sender, "Only the depositor can retrieve unclaimed deposits");
        //Verify that it is past the deadline
        require(depositMem.expiry < now, "Owner can only withdraw when the deadline has passed");
        //Verify that stored deposit amount is larger than zero
        require(depositMem.amount > 0, "There is no balance to withdraw");
        //Set amount to zero
        deposits[_hashedPassword].amount = 0;
        //Create log
        emit LogDepositorWithdraws (msg.sender, depositMem.amount, now);
        //Transfer funds back to owner
        address(msg.sender).transfer(depositMem.amount);
    }
    
    //Function that allows any user who is or has been an owner, to withdraw their collected fees
    function ownerWithdrawsFees () public onlyIfNotPaused {
        //write initial fee balance from sender to variable
        uint256 feesToWithdraw = feeBalance[msg.sender];
        //Verify there are fees to withdraw
        require(feesToWithdraw > 0, "There is no fee balance to withdraw");
        //Set balance to 0 
        feeBalance[msg.sender] = 0;
        //Create log
        emit LogOwnerWithdrawsFees (feesToWithdraw, now);
        //Transer fees to msg.sender
        address(msg.sender).transfer(feesToWithdraw);
    }
}