import * as fs from "fs";
import * as path from "path";

const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying contracts...");

  // Read font base64 file
  const fontBase64Path = path.join(__dirname, "..", "font", "DejaVuSansMono.base64");
  const fontBase64 = fs.readFileSync(fontBase64Path, "utf-8").trim();

  // Deploy RandomRainRenderer
  const RandomRainRenderer = await ethers.getContractFactory("RandomRainRenderer");
  const renderer = await RandomRainRenderer.deploy(
    fontBase64,
    "", // befungeInterpreterJS
    "", // befungeRendererJS
    ""  // randomRainGeneratorJS
  );
  await renderer.waitForDeployment();
  const rendererAddress = await renderer.getAddress();
  console.log("RandomRainRenderer deployed to:", rendererAddress);

  // Deploy RandomRain2025
  const RandomRain2025 = await ethers.getContractFactory("RandomRain2025");
  const randomRain = await RandomRain2025.deploy(rendererAddress);
  await randomRain.waitForDeployment();
  const randomRainAddress = await randomRain.getAddress();
  console.log("RandomRain2025 deployed to:", randomRainAddress);

  console.log("All contracts deployed successfully!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
