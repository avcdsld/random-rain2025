const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RandomRain", function () {
  let randomRain: any;
  let owner: any;
  let user: any;

  before(async function () {
    [owner, user] = await ethers.getSigners();

    const RandomRain = await ethers.getContractFactory("RandomRain");
    randomRain = await RandomRain.deploy();
    await randomRain.waitForDeployment();
  });

  it("Should deploy RandomRain contract successfully", async function () {
    expect(await randomRain.getAddress()).to.be.ok;
    expect(await randomRain.name()).to.equal("Random Rain");
    expect(await randomRain.symbol()).to.equal("RAIN");
    expect(await randomRain.MAX_SUPPLY()).to.equal(2);
    expect(await randomRain.totalSupply()).to.equal(0);
  });

  it("Should mint NFT successfully", async function () {
    await randomRain.mint(await owner.getAddress());
    
    expect(await randomRain.ownerOf(0)).to.equal(await owner.getAddress());
    expect(await randomRain.totalSupply()).to.equal(1);
    
    const seed = await randomRain.tokenSeeds(0);
    expect(seed).to.be.a("bigint");
    expect(seed).to.be.gt(0);
    
    const deterministic = await randomRain.deterministicMode(0);
    expect(deterministic).to.be.true;
  });

  it("Should mint second NFT", async function () {
    await randomRain.mint(await owner.getAddress());
    
    expect(await randomRain.ownerOf(1)).to.equal(await owner.getAddress());
    expect(await randomRain.totalSupply()).to.equal(2);
  });

  it("Should fail to mint third NFT (exceeds max supply)", async function () {
    await expect(
      randomRain.mint(await owner.getAddress())
    ).to.be.revertedWith("exceeds max supply");
  });

  it("Should return HTML tokenURI", async function () {
    const tokenURI = await randomRain.tokenURI(0);
    
    expect(tokenURI).to.be.a("string");
    expect(tokenURI).to.include("data:text/html;base64,");
    
    const base64Data = tokenURI.replace("data:text/html;base64,", "");
    const html = Buffer.from(base64Data, "base64").toString("utf-8");
    expect(html).to.include("<!DOCTYPE html>");
  });

  it("Should allow owner to set seed", async function () {
    const newSeed = 12345n;
    await randomRain.setSeed(0, newSeed);
    
    const seed = await randomRain.tokenSeeds(0);
    expect(seed).to.equal(newSeed);
  });

  it("Should not allow non-owner to set seed", async function () {
    await expect(
      randomRain.connect(user).setSeed(0, 99999n)
    ).to.be.revertedWith("not owner");
  });

  it("Should allow owner to set deterministic mode", async function () {
    await randomRain.setDeterministicMode(0, false);
    
    const deterministic = await randomRain.deterministicMode(0);
    expect(deterministic).to.be.false;
    
    await randomRain.setDeterministicMode(0, true);
    const deterministic2 = await randomRain.deterministicMode(0);
    expect(deterministic2).to.be.true;
  });

  it("Should return preview HTML", async function () {
    const seed = 54321n;
    const previewHTML = await randomRain.preview(seed);
    
    expect(previewHTML).to.be.a("string");
    expect(previewHTML).to.include("data:text/html;base64,");
    
    const base64Data = previewHTML.replace("data:text/html;base64,", "");
    const html = Buffer.from(base64Data, "base64").toString("utf-8");
    expect(html).to.include("INITIAL_SEED = 54321");
  });

  it("Should mint 2 NFTs and check their metadata", async function () {
    await randomRain.mint(await owner.getAddress());
    await randomRain.mint(await owner.getAddress());
    
    expect(await randomRain.totalSupply()).to.equal(2);
    
    const seed0 = await randomRain.tokenSeeds(0);
    const deterministic0 = await randomRain.deterministicMode(0);
    const tokenURI0 = await randomRain.tokenURI(0);
    
    console.log("\n=== Token 0 ===");
    console.log("Seed:", seed0.toString());
    console.log("Deterministic Mode:", deterministic0);
    console.log("TokenURI:");
    console.log(tokenURI0);
    
    const base64Data0 = tokenURI0.replace("data:text/html;base64,", "");
    const html0 = Buffer.from(base64Data0, "base64").toString("utf-8");
    expect(html0).to.include("<!DOCTYPE html>");
    expect(html0).to.include(`INITIAL_SEED = ${seed0.toString()}`);
    expect(html0).to.include(`DETERMINISTIC_MODE = ${deterministic0}`);
    
    const seed1 = await randomRain.tokenSeeds(1);
    const deterministic1 = await randomRain.deterministicMode(1);
    const tokenURI1 = await randomRain.tokenURI(1);
    
    console.log("\n=== Token 1 ===");
    console.log("Seed:", seed1.toString());
    console.log("Deterministic Mode:", deterministic1);
    console.log("TokenURI:");
    console.log(tokenURI1);
    
    const base64Data1 = tokenURI1.replace("data:text/html;base64,", "");
    const html1 = Buffer.from(base64Data1, "base64").toString("utf-8");
    expect(html1).to.include("<!DOCTYPE html>");
    expect(html1).to.include(`INITIAL_SEED = ${seed1.toString()}`);
    expect(html1).to.include(`DETERMINISTIC_MODE = ${deterministic1}`);
    
    expect(seed0).to.not.equal(seed1);
    
    expect(html0).to.include("BefungeInterpreter");
    expect(html0).to.include("generateRandomRain");
    expect(html0).to.include("runBefunge");
    expect(html1).to.include("BefungeInterpreter");
    expect(html1).to.include("generateRandomRain");
    expect(html1).to.include("runBefunge");
  });
});
