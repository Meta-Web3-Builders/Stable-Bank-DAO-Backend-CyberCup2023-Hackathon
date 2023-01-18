// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./CrowdFundFactory.sol";
import "./IDAOToken.sol";


contract DAO{
   //////////STATE VARIABLES////////
   address public Admin;
    address DUSDC;
   address daotoken;
   crowdFundFactory crowdFundFactoryAddr;
   //uint256 public Quorum = DAOMemberCount - ((DAOMemberCount * 30)/ 100);
   uint256 DAOMemberCount;
   address stabeleBankNFT;

//    enum ProposalStatus{
//     pending,
//     approved,
//     unapproved
//    }


   struct DAOMemberInfo{
    string name;
    address memberAddress;
    uint64 memberID;
    bool joined;
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
    bool cancelled;
    uint256 totalVoteCount;
    uint cancellationTime;
    uint approvedTime;
    uint deadline;
    address[] voters;
   }

    Proposals[] allProposals; //array of all proposals
    Proposals[] approvedProposals; //array of all approvedProposals


    uint256 proposalID = 1;
    uint256 proposalCount;
    uint64 memberID = 1;
    uint256 minimumrequiredDAOTokenAmount;
    uint256 maximumrequiredDAOTokenAmount;
    uint256 totalEtherDeposit;
    uint256 totalDaoTokenBal;

    address[] EligibleMembers;
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
    event AdminUpdated(address oldAdmin, address newAdmin);
    event EtherDeposited(address depositor, uint256 amountDeposited);


    ///////////CONSTRUCTOR/////////////////
    constructor(address _DAOtokenAddress, address _DUSDC, crowdFundFactory _crowdFundFactoryaddr, address _nft) {
        daotoken = _DAOtokenAddress;
        Admin = msg.sender;
        DUSDC = _DUSDC;
        crowdFundFactoryAddr = _crowdFundFactoryaddr;
        stabeleBankNFT = _nft;
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



    ///////////////CONTRACT FUNCTIONS///////////////////

    /// @dev minandmaxtokenrequired is the function for the Admin to set minimum and maximum amount of token 
    // required to join the DAO
    function minandmaxDAOtokenrequired(uint256 _minimumrequiredDAOTokenAmount, uint256 _maximumrequiredDAOTokenAmount) external{
        if(msg.sender != Admin){
            revert NotAdmin("Only the Admin is eligible to call this function");
        }
        minimumrequiredDAOTokenAmount = _minimumrequiredDAOTokenAmount;
        maximumrequiredDAOTokenAmount = _maximumrequiredDAOTokenAmount;

    }

    /// @dev function to change the Admin 
    function changeAdmin(address newAdmin) external{
        if(msg.sender != Admin){
            revert NotAdmin("Only the Admin is eligible to call this function");
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
        
        if(IStableBankToken(daotoken).balanceOf(address(this)) <= 0){
            revert ContractNotFunded("No more DAO tokens to purchase, Contact Admin");
        }
        if(IStableBankToken(daotoken).balanceOf(msg.sender) > maximumrequiredDAOTokenAmount){
            revert TooMuch("You have exceeded the maximum amount of DAO tokens required");
        }
        if((IStableBankToken(daotoken).balanceOf(msg.sender) + tokenAmount) > maximumrequiredDAOTokenAmount ){
            revert TooMuch("You have exceeded the maximum amount of DAO tokens required");
        }
       
        //calculate equivalent of ether to the DAOToken
        //10 daotoken for 1 ether
        
        
        //require(msg.value == tokenAmount, "No sufficient funds");
        IDUSDC(DUSDC).transferFrom(msg.sender, address(this), tokenAmount * 1e18);
        IStableBankToken(daotoken).transferFrom(address(this), msg.sender, tokenAmount * 1e18);
        totalEtherDeposit += msg.value;
    }


    /// @dev function for an individual to join the Stable Bank DAO 
    function joinDAO(string memory _name) external{
        DAOMemberInfo storage DMI = member[msg.sender];
        require(clickJoin[msg.sender] == false, "already joined");
        if(DMI.joined == true){
            revert AlreadyJoined("You can't join twice");
        }
                
        if(IStableBankToken(daotoken).balanceOf(address(this)) <= 0){
            revert ContractNotFunded("No more DAO tokens to purchase, Contact Admin");
        }
        clickJoin[msg.sender] = true;

        IDUSDC(DUSDC).transferFrom(msg.sender, address(this), 10 * 1e18);
        IStableBankToken(daotoken).mint(msg.sender, 10 * 1e18);

        DMI.name = _name;
        DMI.memberAddress = msg.sender;
        DMI.memberID = memberID;
        DMI.timeJoined = block.timestamp;
        //EligibleMembers.push(msg.sender);
        memberID++;
       // DAOMemberCount = DAOMemberCount + 1;
        members.push(DMI);

        emit Joined(msg.sender, block.timestamp);
    }


    function approveApplicant(address _memberAddress) external {
        DAOMemberInfo memory DMI = member[msg.sender];
        if (msg.sender != Admin) {
            revert NotAdmin("only admin required");
        }
        require(member[_memberAddress].timeJoined !=0, "Applicant has not apply");
        
        member[_memberAddress].joined = true;
        DMI.joined = true; //added
        DAOMemberCount = DAOMemberCount + 1;
        EligibleMembers.push(msg.sender);

    }

    function rejectApplicant(address _memberAddress) external {
        if (msg.sender != Admin) {
            revert NotAdmin("only admin required");
        }
        require(member[_memberAddress].timeJoined !=0, "Applicant has not apply");
        member[_memberAddress].joined = false;
        clickJoin[_memberAddress] = false;

        IDUSDC(DUSDC).transfer(_memberAddress, 10 * 1e18);
        IStableBankToken(daotoken).burnFrom(_memberAddress, 10 * 1e18);
    }

   /// @dev this function is called to create a proposal for a funding project
   /// @notice Only DAO members are eligible to create a proposal for a funding project
   /// @param _topic: the caller inputs the _topic, _description, and amount of funding for the project
   
    function createProposal(string memory _topic, string memory _description, uint256 amount,uint _deadline) external {
          DAOMemberInfo memory DMI = member[msg.sender];
          uint time = _deadline + block.timestamp;
          if(DMI.joined == false){
            revert NotEligible("You are not a member of the DAO");
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
          P.proposalID = proposalID + 1;
          proposalCount = proposalCount + 1;
          allProposals.push(P);

          proposalID += 1;

          emit ProposalCreated(msg.sender, _topic, block.timestamp);
    }


    function cancelProposal(uint256 _proposalID) external {
        if (msg.sender != Admin) {
            revert NotAdmin("only admin required");
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
            return "pending review, check back later or contact admin";
        }
    }

    function approveProposal(uint256 _proposalID) external{

        if (msg.sender != Admin) {
            revert NotAdmin("only admin required");
        }

        if (_proposals[_proposalID].cancelled == true) {
            revert proposalAlreadyCancelled();
        }
        if (_proposals[_proposalID].votes > 0) {
            revert votingAlreadyStarted("Can't approve an active proposal");
        }
        if(DAOMemberCount < 4){
            revert n0tEnoughDaoMembers("Dao members are not enough");
        }

        _proposals[_proposalID].approved = true;
        _proposals[_proposalID].approvedTime = block.timestamp;

        emit ProposalApproved(_proposalID, _proposals[_proposalID].approvedTime );

    }


    /// @dev function to vote project proposal given the proposal ID
    function voteProposal(uint prosalID) external{
        DAOMemberInfo memory DMI = member[msg.sender];
          if(DMI.joined == false){
            revert NotEligible("You are not a member of the DAO");
          }
          
          if(voted[msg.sender][prosalID] == true){
            revert AlreadyVoted("You can't vote for the same propsal twice");
          }
         
         Proposals storage Pis = _proposals[prosalID];
         if(_proposals[prosalID].approved != true){
            revert ProposalNotApproved("Proposal has not being approved");
         }

        if (IStableBankToken(daotoken).balanceOf(msg.sender) < 1e18) {
            revert insufficientToken();
        }

        if(DAOMemberCount < 3){
            revert n0tEnoughDaoMembers("Dao members are not enough");
        }
        
        Pis.votes =  Pis.votes + 1;

        if (Pis.votes >= DAOMemberCount - ((DAOMemberCount * 30)/ 100)) {
        Pis.approved = true;
        Pis.deadline;
    
        crowdFundFactory(crowdFundFactoryAddr).createCrowdfund(DUSDC, Pis.proposalInitiator, prosalID, Pis.deadline, stabeleBankNFT);
        crowdFundFactory(crowdFundFactoryAddr).getCrowdFund(prosalID);
        }

        IStableBankToken(daotoken).burnFrom(msg.sender, 1e18);

        
        _proposals[prosalID].votes = _proposals[prosalID].votes + 1;
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
        totalEtherDeposit += msg.value;

        emit EtherDeposited(msg.sender, msg.value);
    }


    /// @notice function to get all created project proposal count
    function getAllProposalCount() external view returns(uint256){
        return  proposalCount;
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


    /// @dev function to get DAO Member count
    function getDAOMemberCount() external view returns(uint256){
        return DAOMemberCount;
    }


    /// @dev function returns all voter for a particular project proposal
    function getAllVoters(uint _proposalID) external view returns(address[] memory){
        return _proposals[_proposalID].voters;
    }


    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function usdcBalance() external view returns (uint256){
        return IDUSDC(DUSDC).balanceOf(address(this));
    }

    receive() external payable {}

    fallback() external payable {}
}
