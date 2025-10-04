const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RandomRainGenerator", function () {
  let randomRainGenerator: any;

  before(async function () {
    const RandomRainGenerator = await ethers.getContractFactory("RandomRainGenerator");
    randomRainGenerator = await RandomRainGenerator.deploy();
    await randomRainGenerator.waitForDeployment();
  });

  it("Should deploy RandomRainGenerator successfully", async function () {
    expect(await randomRainGenerator.getAddress()).to.be.ok;
  });

  it("Should generate wandering rain program for even seed", async function () {
    const seed = 42; // Even number
    const programType = await randomRainGenerator.getProgramType(seed);
    expect(programType).to.equal("wandering");
    
    const sourceCode = await randomRainGenerator.generateFromSeed(seed);
    expect(sourceCode.length).to.be.greaterThan(0);
    expect(sourceCode).to.include("v");
    expect(sourceCode).to.include("Rain.");
  });

  it("Should generate straight rain program for odd seed", async function () {
    const seed = 43; // Odd number
    const programType = await randomRainGenerator.getProgramType(seed);
    expect(programType).to.equal("straight");
    
    const sourceCode = await randomRainGenerator.generateFromSeed(seed);
    expect(sourceCode.length).to.be.greaterThan(0);
    expect(sourceCode).to.include("v");
    expect(sourceCode).to.include("Rain.");
  });

  it("Should generate consistent program data for same seed", async function () {
    const seed = 12345;
    const programData1 = await randomRainGenerator.generateProgramDataFromSeed(seed);
    const programData2 = await randomRainGenerator.generateProgramDataFromSeed(seed);
    
    expect(programData1.length).to.equal(programData2.length);
    expect(programData1.length).to.equal(2160); // 80 * 27
    
    for (let i = 0; i < programData1.length; i++) {
      expect(programData1[i]).to.equal(programData2[i]);
    }
  });

  it("Should generate different program data for different seeds", async function () {
    const programData1 = await randomRainGenerator.generateProgramDataFromSeed(12345);
    const programData2 = await randomRainGenerator.generateProgramDataFromSeed(54321);
    
    let different = false;
    for (let i = 0; i < Math.min(programData1.length, programData2.length); i++) {
      if (programData1[i] !== programData2[i]) {
        different = true;
        break;
      }
    }
    expect(different).to.be.true;
  });
});