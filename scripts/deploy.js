const { ethers } = require("hardhat");

async function main() {
  const Bidding = await ethers.getContractFactory("Bidding");
  const bidding = await Bidding.deploy('0x199d5ed7f45f4ee35960cf22eade2076e95b253f', '0x199d5ed7f45f4ee35960cf22eade2076e95b253f', 1670774108,1670874108);

  await bidding.deployed();

  console.log("Beneficiary Address", await bidding.beneficiary());
  console.log("Contract Address", await bidding.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
