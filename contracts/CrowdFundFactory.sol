// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./CrowdFund.sol";

contract crowdFundFactory {
    CrowdFund[] public crowdfunds;

    /// @dev function to create crowdfund
    function createCrowdfund( address _DUSDC, address _ownersAddress, uint256 _salt, uint256 deadline, address _nft, uint _amountProposed, string memory _topic,  bytes  memory _description, CrowdFund.Category _cat) public returns(address crowdFundAddr, address manager){
        CrowdFund crowdfund = (new CrowdFund){salt: bytes32(_salt)}(  _DUSDC,  _ownersAddress, _salt, deadline, _nft, _amountProposed, _topic, _description, _cat);
        crowdfunds.push(crowdfund);
        return (crowdfund.crowdfundAddr(),crowdfund.crowdFundOwner());
    }

    /// @dev functionto return a particular index of a crowdfund
    function getCrowdFund( uint256 _index) public view returns ( address USDC, address deployer, address crowdFundAddr, address owner ) {
        CrowdFund crowdfund = crowdfunds[_index];
        return ( crowdfund.DUSDC(), crowdfund.manager(), crowdfund.crowdfundAddr(), crowdfund.crowdFundOwner());
    }

    /// @dev function to return all crowdfund address
    function returnCrowdfund() external view returns(CrowdFund[] memory){
        return crowdfunds;
    }

    function disburseDonation(uint256 _index) public {
        CrowdFund crowdfund = crowdfunds[_index];
        crowdfund.disburseDonation();
        
    }

    function DonatorsNFT(uint256 _index) external payable{
        CrowdFund crowdfund = crowdfunds[_index];
        CrowdFund(payable(crowdfund.crowdfundAddr())).donatorsNft();
    }
    function ownersNFT(uint256 _index) external payable{
        CrowdFund crowdfund = crowdfunds[_index];
        CrowdFund(payable(crowdfund.crowdfundAddr())).ownersNFT();
    }

}