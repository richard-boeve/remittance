pragma solidity 0.4.24;

import  "./Owned.sol";

contract Stoppable is Owned {
     
    //Global variables 
    RemittanceState public state; 
    
    //Defining the possible states of the contract
    enum RemittanceState {
        Operational,
        Paused,
        Deactivated
    }
    
    //Constructor, setting initial state upon contract creation
    constructor() public {
       state = RemittanceState.Operational;
    }  
    
    //Event logs for when a state changes
    event LogSetState(address indexed sender, RemittanceState indexed newState);
    
    //Function that allows owner to change the state of the contract
    function setState(RemittanceState newState) public onlyOwner {
        //Verify if the state is Deactivated, if so, don't allow update to the state;
        require(state != RemittanceState.Deactivated, "The contract is deactivated and can't be made operational or paused");
        //Set the state of the Contract
        state = newState;
        //Create logs
        emit LogSetState(msg.sender, newState);
    }
}