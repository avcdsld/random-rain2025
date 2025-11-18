const { expect } = require("chai");
const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

describe("RandomRain2025", function () {
  let randomRain: any;
  let renderer: any;
  let owner: any;
  let user: any;

  before(async function () {
    [owner, user] = await ethers.getSigners();

    const fontBase64Path = path.join(__dirname, "..", "font", "DejaVuSansMono.base64");
    const fontBase64 = fs.readFileSync(fontBase64Path, "utf-8").trim();
    const befungeInterpreterJS = "";
    const befungeRendererJS = "";
    const randomRainGeneratorJS = "";

    const RandomRainRenderer = await ethers.getContractFactory("RandomRainRenderer");
    renderer = await RandomRainRenderer.deploy(
      fontBase64,
      befungeInterpreterJS,
      befungeRendererJS,
      randomRainGeneratorJS
    );
    await renderer.waitForDeployment();

    const RandomRain2025 = await ethers.getContractFactory("RandomRain2025");
    randomRain = await RandomRain2025.deploy(await renderer.getAddress());
    await randomRain.waitForDeployment();
  });

  it("Should deploy RandomRain2025 contract successfully", async function () {
    expect(await randomRain.getAddress()).to.be.ok;
    expect(await randomRain.name()).to.equal("Random Rain 2025");
    expect(await randomRain.symbol()).to.equal("RAIN");
    expect(await randomRain.MAX_SUPPLY()).to.equal(2);
    expect(await randomRain.totalSupply()).to.equal(0);
  });

  it("Should mint NFT successfully", async function () {
    await randomRain.mint(await owner.getAddress());
    
    expect(await randomRain.ownerOf(0)).to.equal(await owner.getAddress());
    expect(await randomRain.totalSupply()).to.equal(1);
    
    const seed = await randomRain.seeds(0);
    expect(seed).to.be.a("bigint");
    expect(seed).to.be.gt(0);
    
    const deterministic = await randomRain.deterministicMode(0);
    expect(deterministic).to.be.false;
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

  it("Should return JSON tokenURI", async function () {
    const tokenURI = await randomRain.tokenURI(0);
    
    expect(tokenURI).to.be.a("string");
    expect(tokenURI).to.include("data:application/json;base64,");
    
    const base64Data = tokenURI.replace("data:application/json;base64,", "");
    const json = Buffer.from(base64Data, "base64").toString("utf-8");
    const parsed = JSON.parse(json);
    expect(parsed.name).to.equal("Random Rain 2025");
    expect(parsed.image).to.include("data:image/svg+xml;base64,");
    expect(parsed.animation_url).to.include("data:text/html;base64,");
  });

  it("Should allow owner to set seed", async function () {
    const newSeed = 12345n;
    await randomRain.setSeed(0, newSeed);
    
    const seed = await randomRain.seeds(0);
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

  it("Should return preview JSON", async function () {
    const seed = 54321n;
    const previewJSON = await randomRain.preview(seed);
    
    expect(previewJSON).to.be.a("string");
    expect(previewJSON).to.include("data:application/json;base64,");
    
    const base64Data = previewJSON.replace("data:application/json;base64,", "");
    const json = Buffer.from(base64Data, "base64").toString("utf-8");
    const parsed = JSON.parse(json);
    expect(parsed.name).to.equal("Random Rain 2025 Preview");
    expect(parsed.image).to.include("data:image/svg+xml;base64,");
    expect(parsed.animation_url).to.include("data:text/html;base64,");
  });

  it("Should mint 2 NFTs and check their metadata", async function () {
    if (await randomRain.totalSupply() < 1) {
      await randomRain.mint(await owner.getAddress());
    }
    
    const seed0 = await randomRain.seeds(0);
    const deterministic0 = await randomRain.deterministicMode(0);
    const startWandering0 = await randomRain.startWandering(0);
    const tokenURI0 = await randomRain.tokenURI(0);
    
    console.log("\n=== Token 0 (startWandering: true) ===");
    console.log("Seed:", seed0.toString());
    console.log("Deterministic Mode:", deterministic0);
    console.log("Start Wandering:", startWandering0);
    console.log("TokenURI:");
    console.log(tokenURI0);
    
    expect(startWandering0).to.be.true;
    
    const base64Data0 = tokenURI0.replace("data:application/json;base64,", "");
    const json0 = Buffer.from(base64Data0, "base64").toString("utf-8");
    const parsed0 = JSON.parse(json0);
    expect(parsed0.name).to.equal("Random Rain 2025");
    expect(parsed0.image).to.include("data:image/svg+xml;base64,");
    expect(parsed0.animation_url).to.include("data:text/html;base64,");
    
    const startWanderingAttr0 = parsed0.attributes.find((attr: any) => attr.trait_type === "StartWandering");
    expect(startWanderingAttr0).to.exist;
    expect(startWanderingAttr0.value).to.equal("true");
    
    const htmlBase64Data0 = parsed0.animation_url.replace("data:text/html;base64,", "");
    const html0 = Buffer.from(htmlBase64Data0, "base64").toString("utf-8");
    expect(html0).to.include("<!DOCTYPE html>");
    
    if (await randomRain.totalSupply() < 2) {
      await randomRain.mint(await owner.getAddress());
    }
    
    await randomRain.setStartWandering(1, false);
    
    const seed1 = await randomRain.seeds(1);
    const deterministic1 = await randomRain.deterministicMode(1);
    const startWandering1 = await randomRain.startWandering(1);
    const tokenURI1 = await randomRain.tokenURI(1);
    
    console.log("\n=== Token 1 (startWandering: false) ===");
    console.log("Seed:", seed1.toString());
    console.log("Deterministic Mode:", deterministic1);
    console.log("Start Wandering:", startWandering1);
    console.log("TokenURI:");
    console.log(tokenURI1);
    
    expect(startWandering1).to.be.false;
    
    const base64Data1 = tokenURI1.replace("data:application/json;base64,", "");
    const json1 = Buffer.from(base64Data1, "base64").toString("utf-8");
    const parsed1 = JSON.parse(json1);
    expect(parsed1.name).to.equal("Random Rain 2025");
    expect(parsed1.image).to.include("data:image/svg+xml;base64,");
    expect(parsed1.animation_url).to.include("data:text/html;base64,");
    
    const startWanderingAttr1 = parsed1.attributes.find((attr: any) => attr.trait_type === "StartWandering");
    expect(startWanderingAttr1).to.exist;
    expect(startWanderingAttr1.value).to.equal("false");
    
    const htmlBase64Data1 = parsed1.animation_url.replace("data:text/html;base64,", "");
    const html1 = Buffer.from(htmlBase64Data1, "base64").toString("utf-8");
    expect(html1).to.include("<!DOCTYPE html>");
    
    expect(seed0).to.not.equal(seed1);
  });
});

