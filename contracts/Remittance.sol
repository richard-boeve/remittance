pragma solidity 0.4.24;

contract Remittance {
    
    address public owner;
    
    constructor() public payable {
        owner = msg.sender;
    }
    
    //Allow for deposits of Ether to be made to the contract
    function deposit() payable public {
    }
    
    //Retuns the balance in Ether for the contract
    function getContractBalance() public view returns (uint256) { 
        return address(this).balance; 
    }
    
    //Calculate the hash of the two combined passwords
    function calculateHash(uint256 a, uint b) public view returns (string) {
        return (keccak256(a + b));
    }    
    
    //Withdraw all funds from the contract if the hashed sum of the two passwords meets the expected hash
    function withdrawFunds (uint256 a, uint256 b) public {
        require(calculateHash(a, b) == "63806209331542711802848847270949280092855778197726125910674179583545433573378", "One or both passwords are incorrect");
        //Transfer funds to msg.sender
        //Create logs
    }
}  