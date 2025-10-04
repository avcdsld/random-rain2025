import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("RandomRainModule", (m) => {
  // Deploy RandomRainGenerator
  const generator = m.contract("RandomRainGenerator");

  // Deploy BefungeInterpreter
  const interpreter = m.contract("BefungeInterpreter");

  // Deploy BefungeRenderer
  const renderer = m.contract("BefungeRenderer", [interpreter]);

  // Deploy RandomRain
  const randomRain = m.contract("RandomRain", [generator, interpreter, renderer]);

  return { generator, interpreter, renderer, randomRain };
});
