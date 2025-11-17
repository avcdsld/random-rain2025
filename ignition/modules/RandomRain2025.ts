import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("RandomRain2025Module", (m) => {
  // Deploy RandomRainGenerator
  const generator = m.contract("RandomRainGenerator");

  // Deploy BefungeInterpreter
  const interpreter = m.contract("BefungeInterpreter");

  // Deploy BefungeRenderer
  const renderer = m.contract("BefungeRenderer", [interpreter]);

  // Deploy RandomRain2025
  const randomRain = m.contract("RandomRain2025", [generator, interpreter, renderer]);

  return { generator, interpreter, renderer, randomRain };
});

