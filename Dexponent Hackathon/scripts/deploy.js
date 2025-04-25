const hre = require("hardhat");

async function main() {
  console.log("Deploying YieldVerifier contract...");

  const YieldVerifier = await hre.ethers.getContractFactory("YieldVerifier");
  const verifier = await YieldVerifier.deploy();

  await verifier.deployed();

  console.log(`YieldVerifier deployed to: ${verifier.address}`);

  // Verify contract on testnet explorer (if supported)
  if (process.env.ETHERSCAN_API_KEY) {
    console.log("Waiting for block confirmations...");
    await verifier.deployTransaction.wait(6);

    console.log("Verifying contract...");
    await hre.run("verify:verify", {
      address: verifier.address,
      constructorArguments: [],
    });
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });