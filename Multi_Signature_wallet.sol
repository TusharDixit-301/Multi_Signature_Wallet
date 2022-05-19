// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract wallet{
    uint id=0;
    uint transID=0;
    struct walletInfo{
        string name;
        uint balance;
        address owner;
        address[] partners;
        uint id;
    }
    struct transactionInfo{
        uint id;
        uint walletID;
        address reciever;
        uint funds;
        uint numOfVotes;
        uint numOfVotesAgainst;
        uint numOfVotesFor;
    }
    mapping(uint => transactionInfo) transactionDetails;
    mapping(uint => walletInfo) walletDetails;
    mapping(uint => mapping(address => bool)) votersDetails;
    mapping(uint256 => mapping(address => bool)) isPartner;
    
    modifier checkOwner(uint _id){
        require(walletDetails[_id].owner == msg.sender , "wallet : Not a User");
        _;
    }
    function createWallet(string memory _name) public payable {
        
        walletDetails[id].name = _name;
        walletDetails[id].balance = msg.value;
        walletDetails[id].owner = msg.sender;
        walletDetails[id].id = id;
        id+=1;
    }
    function toAddPartners(address _partner, uint _id)public{
        walletDetails[_id].partners.push(_partner);
        isPartner[_id][_partner] = true;
    }

    function addFunds(uint _id) public payable{
        walletDetails[_id].balance += msg.value;
    }
    function votes()public{

    }
    function withdrawFunds(uint _id, uint _funds) public checkOwner(_id){
        uint len = walletDetails[_id].partners.length;
        for(uint i =0; i< len; i+=1){
            if(walletDetails[_id].partners[i] == msg.sender)
                require(
                    _funds<=walletDetails[_id].balance,
                    "Not enough Funds"
                );
                transactionDetails[transID] = transactionInfo(transID, _id, msg.sender, _funds, len, 0, 0);
                break;
            }
        
        transID +=1;
    }

    function voting(uint256 _transID, uint256 _walletID, bool _vote) public {
        require(
            msg.sender == walletDetails[_walletID].owner ||
                isPartner[_walletID][msg.sender],
            "Not Authorized To Vote"
        );
        require(
            msg.sender != transactionDetails[transID].reciever,
            "You cannot Vote For this Transaction"
        );
        require(
            !votersDetails[_transID][msg.sender],
            "Already Voted For this Transaction"
        );
        votersDetails[_transID][msg.sender] = true;

        if (_vote) {
            transactionDetails[_transID].numOfVotesFor += 1;
        } else {
            transactionDetails[_transID].numOfVotesAgainst += 1;
        }
    }

}
