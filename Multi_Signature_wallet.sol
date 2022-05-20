// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract wallet {
    uint256 id = 0; // counter variable WALLET ID 
    uint256 transID = 0; // counter variable the WALLET ID 
    struct walletInfo {
        string name;
        uint256 balance;
        address owner;
        address[] partners;
        uint256 id;
    }
    struct transactionInfo {
        uint256 id;
        uint256 walletID;
        address reciever;
        uint256 funds;
        uint256 totalVotes;
        uint256 numOfVotesAgainst;
        uint256 numOfVotesFor;
        bool transactionStatus;
    }
    
    mapping(uint256 => transactionInfo) public transactionDetails;  
    mapping(uint256 => walletInfo) public walletDetails;
    mapping(uint256 => mapping(address => bool)) votersDetails;
    mapping(uint256 => mapping(address => bool)) isPartner;

    event CreateWallet(string _walletName, uint _walletID, address _owner);
    event AddPartner(address _partner, uint _walletID);
    event RemovePartner(address _partner, uint _walletID);
    event DepositedFunds(address _depositer, uint _walletID, uint _funds);
    event RequestedFunds(address _requestor, uint _walletID, uint _requestedFunds, uint _transID);
    event Vote(uint _walletID, uint _transID,address _voter, bool _vote);
    event TransactedFunds(uint _transID, address _reciever, uint _walletID, uint _requestedFunds);

    modifier checkOwner(uint256 _walletID) {
        //Checks the msg.sender is the owner of _walletID.
        require(walletDetails[_walletID].owner == msg.sender, "wallet : Not a User");
        _;
    }

    //Creates New Wallet.
    //Callable by everyone.
    function createWallet(string memory _name) public payable {
        walletDetails[id].name = _name;
        walletDetails[id].balance = msg.value;
        walletDetails[id].owner = msg.sender;
        walletDetails[id].partners = new address[](0);
        walletDetails[id].id = id;
        
        emit CreateWallet(_name, id, msg.sender);

        id += 1;
    }

    //Add New Partners To Existing Wallet.
    //Only callable by owner of wallet.
    function addPartner(address _partner, uint256 _walletID)
        public
        checkOwner(_walletID)
    {
        require(isPartner[_walletID][_partner] == false, "Already a Partner");
        walletDetails[_walletID].partners.push(_partner);
        isPartner[_walletID][_partner] = true;

        emit AddPartner(_partner, _walletID);
    }

    //Remove Existing Partner From  _walletID.
    //Only callable by owner of wallet.
    function removePartner(address _partner, uint256 _walletID)
        public
        checkOwner(_walletID)
    {
        require(
            isPartner[_walletID][_partner] == true,
            "Not a Existing Partner"
        );
        uint256 len = walletDetails[_walletID].partners.length;
        uint256 index;
        //To get the Partner's index which has to be deleted.
        for (uint256 i = 0; i < len; i += 1) {
            if (_partner == walletDetails[_walletID].partners[i]) {
                index = i;
                break;
            }
        }
        //To swap the found index with the last index to delete the partner.
        walletDetails[_walletID].partners[index] = walletDetails[_walletID].partners[len - 1];
        walletDetails[_walletID].partners.pop();
        delete isPartner[_walletID][_partner];

       emit RemovePartner(_partner, _walletID);
    }

    //Add Funds in a Wallet.
    //Callable by everyone.
    function addFunds(uint256 _walletID) public payable {
        walletDetails[_walletID].balance += msg.value;

        emit DepositedFunds(msg.sender, _walletID, msg.value);
    }

    //Request Funds from the wallet.
    //Callable by everyone.
    function requestFunds(uint256 _walletID, uint256 _requestedFunds) public {
        require(_requestedFunds <= walletDetails[_walletID].balance, "Not enough Funds");
        uint256 len = walletDetails[_walletID].partners.length;

        /* If there is a requestor other than owner and partners 
        then total vote will be partners array length + owner
        If requestor is the owner or partners the he/she will be excluded 
        then total vote will be partners array length */ 
        if (msg.sender != walletDetails[_walletID].owner  && !isPartner[_walletID][msg.sender]) {
            len += 1;
        }
        transactionDetails[transID] = transactionInfo(transID,_walletID,msg.sender,_requestedFunds,len,0,0,false);

        emit RequestedFunds(msg.sender, _walletID, _requestedFunds, transID);
        transID += 1;
    }

    //Caste Vote for the requested funds.
    //Only Callable by wallet owner and partners.
    function voting(uint256 _transID, uint256 _walletID, bool _vote) public {
        
        //To check whether the voter is  wallet owner or partner.
        require(
            msg.sender == walletDetails[_walletID].owner || isPartner[_walletID][msg.sender],
            "Not Authorized To Vote"
        );
        //In case reciever is owner or partner then they cannot vote for themselves
        require(
            msg.sender != transactionDetails[transID].reciever,
            "You cannot Vote For this Transaction"
        );
        //To check whether eligible person voted or not.
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

        emit Vote(_walletID, _transID, msg.sender, _vote);
    }

    //If Voting successfull transaction will be initiated otherwise respective message will be displayed.
    //Only Callable by Requested User.
    function recieveFunds(uint256 _transID) public {

        //For checking whether the transaction is already done or not.
        require(
            !transactionDetails[_transID].transactionStatus,
            "Already Transacted"
        );

        //For checking whether the reciever address is similar to requested address.
        require(
            msg.sender == transactionDetails[_transID].reciever,
            "Invalid Request : receiver is not same"
        );
        if (transactionDetails[_transID].numOfVotesFor == transactionDetails[_transID].totalVotes) {

            payable(msg.sender).call{value: transactionDetails[_transID].funds};
            transactionDetails[_transID].transactionStatus = true;

            //Updating the Funds.
            walletDetails[transactionDetails[_transID].walletID].balance -= transactionDetails[_transID].funds;
        } else {
            revert("Transaction Denined By Authorities");
        }
        emit TransactedFunds(transID,msg.sender, transactionDetails[_transID].walletID, transactionDetails[_transID].funds);
    }

    //Display the Transaction status.
    function isTransacted(uint256 _transID) public view returns (bool) {
        return transactionDetails[_transID].transactionStatus;
    }
}
