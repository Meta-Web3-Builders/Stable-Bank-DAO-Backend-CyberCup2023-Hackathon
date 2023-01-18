// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./CrowdFundFactory.sol";
import "./IDAOToken.sol";


contract DAO{
   //////////STATE VARIABLES////////
   address public Admin;
    address DUSDC;
   address daotoken;
   address crowdFundFactoryAddr;
   uint256 public DAOMemberCount;
   address StableBankDaoNFT;
   uint256 proposalID = 1;
   uint256 public proposalCount;
   uint64 memberID = 1;
   uint256 minimumrequiredDAOTokenAmount;
   uint256 maximumrequiredDAOTokenAmount;



   struct DAOMemberInfo{
    string name;
    address memberAddress;
    uint64 memberID;
    bool approved;
    uint timeJoined;
   }

   struct Proposals{
    uint256 proposalID;
    string topic;
    bytes description;
    address proposalInitiator;
    uint256 amountProposed;
    uint256 votes;
    bool approved;
    bool created;
    CrowdFund.Category category;
    bool cancelled;
    uint256 totalVoteCount;
    uint cancellationTime;
    uint approvedTime;
    uint deadline;
    address[] voters;
   }

    Proposals[] allProposals; //array of all proposals
    Proposals[] approvedProposals; //array of all approvedProposals
    address[] approveMembers;
    address[] rejectedMember;
    address[] pendingApproveMembers;
    DAOMemberInfo[] members;
   

    mapping(uint256 => Proposals) _proposals;
    mapping(address => mapping(uint256 => bool)) voted;
    mapping(address => DAOMemberInfo) member;
    mapping(address => bool) clickJoin;

    ////////////CONTRACT EVENTS/////////////
    event Joined(address indexed member, uint256 indexed time);
    event ProposalCreated(address indexed propInitiator, string indexed topic, uint256 indexed time);
    event ProposalCancelled(uint256 indexed _proposalID, uint256 indexed cancellationTime);
    event ProposalApproved(uint256 indexed _proposalID, uint256 indexed ApproveTime);
    event ProposalVoted(address indexed voter, uint256 indexed proposalID, uint256 indexed voteP);
    event newCrowdfundDetails(address _USDC, address indexed manager, address indexed crowdFundAddr, address indexed owner);
    event AdminUpdated(address oldAdmin, address newAdmin);
    event EtherDeposited(address depositor, uint256 amountDeposited);


    ///////////CONSTRUCTOR/////////////////
    constructor(address _DAOtokenAddress, address _DUSDC, address _crowdFundFactoryaddr, address _nft) {
        daotoken = _DAOtokenAddress;
        Admin = msg.sender;
        DUSDC = _DUSDC;
        crowdFundFactoryAddr = _crowdFundFactoryaddr;
        StableBankDaoNFT = _nft;
        //crowdFundFactory(crowdFundFactoryAddr).createDaoToken(1);
    }


    ///////////CUSTOM ERRORS///////////////
    error NotAdmin(string);
    error NotEligible(string);
    error InsufficientToken(uint256 amountAvailable, uint256 amountExpected);
    error ToomuchToken(uint256 amountAvailable, uint256 amountExpected);
    error AlreadyJoined(string);
    error EtherNotSufficient(uint256 amountInputed,uint256 amountExpected);
    error ZeroEther(string);
    error ZeroToken(string);
    error ContractNotFunded(string);
    error AlreadyVoted(string);
    error insufficientToken();
    error ProposalNotApproved(string);
    error proposalAlreadyCancelled();
    error ZeroAddress(string);
    error TooMuch(string);
    error invalidTime(string);
    error votingAlreadyStarted(string);
    error n0tEnoughDaoMembers(string);
    error crowdFundCreated(string);



    ///////////////CONTRACT FUNCTIONS///////////////////

    /// @dev minandmaxtokenrequired is the function for the Admin to set minimum and maximum amount of token 
    // required to join the DAO
    function minandmaxDAOtokenrequired(uint256 _minimumrequiredDAOTokenAmount, uint256 _maximumrequiredDAOTokenAmount) external{
        if(msg.sender != Admin){
            revert NotAdmin("Not Admin");
        }
        minimumrequiredDAOTokenAmount = _minimumrequiredDAOTokenAmount;
        maximumrequiredDAOTokenAmount = _maximumrequiredDAOTokenAmount;

    }

    /// @dev function to change the Admin 
    function changeAdmin(address newAdmin) external{
        if(msg.sender != Admin){
            revert NotAdmin("Not admin");
        }
         if (newAdmin == address(0)) {
            revert ZeroAddress("zero address is not allowed");
        }
        Admin = newAdmin;

        emit AdminUpdated(msg.sender, newAdmin);
    }

    
    /// @dev function to purchase the DAO token
    function purchaseDAOToken(uint tokenAmount) external payable{
        //check to user balance
        
        if(IStableBank(daotoken).balanceOf(address(this)) <= 0){
            revert ContractNotFunded("Contract:No more DAO tokens");
        }
        if(IStableBank(daotoken).balanceOf(msg.sender) > maximumrequiredDAOTokenAmount){
            revert TooMuch("Enough Dao Token");
        }
        if((IStableBank(daotoken).balanceOf(msg.sender) + tokenAmount) > maximumrequiredDAOTokenAmount ){
            revert TooMuch("Enough Dao Token");
        }
       
        //calculate equivalent of ether to the DAOToken
        //10 daotoken for 1 ether
        
        
        //require(msg.value == tokenAmount, "No sufficient funds");
        IUSDC(DUSDC).transferFrom(msg.sender, address(this), tokenAmount * 1e18);
        IStableBank(daotoken).transferFrom(address(this), msg.sender, tokenAmount * 1e18);
    }


    /// @dev function for an individual to join the Stable Bank DAO 
    function joinDAO(string memory _name) external{
        DAOMemberInfo storage DMI = member[msg.sender];
        require(clickJoin[msg.sender] == false, "already joined");
         
        if(IStableBank(daotoken).balanceOf(address(this)) <= 0){
            revert ContractNotFunded("Contract:No more DAO tokens");
        }
        clickJoin[msg.sender] = true;

        IUSDC(DUSDC).transferFrom(msg.sender, address(this), 10 * 1e18);
        IStableBank(daotoken).mint(msg.sender, 10 * 1e18);

        DMI.name = _name;
        DMI.memberAddress = msg.sender;
        DMI.memberID = memberID;
        DMI.timeJoined = block.timestamp;
        memberID++;
        members.push(DMI);
        pendingApproveMembers.push(msg.sender);

        emit Joined(msg.sender, block.timestamp);
    }


    function approveApplicant(address _memberAddress) external {
        
        if (msg.sender != Admin) {
            revert NotAdmin("Not Admin");
        }
        require(member[_memberAddress].timeJoined !=0, "Applicant has not apply");

        //set the approve status in the array of struct Daomemeberinfo
        //copy the members struct to memory so as to save gas
        DAOMemberInfo[] memory _internalMember = members;
        uint i = 0;
            while (_internalMember[i].memberAddress != _memberAddress) {
                i++;
            }
            uint index = i;
        members[index].approved = true;

        //remove the address from the pending approve address array
        while (index<pendingApproveMembers.length-1) {
            pendingApproveMembers[index] = pendingApproveMembers[index+1];
            index++;
        }
        pendingApproveMembers.pop();
        
        member[_memberAddress].approved = true;
        DAOMemberCount = DAOMemberCount + 1;
        approveMembers.push(_memberAddress);

    }

    function rejectApplicant(address _memberAddress) external {
        if (msg.sender != Admin) {
            revert NotAdmin("Not Admin");
        }
        require(member[_memberAddress].timeJoined !=0, "Applicant has not apply");

        //set the approve status in the array of struct Daomemeberinfo
        //copy the members struct to memory so as to save gas
        DAOMemberInfo[] memory _internalMember = members;
        uint i = 0;
        while (_internalMember[i].memberAddress != _memberAddress) {
            i++;
        }
        uint index = i;
        members[index].approved = false;

        //remove the address from the pending approve address array
        while (index<pendingApproveMembers.length-1) {
            pendingApproveMembers[index] = pendingApproveMembers[index+1];
            index++;
        }
        pendingApproveMembers.pop();

        member[_memberAddress].approved = false;
        clickJoin[_memberAddress] = false;
        rejectedMember.push(_memberAddress);

        IUSDC(DUSDC).transfer(_memberAddress, 10 * 1e18);
        IStableBank(daotoken).burnFrom(_memberAddress, 10 * 1e18);
    }

   /// @dev this function is called to create a proposal for a funding project
   /// @notice Only DAO members are eligible to create a proposal for a funding project
   /// @param _topic: the caller inputs the _topic, _description, and amount of funding for the project
   
    function createProposal(string memory _topic, string memory _description, uint256 amount,uint _deadline, CrowdFund.Category cat) external {
          DAOMemberInfo memory DMI = member[msg.sender];
          uint time = _deadline + block.timestamp;
          if(DMI.approved == false){
            revert NotEligible("Not DAO Member");
          }
      
          if (time < block.timestamp) {
              revert invalidTime("invalid end time");
          }
  
          Proposals storage P = _proposals[proposalID];
          P.topic = _topic;
          P.description = bytes(_description);
          P.proposalID = proposalID;
          P.deadline = _deadline;
          P.amountProposed = amount;
          P.proposalInitiator = msg.sender;
          P.category = cat;
          proposalCount = proposalCount + 1;
          allProposals.push(P);

          proposalID += 1;

          emit ProposalCreated(msg.sender, _topic, block.timestamp);
    }


    function cancelProposal(uint256 _proposalID) external {
        if (msg.sender != Admin) {
            revert NotAdmin("Not Admin");
        }
        if (_proposals[_proposalID].cancelled == true) {
            revert proposalAlreadyCancelled();
        }
        if (_proposals[_proposalID].votes > 0) {
            revert votingAlreadyStarted("Can't cancel an active proposal");
        }

        Proposals storage P = _proposals[proposalID];

        P.cancelled = true;
        P.cancellationTime = block.timestamp;

        emit ProposalCancelled(_proposalID, P.cancellationTime);
    }

    function getProposalStatus(uint _proposalID) external view returns(string memory){
        if(_proposals[_proposalID].cancelled == true){
            return "cancelled";
        } else if(_proposals[_proposalID].approved == true){
            return  "approved";
        }else{
            return "pending review.";
        }
    }

    function approveProposal(uint256 _proposalID) external{

        if (msg.sender != Admin) {
            revert NotAdmin("Not Admin");
        }

        if (_proposals[_proposalID].cancelled == true) {
            revert proposalAlreadyCancelled();
        }
        if (_proposals[_proposalID].votes > 0) {
            revert votingAlreadyStarted("Active proposal");
        }
        if(DAOMemberCount < 4){
            revert n0tEnoughDaoMembers("Not enough Dao members");
        }

        _proposals[_proposalID].approved = true;
        _proposals[_proposalID].approvedTime = block.timestamp;

        emit ProposalApproved(_proposalID, _proposals[_proposalID].approvedTime );

    }

    /// @dev function to vote project proposal given the proposal ID
    function voteProposal(uint prosalID) external {
         DAOMemberInfo memory DMI = member[msg.sender];
          if(DMI.approved == false){
            revert NotEligible("Not Dao member");
          }
          
          if(voted[msg.sender][prosalID] == true){
            revert AlreadyVoted("Already Voted");
          }
         
         Proposals storage Pis = _proposals[prosalID];

        if (IStableBank(daotoken).balanceOf(msg.sender) < 1e18) {
            revert insufficientToken();
        }

        if(DAOMemberCount < 4){
            revert n0tEnoughDaoMembers("Not enough Dao Member");
        }

        if(Pis.approved != true){
            revert  ProposalNotApproved("Noty yet approved proposal ");
        }

        if(Pis.created == true){
            revert crowdFundCreated("Quorum reached, Thank you");
        }

        address beneficiary = _proposals[prosalID].proposalInitiator;
        uint _deadline = _proposals[prosalID].deadline;
        uint amountProposed  = _proposals[prosalID].amountProposed;
        string memory name = _proposals[prosalID].topic;
        bytes  memory description = _proposals[prosalID].description;
        CrowdFund.Category cat = _proposals[prosalID].category;
         
        Pis.votes =  Pis.votes + 1;

        if (Pis.votes >= (DAOMemberCount - ((DAOMemberCount * 30)/ 100))) {
        Pis.created = true;
        Pis.deadline = _deadline + block.timestamp;
    
         deployCrowdFund(crowdFundFactoryAddr, DUSDC, beneficiary , prosalID, _deadline, StableBankDaoNFT, amountProposed, name, description, cat);
         ( address _USDC, address manager, address crowdFundAddr, address owner) = returnClonedAddress(crowdFundFactoryAddr, prosalID);

         emit newCrowdfundDetails(_USDC, manager, crowdFundAddr, owner);
        }

        IStableBank(daotoken).burnFrom(msg.sender, 1e18);

        voted[msg.sender][prosalID] = true;
        Pis.voters.push(msg.sender);
     
        Pis.totalVoteCount = Pis.totalVoteCount + 1;

        emit ProposalVoted(msg.sender, prosalID, 1);
         
    }
     
     /// @notice function to deposit ether into the DAO
    function depositIntoDAO () public payable{
        if( msg.value == 0 ){
            revert ZeroEther("Zero ether not allowed");
        }

        emit EtherDeposited(msg.sender, msg.value);
    }

    function transferLockedToken(address tokenAddress) public {
        if (msg.sender != Admin) {
            revert NotAdmin("only admin required");
        }
        uint amount = IUSDC(tokenAddress).balanceOf(address(this));

        IUSDC(tokenAddress).transfer(msg.sender, amount);
    }
    
    /// @dev function to get the vote count of a particular proposal
    function voteCount(uint ID) external view returns(uint256){
        Proposals memory Pis = _proposals[ID];
        return Pis.totalVoteCount;
    }

    /// @notice function to get all created proposals
    function getAllProposals() external view returns( Proposals[] memory Pl ){
        return allProposals;
    }


    /// @notice function to return a particular proposal
    /// @param prosalID: ID of the proposal
    function viewProposal(uint prosalID) external view returns(Proposals memory){
        return _proposals[prosalID];
    }


    /// @notice function to return a particular DAO member information
    /// @param memberAddr: Address of the DAO member 
    function viewDAOMemberInfo(address memberAddr) external view returns(DAOMemberInfo memory){
        return member[memberAddr];
    }

    function getProposalDeadline(uint _proposalId) external view returns(uint ){
        return _proposals[_proposalId].deadline;
        
    }


    /// @notice function to show all DAO members information
    function showAllDAOMemberDetails() external view returns(DAOMemberInfo[] memory memberInfo) {
        return members;
    }


    /// @dev function to return all members that need to be aprrove/reject
    function allPendingMember() external view returns(address[] memory){
        return pendingApproveMembers;
    }


    /// @dev function returns all voter for a particular project proposal
    function getAllVoters(uint _proposalID) external view returns(address[] memory){
        return _proposals[_proposalID].voters;
    }


    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function usdcBalance() external view returns (uint256){
        return IUSDC(DUSDC).balanceOf(address(this));
    }



    function changeCrowdfundFactory(address _crowdFundFactory) external {
        if(msg.sender != Admin){
            revert NotAdmin("Only the Admin is eligible to call this function");
        }

        crowdFundFactoryAddr = _crowdFundFactory;    
    }

    //Helper functions
    function deployCrowdFund(address _crowdFundFactoryAddr, address _USDC, address _ownersAddress, uint256 _salt, uint256 deadline, address _nft, uint _amountProposed, string memory _topic, bytes memory _description, CrowdFund.Category cat) internal returns(address crowdFundAddr, address manager ) {
        
      return crowdFundFactory(_crowdFundFactoryAddr).createCrowdfund(_USDC, _ownersAddress, _salt, deadline, _nft, _amountProposed, _topic, _description, cat);

    }

    function returnClonedAddress(address _crowdFundFactoryAddr, uint index) internal view returns(address _USDC, address deployer, address crowdFundAddr, address owner ) {

        return crowdFundFactory(_crowdFundFactoryAddr).getCrowdFund(index - 1);
    }

    receive() external payable {}

    fallback() external payable {}
}