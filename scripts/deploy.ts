import { network } from "hardhat";

async function main() {
  const { viem } = await network.connect();

  console.log("Deploying contracts...");

  // Deploy RandomRainGenerator
  const generator = await viem.deployContract("RandomRainGenerator");
  console.log("RandomRainGenerator deployed to:", generator.address);

  // Deploy BefungeInterpreter
  const interpreter = await viem.deployContract("BefungeInterpreter");
  console.log("BefungeInterpreter deployed to:", interpreter.address);

  // Deploy BefungeRenderer
  const renderer = await viem.deployContract("BefungeRenderer", [interpreter.address]);
  console.log("BefungeRenderer deployed to:", renderer.address);

  // Deploy RandomRain
  const randomRain = await viem.deployContract("RandomRain", [
    generator.address,
    interpreter.address,
    renderer.address
  ]);
  console.log("RandomRain deployed to:", randomRain.address);

  console.log("All contracts deployed successfully!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
