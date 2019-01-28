pragma solidity 0.4.24;

import "./Stoppable.sol";

contract Remittance is Stoppable {

    //Global Variables
    uint256 timeOfDeposit;
    bytes32 hashPasswordShop;
    bytes32 hashPasswordBeneficiary;
    uint256 constant expirePeriod = 1 weeks;

    //All events to be logged
    event LogDeposit(address sender, uint amount, uint time);
    event LogWithdrawFunds (address sender, uint amount);
    event LogOwnerWithdraws(address sender, uint amount, uint time);
    
    //Allow for deposits of Ether to be made to the contract
    function deposit() payable public onlyOwner {
        require(state == RemittanceState.Operational, "Contract is not operational");
        //Set the time of deposit that will be used to calculate expiry
        timeOfDeposit = now;
        //Create logs
        emit LogDeposit (msg.sender, msg.value, timeOfDeposit);
    }
    
    //Retuns the balance in Ether for the contract
    function getContractBalance() public view returns (uint256) { 
        return address(this).balance; 
    }
    
    //Function that allows the passwords to be set
    function setPassword(string passwordShop, string passwordBeneficiary) public onlyOwner returns (bytes32, bytes32) {
        //Verify the contract is operational
        require(state == RemittanceState.Operational, "Contract is not operational");
        //Verify passwords have been entered
        require(bytes(passwordShop).length > 5, "Enter a shop password of at least 6 six characters");
        require(bytes(passwordBeneficiary).length > 5, "Enter a shop password of at least 6 six characters");
        //Hash the passwords and save as global variables
        hashPasswordShop = (keccak256(abi.encodePacked(passwordShop)));
        hashPasswordBeneficiary = (keccak256(abi.encodePacked(passwordBeneficiary)));
        return (hashPasswordShop, hashPasswordBeneficiary);
    }
    
    //Withdraw all funds from the contract if the entered passwords are correct
    function withdrawFunds (string passwordShop, string passwordBeneficiary) public {
        //Verify that both passwords are correct
        bytes32 hashPasswordShopWithdraw = (keccak256(abi.encodePacked(passwordShop)));
        bytes32 hashPasswordBeneficiaryWithdraw = (keccak256(abi.encodePacked(passwordBeneficiary)));
        require(hashPasswordShopWithdraw == hashPasswordShop, "Incorrect shop password");
        require(hashPasswordBeneficiaryWithdraw == hashPasswordBeneficiary, "Incorrect beneficiary password");
        //Create logs
        emit LogWithdrawFunds (msg.sender, address(this).balance);
        //If the solution is correct, send the funds to the msg.sender
        address(msg.sender).transfer(address(this).balance);
    }
    
    //Allow owner to retrieve funds if not withdrawn after more than 1 week
    function ownerWithdraws () public onlyOwner {
        //Verify a week has gone by
        uint256 expiry = timeOfDeposit + expirePeriod;
        require(expiry < now, "Owner can only withdraw if more than one week has passed since deposit");
        //Create logs
        emit LogOwnerWithdraws (msg.sender, address(this).balance, now);
        //Transfer contract funds back to owner
        address(msg.sender).transfer(address(this).balance);
    }
    
    //Fallback function which rejects funds sent to the contract address if sender is not the owner
    function() public { revert(); 
    }    
}