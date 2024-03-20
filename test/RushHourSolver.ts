import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { ethers } from "hardhat";
import { IRushHourSolver } from "../typechain-types";

describe("RushHourSolver", function () {
  async function deployRushHourSolverFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const RushHourSolver = await ethers.getContractFactory("RushHourSolver");
    const rushHourSolver = await RushHourSolver.deploy();

    return { rushHourSolver, owner, otherAccount };
  }

  function printOutputSteps(output: IRushHourSolver.StepStructOutput[]) {
    if (output.length > 0) {
      output.map((step) => {
        console.log(`Car #${step.carId} => ${Number(step.direction) === 0 ? 'Up' : Number(step.direction) === 1 ? 'Right' : Number(step.direction) === 2 ? 'Down' : 'Left'}`)
      })
    } else {
      console.log("No Solution Found")
    }
  }

  it("Test Case 1", async function () {
    const { rushHourSolver } = await loadFixture(deployRushHourSolverFixture);

    const input = [
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 1, 1, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
    ]
    const output = await rushHourSolver.solve(input)
    printOutputSteps(output);
  });

  it("Test Case 2", async function () {
    const { rushHourSolver } = await loadFixture(deployRushHourSolverFixture);

    const input = [
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [1, 1, 2, 2, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
    ]
    const output = await rushHourSolver.solve(input)
    printOutputSteps(output);
  });

  it("Test Case 3", async function () {
    const { rushHourSolver } = await loadFixture(deployRushHourSolverFixture);

    const input = [
      [0, 0, 0, 0, 0, 0],
      [0, 0, 2, 0, 0, 0],
      [1, 1, 2, 3, 0, 0],
      [0, 0, 0, 3, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
    ]
    const output = await rushHourSolver.solve(input)
    printOutputSteps(output);
  });

  it("Test Case 4", async function () {
    const { rushHourSolver } = await loadFixture(deployRushHourSolverFixture);

    const input = [
      [2, 2, 2, 0, 0, 3],
      [0, 0, 4, 0, 0, 3],
      [1, 1, 4, 0, 0, 3],
      [5, 0, 4, 0, 6, 6],
      [5, 0, 0, 0, 7, 0],
      [8, 8, 8, 0, 7, 0]
    ]
    const output = await rushHourSolver.solve(input, {
      gasLimit: 600000000
    })
    printOutputSteps(output);
  }).timeout(6000000);
});
