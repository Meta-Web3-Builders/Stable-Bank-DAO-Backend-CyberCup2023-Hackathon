// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./StableBankDaoNFT.sol";
interface IDUSDC{
    function transferFrom(address _from,address _to,uint256 _amount) external returns(bool);
    function transfer(address _to,uint256 _amount) external returns(bool);
    function balanceOf(address account) external view returns (uint256);
}

contract CrowdFund {

    /************State Variables***************/
    address public crowdFundOwner;
    address public manager;
    address stabeleBankNFTAddr;
    string public name;
    uint public targetAmount;
    address beneficiary;
    Category category;
    uint donorsCount;
    address public crowdfundAddr;
    address public DUSDC;
    uint public amountRaised;
    bool public targetReached;
    bool crowdfundCreated;
    uint time;
    uint duration;

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

    DonatedInfo[] public donorList;

    event CreateCrowdFund(address indexed _benef, uint indexed _targ, string indexed name, Category _cat);
    event Donate(address indexed donor, uint indexed amount, uint indexed time);
    event withdrawFund(address indexed _benef, uint indexed amount);

    constructor(address _DUSDC, address _ownersAddress, uint _time, address _nft) {
        crowdFundOwner = _ownersAddress;
        manager = msg.sender;
        crowdfundAddr = address(this);
        DUSDC = _DUSDC;
        time = _time;
        stabeleBankNFTAddr = _nft;
    }

    modifier onlyOwner {
        require(crowdFundOwner == msg.sender, "You are not permitted to perform this operation!");
        _;
    }
    modifier onlyManager{
        require(manager == msg.sender, "you are not permitted");
        _;
    }

    //function to create crowdfund
    function createCrowdFund(string calldata _name, uint _target, address _beneficiary, Category _cat) external onlyOwner {
        require(_beneficiary != address(0), "Fund raising cannot be done for address zero");
        name = _name;
        targetAmount = _target * 1e18;
        beneficiary = _beneficiary;
        category = _cat;
        crowdfundCreated = true;
        duration = (time * 1 days) + block.timestamp;

        emit CreateCrowdFund(_beneficiary, _target, _name, _cat);
    }

    //function to withdrawfund
    function withdraw() external onlyOwner {
        require(msg.sender != address(0), "invalid address");
        uint amount = IDUSDC(DUSDC).balanceOf(address(this));
        require(amount >= targetAmount, "CrowdFunding is not complete yet!");
        IDUSDC(DUSDC).transfer(beneficiary, amount);

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
            assert(IDUSDC(DUSDC).transferFrom(msg.sender, address(this), amount));
            targetReached = true;
        } else{
            assert(IDUSDC(DUSDC).transferFrom(msg.sender, address(this), amount));

        }

        DonatedInfo storage _info = fundDonationList[msg.sender];
        if(donated[msg.sender] == true){
            _info.amount += _amount;
        }else{
         _info.addr = msg.sender;
         _info.amount += _amount;
        _info.time = block.timestamp;
        donorsCount++;
        donorList.push(_info);

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
        for(uint i = 0; i < donorList.length; i++){
            IDUSDC(DUSDC).transfer(donorList[i].addr, donorList[i].amount);
        }
    }

    function donatorsNft() external payable onlyManager {
        if(targetReached == true){
            revert reached("Target Reached. Thank you");
        }
        require(block.timestamp > duration, "TIme for donation still on");
        require(msg.value > 0, "ether for transaction cost");
        for(uint i = 0; i < donorList.length; i++){
            StableBankDaoNft(stabeleBankNFTAddr).safeMint(donorList[i].addr);
        }

    }
    function ownersNFT() external payable onlyManager {
        if(targetReached == true){
            revert reached("Target Reached. Thank you");
        }
        require(block.timestamp > duration, "TIme for donation still on");
        require(msg.value > 0, "ether for transaction cost");
        for(uint i = 0; i < donorList.length; i++){
            StableBankDaoNft(stabeleBankNFTAddr).safeMint(crowdFundOwner);
        }

    }

    function getAllDonor() external view returns(DonatedInfo[] memory) {
        return donorList;
    }

    function amountDonated(address _donor) external view returns(uint) {
        return fundDonationList[_donor].amount;
    }

    function getContractBalance() external view onlyOwner returns(uint) {
        return address(this).balance;
    }

    function getUSDCBalance() external view returns(uint){
        return IDUSDC(DUSDC).balanceOf(address(this));
    }

    function getDonorLenght() external view returns(uint){
        return donorList.length;
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