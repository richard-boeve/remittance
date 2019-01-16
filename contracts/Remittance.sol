pragma solidity 0.4.24;

contract Remittance {
    
    //Global Variables
    address public owner;
    bytes32 hash;
    uint256 amount;
    RemittanceState public state;
    uint256 timeOfDeposit;
    uint256 expiredTime;
    
    //Constructor, setting initial properties
    constructor() public {
        owner = msg.sender;
        state = RemittanceState.Operational;
    }
    
    //Modifiers
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyIfRunning {
        require(state == RemittanceState.Operational, "The contract is not operational");
        _;
    }
    
    //Defining the possible states of the contract
    enum RemittanceState {
        Operational,
        Paused,
        Deactivated
    }
    
    //All events to be logged
    event LogDeposit(address sender, uint amount, uint time);
    event LogWithdrawFunds (address sender, uint amount);
    event LogSetState(RemittanceState newState);
    event LogOwnerWithdraws(address sender, uint amount, uint time);
    
    //Change the state of the contract
    function setState(RemittanceState newState) public onlyOwner {
        //Verify if the state is Deactivated, if so, don't allow update to the state
        require(state != RemittanceState.Deactivated, "The contract is deactivated and can't be made operational or paused");
        //Set the state of the Contract
        state = newState;
        //Create logs
        emit LogSetState(newState);
    }
    
    //Allow for deposits of Ether to be made to the contract
    function deposit() payable public onlyOwner onlyIfRunning{
        //Create logs
        timeOfDeposit = now;
        amount = address(this).balance;
        emit LogDeposit (msg.sender, msg.value, timeOfDeposit);
    }
    
    //Retuns the balance in Ether for the contract
    function getContractBalance() public view returns (uint256) { 
        return address(this).balance; 
    }
    
    //Calculate the hash of the two combined passwords
    function calculateHash(uint256 a, uint b) private returns (bytes32) {
        hash = (keccak256(abi.encodePacked(a + b)));
        return hash;
    }    
    
    //Withdraw all funds from the contract if the hashed sum of the two passwords meets the expected hash
    function withdrawFunds (uint256 a, uint256 b) public onlyIfRunning {
        //Send the input from the withdrawFunds function to the calculateHash function
        calculateHash(a, b);
        //Verify that the hashed sum of the passwords is the solution
        require(hash == 63806209331542711802848847270949280092855778197726125910674179583545433573378, "One or both passwords are incorrect");
        //If the solution is correct, send the funds to the msg.sender
        address(msg.sender).transfer(amount);
        //Create logs
        emit LogWithdrawFunds (msg.sender, amount);
        }
    
    //Allow owner to retrieve funds if not withdrawn after more than 1 week
    function ownerWithdraws () public onlyOwner onlyIfRunning {
        //Verify a week has gone by
        expiredTime = timeOfDeposit + 1 weeks;
        require(expiredTime < now, "Owner can only withdraw if more than one week has passed since deposit");
        //Transfer contract funds back to owner
        address(msg.sender).transfer(amount);
        //Create logs
        emit LogOwnerWithdraws (msg.sender, amount, now);
    }
    
    //Fallback function which rejects funds sent to the contract address if sender is not the owner
    function() public { revert(); 
    }    
}
     
