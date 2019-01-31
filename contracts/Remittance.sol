pragma solidity 0.4.24;

import "./Stoppable.sol";

contract Remittance is Stoppable {

    //State Variables
    uint256 timeOfDeposit;
    bytes32 hashedShopPassword;
    bytes32 hashedBenificiaryPassword;
    uint256 expirePeriodInSeconds;

    //All events to be logged
    event LogDeposit(address indexed sender, uint indexed amount, uint indexed time, uint expirePeriodinSeconds);
    event LogWithdrawFunds (address indexed sender, uint indexed amount);
    event LogOwnerWithdraws(address indexed sender, uint indexed amount, uint indexed time);
    
    //Allow for deposits of Ether to be made to the contract
    function deposit(bytes32 _hashedShopPassword, bytes32 _hashedBenificiaryPassword, uint256 _expirePeriodInSeconds) payable public onlyOwner onlyIfRunning {
        //Verify that the expiry (deadline) is not more than 7 days from now
        require(expirePeriodInSeconds <= 604800, "Deadline can't be out further than 7 days");
        //Set the time of deposit that will be used to calculate expiry
        timeOfDeposit = now;
        //Write hashed password to state
        hashedShopPassword = _hashedShopPassword;
        hashedBenificiaryPassword = _hashedBenificiaryPassword;
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
    function setPassword(string passwordShop, string passwordBeneficiary) view public onlyOwner onlyIfRunning returns (bytes32, bytes32) {
        //Verify passwords have been entered
        require(bytes(passwordShop).length > 5, "Enter a shop password of between 6 and 10 characters");
        require(bytes(passwordShop).length <= 10, "Enter a shop password of between 6 and 10 characters");
        require(bytes(passwordBeneficiary).length > 5, "Enter a beneficiary password of between 6 and 10 characters");
        require(bytes(passwordBeneficiary).length <= 10, "Enter a beneficiary password of between 6 and 10 characters");
        //Hash the passwords and save as state variables
        bytes32 hashPasswordShop = (keccak256(abi.encodePacked(passwordShop)));
        bytes32 hashPasswordBeneficiary = (keccak256(abi.encodePacked(passwordBeneficiary)));
        return (hashPasswordShop, hashPasswordBeneficiary);
    }
    
    //Withdraw all funds from the contract if the entered passwords are correct
    function withdrawFunds (string passwordShop, string passwordBeneficiary) public onlyIfNotPaused {
        //Verify that it is not past the deadline yet
        uint256 expiry = timeOfDeposit + expirePeriodInSeconds;
        require(expiry >= now, "Deadline has passed, you can no longer withdraw funds");
        //Verify that both passwords are correct
        bytes32 hashPasswordShopWithdraw = (keccak256(abi.encodePacked(passwordShop)));
        bytes32 hashPasswordBeneficiaryWithdraw = (keccak256(abi.encodePacked(passwordBeneficiary)));
        require(hashPasswordShopWithdraw == hashedShopPassword, "Incorrect shop password");
        require(hashPasswordBeneficiaryWithdraw == hashPasswordBeneficiaryWithdraw, "Incorrect beneficiary password");
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