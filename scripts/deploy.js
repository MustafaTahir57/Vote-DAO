const { ethers } = require("hardhat");

async function main() {
  // Deploy the DAO contract
  const DAO = await ethers.getContractFactory("DAO");
  const dao = await DAO.deploy();

  // Wait for the contract to be deployed
  await dao.deployed();

  // Log deployment details
  console.log(`DAO contract deployed at address: ${dao.address}`);
}

// Execute the deployment script
main().then(() => process.exit(0)).catch(error => {
  console.error(error);
  process.exit(1);
});
