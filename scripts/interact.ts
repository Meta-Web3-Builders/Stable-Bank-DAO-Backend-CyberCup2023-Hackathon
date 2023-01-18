
const { ethers } = require('hardhat');
import { Contract, providers, utils, Wallet } from "ethers";
require("dotenv").config({ path: ".env" });

async function main () {

   const rpc =  await new providers.JsonRpcProvider( process.env.ALCHEMY_mumbai_API_KEY_URL ) ;
   //@ts-ignore
   const contractOwner = new Wallet( process.env.ACCOUNT_PRIVATE_KEY, rpc);
   //@ts-ignore
   const wallet2 = new Wallet( process.env.ACCOUNT_PRIVATE_KEY2, rpc);
   //@ts-ignore
   const wallet3 = new Wallet( process.env.ACCOUNT_PRIVATE_KEY3, rpc);
   //@ts-ignore
   const wallet4 = new Wallet( process.env.ACCOUNT_PRIVATE_KEY4, rpc);
   //@ts-ignore
   const wallet5 = new Wallet( process.env.ACCOUNT_PRIVATE_KEY5, rpc);
   //@ts-ignore
   const wallet6 = new Wallet( process.env.ACCOUNT_PRIVATE_KEY6, rpc);

   //console.log(wallet2.address)
  
//   const accounts = await ethers.getSigners()
//   const contractOwner = accounts[0]

    //DEPLOYING STABLE BANK DAO TOKEN CONTRACT
    const DAOToken = await ethers.getContractFactory("StableBankToken");
    const daotoken = await DAOToken.deploy();
  
    await daotoken.deployed();

    console.log(`Stable Bank DAOToken contract is deployed to ${daotoken.address}`);
  
     
    //DEPLOYING STABLE BANK FUNDY NFT CONTRACT
    const FundyNFT = await ethers.getContractFactory("StableBankDaoNft");
    const nft = await FundyNFT.deploy();
  
    await nft.deployed();
    console.log(`Stable Bank Fundy NFT contract is deployed to ${nft.address}`);
  
  
     //DEPLOYING STABLE BANK USDC TOKEN CONTRACT
    const DUSDC = await ethers.getContractFactory("DUSDC");
    const Dusdc = await DUSDC.deploy();
  
    await Dusdc.deployed();
    console.log(`Stable Bank USDC Token contract is deployed to ${Dusdc.address}`);
  
  
  //DEPLOYING CROWD FUND FACTORY CONTRACT
    const CrowdFundFactory = await ethers.getContractFactory("crowdFundFactory");
    const CFF = await CrowdFundFactory.deploy();
  
    await CFF.deployed();
    console.log(`Crowd Fund Factory contract is deployed to ${CFF.address}`);


      
  //DEPLOYING CROWD FUND FACTORY CONTRACT
  const DAO = await ethers.getContractFactory("DAO");
  const Dao = await DAO.deploy( daotoken.address, Dusdc.address, CFF.address,nft.address);

  await Dao.deployed();
  console.log(`Dao contract is deployed to ${Dao.address}`);

  // DEPLOYING Dusdc minting address FACTORY CONTRACT
  const DusdcMinting = await ethers.getContractFactory("DusdcMinting");
  const dusdcMinting = await DusdcMinting.deploy(Dusdc.address);

  await dusdcMinting.deployed();
  console.log(`dusdcMinting contract is deployed to ${dusdcMinting.address}`);




  /*************************Testing Project****************************** */

  //++++++INteracting+++++++++++++++//

  //***************DAOTOKEN INTERACTION****************//

//   const wallet2 = accounts[1];
//   const wallet3 = accounts[2];
//   const wallet4 = accounts[3];
//   const wallet5 = accounts[4];
//   const wallet6 = accounts[5];
//   const contractOwner = accounts[6];

  const DAOTokenInteract = await ethers.getContractAt("StableBankToken", daotoken.address);
  const daoamt = ethers.utils.parseEther("500")
  await DAOTokenInteract.connect(contractOwner).mint(Dao.address, daoamt)


 

  await DAOTokenInteract.transferOwnership(Dao.address);
  const amtToApprove = await ethers.utils.parseEther("20")

  await DAOTokenInteract.connect(wallet2).approve(Dao.address, amtToApprove);
  await DAOTokenInteract.connect(wallet3).approve(Dao.address, amtToApprove);
  await DAOTokenInteract.connect(wallet4).approve(Dao.address, amtToApprove);
  await DAOTokenInteract.connect(wallet5).approve(Dao.address, amtToApprove);
  const stableApprove5 = await DAOTokenInteract.connect(wallet6).approve(Dao.address, amtToApprove);

  console.log("Stable Approve 5; ", stableApprove5)



  //****************USDC INTERACTION************ *//
  const USDCInteract = await ethers.getContractAt("DUSDC", Dusdc.address);
  const usdcTomint= await ethers.utils.parseEther("5000")
  await USDCInteract.connect(contractOwner).transferFromContract(dusdcMinting.address, usdcTomint)

 await USDCInteract.connect(wallet2).approve(Dao.address, amtToApprove);
 await USDCInteract.connect(wallet3).approve(Dao.address, amtToApprove);
 await USDCInteract.connect(wallet4).approve(Dao.address, amtToApprove);
 await USDCInteract.connect(wallet5).approve(Dao.address, amtToApprove);
 const usdcapprove5 = await USDCInteract.connect(wallet6).approve(Dao.address, amtToApprove);
 console.log("APPROVE 5: ", usdcapprove5);


  /***********************UsdcMInting contract******************************* */
  const USdcmintingInteract = await ethers.getContractAt("DusdcMinting", dusdcMinting.address);

 await USdcmintingInteract.connect(wallet2).mintToken();
 await USdcmintingInteract.connect(wallet3).mintToken();
 await USdcmintingInteract.connect(wallet4).mintToken();
 await USdcmintingInteract.connect(wallet5).mintToken();
 await USdcmintingInteract.connect(contractOwner).mintToken();
 const addr5mint = await USdcmintingInteract.connect(wallet6).mintToken();
 console.log("address 5 minted: ", addr5mint);

  /****************************DAO Interact********************************** */
 const DaoInteract = await ethers.getContractAt("DAO", Dao.address);
 await DaoInteract.connect(wallet2).joinDAO("Isaac")
 await DaoInteract.connect(wallet3).joinDAO("Sayrarh")
 await DaoInteract.connect(wallet4).joinDAO("Abiodun")
 await DaoInteract.connect(wallet5).joinDAO("Isiak")
 const ayodejiJOined = await DaoInteract.connect(wallet6).joinDAO("Ayodeji")
 console.log("Ayodeji Joined", ayodejiJOined)

  /**************************approve user******************************* */
 await DaoInteract.connect(contractOwner).approveApplicant(wallet2.address)
 await DaoInteract.connect(contractOwner).approveApplicant(wallet3.address)
 await DaoInteract.connect(contractOwner).approveApplicant(wallet4.address)
 await DaoInteract.connect(contractOwner).approveApplicant(wallet5.address)
 const ayodejiApprove = await DaoInteract.connect(contractOwner).approveApplicant(wallet6.address)
 console.log("Ayodeji approve", ayodejiApprove)



  /****************************create a proposal*********************************** */
 await DaoInteract.connect(wallet2).createProposal(
    "Help the needy",
    "Help the needy in my local community",
    5000,
    6
    )
 const addr2Create = await DaoInteract.connect(wallet3).createProposal(
    "Funds for Orphans",
    "Raise funds for the less priviledge in my community",
    4000,
    10
  )

  console.log("address 2 create proposal: ", addr2Create)

  /************************Approve Proposal******************** */
 await DaoInteract.connect(contractOwner).approveProposal(1)
 const approveProposal2 = await DaoInteract.connect(contractOwner).approveProposal(2)
 console.log("proposal 2 approved: ", approveProposal2)

  /***********************Vote For Proposal 1********************** */
 await DaoInteract.connect(wallet2).voteProposal(1)
 await DaoInteract.connect(wallet3).voteProposal(1)
 await DaoInteract.connect(wallet4).voteProposal(1)
 const approval1_4 = await DaoInteract.connect(wallet5).voteProposal(1)
//await DaoInteract.connect(wallet6).voteProposal(1)
 const res = await approval1_4.wait()

 console.log("approval 1vote 4: ",  res.events[0].topics) //index3 of the event emitted- crowdfundaddr
 //console.log("approval 1vote 5: ", approval1_5) rrevert with quorum reached


    /***********************Vote For Proposal 2********************* */
 await   DaoInteract.connect(wallet2).voteProposal(2)
 await   DaoInteract.connect(wallet3).voteProposal(2)
 await   DaoInteract.connect(wallet4).voteProposal(2)
const approval2_4 = await   DaoInteract.connect(wallet5).voteProposal(2)
// await   DaoInteract.connect(wallet6).voteProposal(2)
 const res2 = await approval2_4.wait()

 console.log("approval 2vote 4: ", res2.events[0].topics)
 //console.log("approval 2vote 5: ", approval2_5) revert with qorum reached
    /************************************************ */

    /******************CrowdFundFactory INteract*************************** */
    const crowdFundFactoryInteract = await ethers.getContractAt("crowdFundFactory", CFF.address)
    const addressCreated = await crowdFundFactoryInteract.connect(contractOwner).returnCrowdfund();
    console.log("crwodfund address created", addressCreated)

    /**********************Crowdfund interact**************************** */
    const crwodfundInteract1 = await ethers.getContractAt("CrowdFund", addressCreated[0]);
    const crwodfundInteract2 = await ethers.getContractAt("CrowdFund", addressCreated[1]);

    /******************************************************* */
    const proposal1Details = await DaoInteract.connect(wallet3).callStatic.viewProposal(1)
    const proposal2Details = await DaoInteract.connect(wallet3).callStatic.viewProposal(2)
    
    console.log("proposal Details 1: ", proposal1Details)
    console.log("proposal Details 2: ", proposal2Details)

    console.log("proposal1Details", proposal1Details[1], Number(proposal1Details[4]).toString(), proposal1Details[3], 1)
    console.log("proposal2Details", proposal2Details[1], Number(proposal2Details[4]).toString(), proposal2Details[3], 1)

    /**********************Get crowdfunf owner*************************************** */
    const crowdfundOwmner = await crwodfundInteract1.connect(wallet2).callStatic.crowdFundOwner()
    const crowdfundOwmner2 = await crwodfundInteract2.connect(wallet3).callStatic.crowdFundOwner()
    console.log("crowdfund ownder", crowdfundOwmner, crowdfundOwmner2)

   //  name
   //  target
   //  beneficiary 
   //  cat
    const createCrowd = await crwodfundInteract1.connect(wallet2).createCrowdFund( proposal1Details[1], Number(proposal1Details[4]).toString(), proposal1Details[3], 1)
    const createCrowd2 = await crwodfundInteract2.connect(wallet3).createCrowdFund(proposal2Details[1], Number(proposal2Details[4]).toString(), proposal2Details[3], 1)
    console.log("crowdfund created: ", createCrowd)
    console.log("crowdfund created2: ", createCrowd2)


    /*************************Get crowdfund Description*********************8 */
     const desc1 = await crwodfundInteract1.connect(wallet5).Description()
     const desc2 = await crwodfundInteract2.connect(wallet5).Description()

     console.log("descption 1: ", desc1);
     console.log("description 2: ", desc2);

     /***********************Get balance of Donor********************* */
     const balOfDOnor = await USDCInteract.connect(contractOwner).balanceOf(contractOwner.address);
    console.log("balance: ", Number(balOfDOnor).toString());

    /**************************Get usdc address********************* */
    const returnusdcaddr = await crwodfundInteract2.connect(wallet5).callStatic.DUSDC()
    console.log("address of susdc: ", returnusdcaddr)

    /**************************Approve crowdfund address************* */
    const approveAmt = ethers.utils.parseEther("500")
    await USDCInteract.connect(contractOwner).approve(crwodfundInteract1.address, approveAmt);
    await USDCInteract.connect(wallet6).approve(crwodfundInteract1.address, approveAmt);

    const approvalSuccess = await USDCInteract.connect(contractOwner).approve(crwodfundInteract2.address, approveAmt);
    console.log("approval successful: ", approvalSuccess)
    

    /*************************Donate********************* */
    //const dontateAmt =  ethers.utils.parseEther("5")
    const donate = await crwodfundInteract1.connect(contractOwner).donateFund("5");
    console.log("Donated sucessfullyy: ", donate)
    const donate3_1 = await crwodfundInteract1.connect(wallet6).donateFund("4");
    console.log("Donated sucessfullyy 5: ", donate3_1)

    const donate2 = await crwodfundInteract2.connect(contractOwner).donateFund("5");
    console.log("Donated sucessfullyy 2: ", donate2)


  

    /*****************all donors address********************** */
  
   const donors = await crwodfundInteract1.connect(wallet5).allDonorsAddress();
   console.log("DONORS for 1: ", donors)

   const donors2 = await crwodfundInteract2.connect(wallet5).allDonorsAddress();
   console.log("DONORS for 2: ", donors2)

    /*******************Amount Donated******************* */
   const amtDonated =  await crwodfundInteract1.connect(wallet5).amountDonated(contractOwner.address);
   console.log("Amount Donated", Number(amtDonated).toString());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
      console.error(error);
      process.exit(1);
});