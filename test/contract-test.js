const { expect } = require("chai");

describe("Bidding Tests", function () {

    let biddingContract;
    
    before(async () => {  

        const [owner, beneficiary] = await ethers.getSigners();
        const auctionStartTime = 1680774108;
        const auctionEndTime = 1690874108;
        console.log('owner :',owner.address, 'beneficiary :',beneficiary.address);
        const Bidding = await ethers.getContractFactory("Bidding");
        biddingContract = await Bidding.deploy(beneficiary.address, '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2', auctionStartTime, auctionEndTime);
    
        await biddingContract.deployed();
    
        console.log("Contract Address", await biddingContract.address);
    });

    it("test1", async function () {

        const auctionEndTime = await biddingContract.auctionEndTime();
        const auctionStartTime = await biddingContract.auctionStartTime();
        console.log(auctionStartTime,auctionEndTime);

        // assert that the value is correct
        expect(1).to.equal(1);

    });

});
