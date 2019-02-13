pragma solidity 0.4.24;

import "./Stoppable.sol";

contract Remittance is Stoppable {

    //State Variables
    uint256 timeOfDeposit;
    bytes32 hashedPassword;
    uint256 expirePeriodInSeconds;
    uint256 constant maxExpiryInSeconds = 604800;

    //All events to be logged
    event LogDeposit(address indexed sender, uint indexed amount, uint indexed time, uint expirePeriodinSeconds);
    event LogWithdrawFunds (address indexed sender, uint indexed amount);
    event LogOwnerWithdraws(address indexed sender, uint indexed amount, uint indexed time);

    //Mapping of hash to boolean
    mapping(bytes32 => bool) public wasUsedBefore;
    
    //Allow for deposits of Ether to be made to the contract
    function deposit(bytes32 _hashedPassword, uint256 _expirePeriodInSeconds) payable public onlyOwner onlyIfRunning {
        //Verify that the expiry (deadline) is not more than 7 days from now
        require(expirePeriodInSeconds <= maxExpiryInSeconds, "Deadline can't be out further than 7 days");
        //Verify that the hashed password hasn't been used before
        require(wasUsedBefore[_hashedPassword] == false, "Password has been used before");
        //Set the time of deposit that will be used to calculate expiry
        timeOfDeposit = now;
        //Write hashed password to state
        hashedPassword = _hashedPassword;
        //Set the password as being used
        wasUsedBefore[_hashedPassword] = true;
        //Write deadline period to state
        expirePeriodInSeconds = _expirePeriodInSeconds;
        //Create logs
        emit LogDeposit (msg.sender, msg.value, timeOfDeposit, expirePeriodInSeconds);
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
    
    //Withdraw all funds from the contract if the entered passwords are correct
    function withdrawFunds (bytes32 plainPasswordShop, bytes32 plainPasswordBeneficiary) public onlyIfNotPaused {
        //Verify that it is not past the deadline yet
        uint256 expiry = timeOfDeposit + expirePeriodInSeconds;
        require(expiry >= now, "Deadline has passed, you can no longer withdraw funds");
        //Verify that both passwords are correct
        bytes32 hashPasswordWithdraw = keccak256(abi.encodePacked(plainPasswordShop, plainPasswordBeneficiary));
        require(hashPasswordWithdraw == hashedPassword, "Incorrect password");
        //Create logs
        emit LogWithdrawFunds (msg.sender, address(this).balance);
        //If the solution is correct, send the funds to the msg.sender
        address(msg.sender).transfer(address(this).balance);
    }
    
    //Allow owner to retrieve funds if not withdrawn after more than 1 week
    function ownerWithdraws () public onlyOwner onlyIfNotPaused {
        //Verify that it is past the deadline
        uint256 expiry = timeOfDeposit + expirePeriodInSeconds;
        require(expiry < now, "Owner can only withdraw when the deadline has passed");
        //Create logs
        emit LogOwnerWithdraws (msg.sender, address(this).balance, now);
        //Transfer contract funds back to owner
        address(msg.sender).transfer(address(this).balance);
    }
}