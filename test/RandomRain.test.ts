const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RandomRain", function () {
  let generator: any;
  let interpreter: any;
  let renderer: any;
  let randomRain: any;
  let owner: any;

  before(async function () {
    [owner] = await ethers.getSigners();

    const RandomRainGenerator = await ethers.getContractFactory("RandomRainGenerator");
    generator = await RandomRainGenerator.deploy();
    await generator.waitForDeployment();

    const BefungeInterpreter = await ethers.getContractFactory("BefungeInterpreter");
    interpreter = await BefungeInterpreter.deploy();
    await interpreter.waitForDeployment();

    const BefungeRenderer = await ethers.getContractFactory("BefungeRenderer");
    renderer = await BefungeRenderer.deploy(await interpreter.getAddress());
    await renderer.waitForDeployment();

    const RandomRain = await ethers.getContractFactory("RandomRain");
    randomRain = await RandomRain.deploy(
      await generator.getAddress(),
      await interpreter.getAddress(),
      await renderer.getAddress()
    );
    await randomRain.waitForDeployment();
  });

  it("Should deploy RandomRain contract successfully", async function () {
    expect(await randomRain.getAddress()).to.be.ok;
    expect(await randomRain.name()).to.equal("Random Rain Poetry");
    expect(await randomRain.symbol()).to.equal("RAIN");
    expect(await randomRain.MAX_SUPPLY()).to.equal(1000);
  });

  it("Should mint NFT with seed successfully", async function () {
    const seed = 12345;
    const steps = 100;
    
    await randomRain.mintWithSeed(await owner.getAddress(), seed, steps);
    
    expect(await randomRain.ownerOf(1)).to.equal(await owner.getAddress());
    expect(await randomRain.totalSupply()).to.equal(1);
    expect(await randomRain.nextTokenId()).to.equal(2);
    
    const tokenSeed = await randomRain.getTokenSeed(1);
    expect(tokenSeed).to.equal(seed);
    
    const metadata = await randomRain.getTokenMetadata(1);
    expect(metadata.seed).to.equal(seed);
    expect(metadata.isGenerated).to.be.true;
    expect(metadata.svgData.length).to.be.greaterThan(0);
  });

  it("Should mint an NFT and retrieve its tokenURI", async function () {
    const seed = 12345;
    const steps = 100;

    // Mint the NFT with a higher gas limit
    await randomRain.mintWithSeed(await owner.getAddress(), seed, steps, { gasLimit: 8000000 });

    // Retrieve the tokenURI
    const tokenURI = await randomRain.tokenURI(1);
    console.log("Token URI:", tokenURI);

    // Basic checks
    expect(tokenURI).to.be.a('string');
    expect(tokenURI).to.include('data:application/json;base64,');
  });
});