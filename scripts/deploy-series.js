require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;

const DeployUtils = require("./lib/DeployUtils");
let deployUtils;

async function main() {
  deployUtils = new DeployUtils(ethers);
  require("./consoleLogAlert")();

  const chainId = await deployUtils.currentChainId();
  let [deployer] = await ethers.getSigners();

  const network = chainId === 137 ? "matic" : chainId === 5 ? "goerli" : chainId === 44787 ? "alfajores" : "localhost";

  console.log("Deploying contracts with the account:", deployer.address, "to", network);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const wl = await deployUtils.deploy("MagicSeries");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
