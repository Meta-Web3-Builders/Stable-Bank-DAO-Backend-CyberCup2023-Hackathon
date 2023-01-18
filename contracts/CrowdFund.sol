// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./StableBankDaoNFT.sol";
interface IUSDC{
    function transferFrom(address _from,address _to,uint256 _amount) external returns(bool);
    function transfer(address _to,uint256 _amount) external returns(bool);
    function balanceOf(address account) external view returns (uint256);
}

contract CrowdFund {

    /************State Variables***************/
    address public crowdFundOwner;
    address public manager;
    address public stabeleBankNFTAddr;
    string public name;
    string public Description;
    uint public targetAmount;
    address beneficiary;
    Category public category;
    uint public donorsCount;
    uint public proposalid;
    address public crowdfundAddr;
    address public USDC;
    uint public amountRaised;
    bool public targetReached;
    bool public crowdfundCreated;
    uint public time;
    uint public duration;
    address[] public allDonators;

    enum Category{
        Tech,
        Sport,
        Health,
        Finance,
        Study,
        Travel
    }

    struct DonatedInfo {
        address addr;
        uint amount;
        uint time;
    }

    /************Errors***************/
    error withdrawn(string);
    error reached(string);
    error deadlineElapsed(string);

    mapping(address => DonatedInfo) fundDonationList;
    mapping(address => bool) donationWithdraw;
    mapping(address => bool) donated;

    DonatedInfo[] public donorListInfo;

   // event CreateCrowdFund(address indexed _benef, uint indexed _targ, string indexed name, Category _cat);
    event Donate(address indexed donor, uint indexed amount, uint indexed time);
    event withdrawFund(address indexed _benef, uint indexed amount);

    constructor(address _USDC, address _ownersAddress,uint _salt, uint _time, address _nft, uint _amountProposed, string memory _topic, bytes  memory _description, Category _cat) {
        crowdFundOwner = _ownersAddress;
        manager = msg.sender;
        crowdfundAddr = address(this);
        USDC = _USDC;
        time = _time;
        proposalid = _salt;
        duration = (_time * 1 days) + block.timestamp;
        stabeleBankNFTAddr = _nft;
        targetAmount = _amountProposed;
        name = _topic;
        targetAmount = targetAmount * 1e18;
        Description = string(abi.encodePacked(bytes(_description)));
        category = _cat;
        crowdfundCreated = true;
    }

    modifier onlyOwner {
        require(crowdFundOwner == msg.sender, "You are not permitted to perform this operation!");
        _;
    }
    modifier onlyManager{
        require(manager == msg.sender, "you are not permitted");
        _;
    }

    //function to withdrawfund
    function withdraw() external onlyOwner {
        require(msg.sender != address(0), "invalid address");
        uint amount = IUSDC(USDC).balanceOf(address(this));
        require(amount >= targetAmount, "CrowdFunding is not complete yet!");
        IUSDC(USDC).transfer(beneficiary, amount);

        donationWithdraw[beneficiary] = true;
        emit withdrawFund(beneficiary, amount);

    }

    //function to donate fund
    function donateFund(uint _amount) external payable {
        if(donationWithdraw[beneficiary] == true){
            revert withdrawn("Donation has ended, reach goals");
        }
        if(targetReached == true){
            revert reached("Target Reached. Thank you");
        }
        if(block.timestamp > duration){
            revert deadlineElapsed("sorry, deadline elapsed");
        }
        require(crowdfundCreated == true, " not created");

        uint amount = _amount * 1e18;
        require(amount > 0, "Amount should be greater than zero!");

        if((amountRaised += amount) >= targetAmount){
            assert(IUSDC(USDC).transferFrom(msg.sender, address(this), amount));
            targetReached = true;
        } else{
            assert(IUSDC(USDC).transferFrom(msg.sender, address(this), amount));

        }

        DonatedInfo storage _info = fundDonationList[msg.sender];
        if(donated[msg.sender] == true){
            _info.amount += _amount;
        }else{
         _info.addr = msg.sender;
         _info.amount += _amount;
        _info.time = block.timestamp;
        donorsCount++;
        donorListInfo.push(_info);
        allDonators.push(msg.sender);

        }
          
        donated[msg.sender] = true;

        emit Donate(msg.sender, _amount, block.timestamp);
    }

    //function to return donation if target not reached
    function disburseDonation() external payable onlyManager{
        if(targetReached == true){
            revert reached("Target Reached. Thank you");
        }
        require(block.timestamp > duration, "TIme for donation still on");
        require(msg.value > 0, "ether for transaction cost");
        for(uint i = 0; i < donorListInfo.length; i++){
            IUSDC(USDC).transfer(donorListInfo[i].addr, donorListInfo[i].amount);
        }
    }

    function donatorsNft() external payable onlyManager {
        if(targetReached == true){
            revert reached("Target Reached. Thank you");
        }
        require(block.timestamp > duration, "TIme for donation still on");
        require(msg.value > 0, "ether for transaction cost");
        for(uint i = 0; i < donorListInfo.length; i++){
            StableBankDaoNft(stabeleBankNFTAddr).safeMint(donorListInfo[i].addr);
        }

    }
    function ownersNFT() external payable onlyManager {
        if(targetReached == true){
            revert reached("Target Reached. Thank you");
        }
        require(block.timestamp > duration, "TIme for donation still on");
        require(msg.value > 0, "ether for transaction cost");
        for(uint i = 0; i < donorListInfo.length; i++){
            StableBankDaoNft(stabeleBankNFTAddr).safeMint(crowdFundOwner);
        }

    }

    function getAllDonorInfo() external view returns(DonatedInfo[] memory) {
        return donorListInfo;
    }

    function allDonorsAddress() external view returns(address[] memory){
        return allDonators;
    }

    function amountDonated(address _donor) external view returns(uint) {
        return fundDonationList[_donor].amount;
    }

    function getContractBalance() external view onlyOwner returns(uint) {
        return address(this).balance;
    }

    function getUSDCBalance() external view returns(uint){
        return IUSDC(USDC).balanceOf(address(this));
    }

    function getDonorLenght() external view returns(uint){
        return donorListInfo.length;
    }

    function getTimeLeft() external view returns(uint){
        if(duration < block.timestamp ){
            return 0;
        }else{
            return duration - block.timestamp;
        }
    }

    receive() external payable {}

    fallback() external payable {}
}