// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./CrowdFund.sol";

contract crowdFundFactory {
    CrowdFund[] public crowdfunds;

    function createCrowdfund( address _DUSDC, address _ownersAddress, uint256 _salt, uint256 deadline, address _nft) public returns(address crowdFundAddr, address manager){
        CrowdFund crowdfund = (new CrowdFund){salt: bytes32(_salt)}(  _DUSDC,  _ownersAddress, deadline, _nft);
        crowdfunds.push(crowdfund);
        return (crowdfund.crowdfundAddr(),crowdfund.crowdFundOwner());
    }
    function getCrowdFund( uint256 _index) public view returns ( address DUSDC, address deployer, address crowdFundAddr, address owner ) {
        CrowdFund crowdfund = crowdfunds[_index];
        return ( crowdfund.DUSDC(), crowdfund.manager(), crowdfund.crowdfundAddr(), crowdfund.crowdFundOwner());
    }
    function DonatorsNFT(uint256 _index) public payable{
        CrowdFund crowdfund = crowdfunds[_index];
        CrowdFund(payable(crowdfund.crowdfundAddr())).donatorsNft();
    }
    function ownersNFT(uint256 _index) public payable{
        CrowdFund crowdfund = crowdfunds[_index];
        CrowdFund(payable(crowdfund.crowdfundAddr())).ownersNFT();
    }


}
