pragma solidity 0.4.24;

import "./Stoppable.sol";

contract Remittance is Stoppable {

    //State Variables
    uint256 constant maxExpiryInSeconds = 604800;
    address owner;

    //Constructor, setting owner so this address can be paid a fee
    constructor() public payable {
        owner = msg.sender;
    }
    
    //All events to be logged
    event LogDeposit(address indexed sender, uint indexed benificiaryID, uint indexed amount, uint time, uint expirePeriodinSeconds);
    event LogFee(address indexed sender, uint indexed benificiaryID, uint time);
    event LogWithdrawFunds (address indexed sender, uint indexed benificiaryID, uint indexed amount);
    event LogOwnerWithdraws(address indexed sender, uint indexed amount, uint indexed time);
    
    //Struct that contains the users of the contract
    struct Deposit {
        bool depositExists;
        address addressSender;
        uint256 benificiaryID;
        uint256 expirePeriodInSeconds;
        uint256 timeOfDeposit;
        uint256 amount;
    }
    
    //Mapping of deposits
    mapping(bytes32 => Deposit) public deposits;
    
    //Mapping of hash to boolean
    mapping(bytes32 => bool) public wasUsedBefore;
    
    //Allow for deposits of Ether to be made. Each deposit will be mapped to a hash that consists of the benificiary's unique ID,
    //benficiary password and shop password. This hash is always unique as there is a check that prevents that the combination of 
    //benificiary ID and passwords is used more than once
    function deposit(uint256 _benificiaryID, bytes32 _hashedPassword, uint256 _expirePeriodInSeconds) payable public onlyIfRunning {
        //Verify that the message value is > 0 
        require(msg.value > 0, "You can't deposit 0 or less");
        //Verify that beneficiary id and expiry period are entered 
        require(_benificiaryID != 0, "Benificiary ID is mandatory");
        require(_expirePeriodInSeconds != 0, "Expiry period in seconds is mandatory");
        //Verify that the expiry (deadline) is not more than 7 days from now
        require(_expirePeriodInSeconds <= maxExpiryInSeconds, "Deadline can't be out further than 7 days");
        //Create a hash against which the deposit can be stored
        bytes32 storageHash = keccak256(abi.encodePacked(_benificiaryID, _hashedPassword));
        //Verify that the storage hash hasn't been used before
        require(wasUsedBefore[storageHash] == false, "Password has been used before for this");
        //Set the storageHash as being used
        wasUsedBefore[storageHash] = true;
        //Take a fee out of the msg.value 
        uint256 amount = msg.value - 1000000;
        //Write the arguments to storage
        Deposit storage currentDeposit = deposits[storageHash];
        currentDeposit.depositExists = true;
        currentDeposit.addressSender = msg.sender;
        currentDeposit.benificiaryID = _benificiaryID;
        currentDeposit.expirePeriodInSeconds = _expirePeriodInSeconds;
        currentDeposit.timeOfDeposit = now;
        currentDeposit.amount = amount;
        //Create log for transfer fee to owner
        emit LogFee (msg.sender, _benificiaryID, now);
        //Send fee to contract owner
        address(owner).transfer(1000000);
        //Create logs
        emit LogDeposit (msg.sender, _benificiaryID, msg.value, now, _expirePeriodInSeconds);
    }
    
    //Retuns the balance in Ether for the contract - Here just for Remix purposes
    function getContractBalance() public view returns (uint256) { 
        return address(this).balance; 
    }
    
    //Function that allows the passwords to be set - Off chain
    function generateHashedPassword(bytes32 plainPasswordShop, bytes32 plainPasswordBeneficiary) pure public returns (bytes32) {
        //Hash the passwords
        return keccak256(abi.encodePacked(plainPasswordShop, plainPasswordBeneficiary));
    }
    
    //Withdraw all funds that the depositor has deposited for the benificiary. The address of the depositor is used to make a 
    //match in the mapping, after which passwords are verified against the stored hash. If this passes, the balance against that
    //mapping will be paid out to the message sender
    function withdrawFunds (uint _benificiaryID, bytes32 _plainPasswordShop, bytes32 _plainPasswordBeneficiary) public onlyIfNotPaused {
        //Calculate the storageHash
        bytes32 hashPasswordWithdraw = keccak256(abi.encodePacked(_plainPasswordShop, _plainPasswordBeneficiary));
        bytes32 storageHash = keccak256(abi.encodePacked(_benificiaryID, hashPasswordWithdraw));
        //Verify that the storage hash represents an outstanding deposit
        require(deposits[storageHash].depositExists == true, "One or more of the following are incorrect: benificiary ID, password benificiary, password shop");
        //Verify that it is not past the deadline yet
        uint256 expiry = deposits[storageHash].timeOfDeposit + deposits[storageHash].expirePeriodInSeconds;
        require(expiry >= now, "Deadline has passed, you can no longer withdraw funds");
        //Create logs
        emit LogWithdrawFunds (msg.sender, _benificiaryID, deposits[storageHash].amount);
        //transfer the funds to the msg.sender so he/she can pay out to the benificiary
        address(msg.sender).transfer(deposits[storageHash].amount);
    }
    
    // //Allow depositor to retrieve funds if not withdrawn by benifiary after the withdrawal expiry period has passed
    function depositorWithdraws (uint _benificiaryID, bytes32 _plainPasswordShop, bytes32 _plainPasswordBeneficiary) public onlyIfNotPaused {
        //Calculate the storageHash
        bytes32 hashPasswordWithdraw = keccak256(abi.encodePacked(_plainPasswordShop, _plainPasswordBeneficiary));
        bytes32 storageHash = keccak256(abi.encodePacked(_benificiaryID, hashPasswordWithdraw));
        //Verify that the storage hash represents an outstanding deposit
        require(deposits[storageHash].depositExists == true, "One or more of the following are incorrect: benficiary ID, password benificiary, password shop");
        //Verify that the msg.sender is the depositor
        require(deposits[storageHash].addressSender == msg.sender, "Only the depositor can retrieve unclaimed deposits");
        //Verify that it is past the deadline
        uint256 expiry = deposits[storageHash].timeOfDeposit + deposits[storageHash].expirePeriodInSeconds;
        require(expiry < now, "Owner can only withdraw when the deadline has passed");
        //Create logs
        emit LogOwnerWithdraws (msg.sender, deposits[storageHash].amount, now);
        //Transfer funds back to owner
        address(msg.sender).transfer(deposits[storageHash].amount);
    }
 }