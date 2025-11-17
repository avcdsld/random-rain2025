const { expect } = require("chai");
const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

describe("RandomRainRenderer SVG Generation", function () {
  let renderer: any;
  let owner: any;

  before(async function () {
    [owner] = await ethers.getSigners();

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
  });

  it("Should generate SVG with exactly 80 consecutive 'v' characters in the first line", async function () {
    // Generate source code with seed 0 (wandering mode)
    const seed = 0n;
    const svgData = await renderer.svg(seed);
    
    expect(svgData).to.include("data:image/svg+xml;base64,");
    
    // Decode base64
    const base64Data = svgData.replace("data:image/svg+xml;base64,", "");
    const svgContent = Buffer.from(base64Data, "base64").toString("utf-8");
    
    // Write SVG to file for inspection
    fs.writeFileSync(path.join(__dirname, "..", "test_output.svg"), svgContent);
    console.log("\nSVG written to test_output.svg for inspection");
    
    // Create a string of 80 consecutive 'v' characters
    const eightyV = "v".repeat(80);
    
    // Check if the SVG contains 80 consecutive 'v' characters
    // We need to check in the text content, ignoring HTML tags
    // First, extract text content from the first code line
    const textTagRegex = /<text[^>]*>([\s\S]*?)<\/text>/g;
    const matches = [...svgContent.matchAll(textTagRegex)];
    
    // Skip the first match (Step line) and get the second match (first code line)
    if (matches.length > 1) {
      const firstCodeLineContent = matches[1][1];
      
      // Remove HTML tags to get clean text
      const cleanText = firstCodeLineContent.replace(/<[^>]*>/g, "");
      
      console.log("\n=== First Code Line Analysis ===");
      console.log("Clean text (first 100 chars):", cleanText.substring(0, 100));
      console.log("Clean text length:", cleanText.length);
      
      // Check if 80 consecutive 'v' characters exist in the clean text
      const hasEightyV = cleanText.includes(eightyV);
      
      // Also count the maximum consecutive 'v' characters
      const maxConsecutiveV = Math.max(...(cleanText.match(/v+/g) || []).map(s => s.length));
      
      console.log("80 consecutive 'v' found:", hasEightyV);
      console.log("Maximum consecutive 'v':", maxConsecutiveV);
      
      expect(hasEightyV, "First line should contain exactly 80 consecutive 'v' characters").to.be.true;
      expect(maxConsecutiveV, "Maximum consecutive 'v' should be 80").to.equal(80);
    } else {
      throw new Error("Could not find code lines in SVG");
    }
  });
});

