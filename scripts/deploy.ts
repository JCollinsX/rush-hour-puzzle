import { ethers } from "hardhat";

async function main() {
  const rushHourSolver = await ethers.deployContract("RushHourSolver");

  await rushHourSolver.waitForDeployment();

  console.log(
    `RushHourSolver deployed to ${rushHourSolver.target}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
