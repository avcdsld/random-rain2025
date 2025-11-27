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

  it("Should mint third NFT successfully", async function () {
    await randomRain.mint(await owner.getAddress());
    
    expect(await randomRain.ownerOf(2)).to.equal(await owner.getAddress());
    expect(await randomRain.totalSupply()).to.equal(3);
  });

  it("Should return JSON tokenURI", async function () {
    const tokenURI = await randomRain.tokenURI(0);
    
    expect(tokenURI).to.be.a("string");
    expect(tokenURI).to.include("data:application/json;base64,");
    
    const base64Data = tokenURI.replace("data:application/json;base64,", "");
    const json = Buffer.from(base64Data, "base64").toString("utf-8");
    const parsed = JSON.parse(json);
    expect(parsed.name).to.equal("Random Rain 2025 NFT");
    expect(parsed.image).to.include("data:image/svg+xml;base64,");
    expect(parsed.animation_url).to.include("data:text/html;base64,");
  });

  it("Should allow owner to set seed", async function () {
    const newSeed = 12345n;
    await randomRain.setSeed(0, newSeed);
    
    const seed = await randomRain.seeds(0);
    expect(seed).to.equal(newSeed);
  });

  it("Should allow non-owner to set seed", async function () {
    const newSeed = 99999n;
    await randomRain.connect(user).setSeed(0, newSeed);
    
    const seed = await randomRain.seeds(0);
    expect(seed).to.equal(newSeed);
  });

  it("Should allow owner to set deterministic mode", async function () {
    // tokenId 0が存在することを確認
    if (await randomRain.totalSupply() < 1) {
      await randomRain.mint(await owner.getAddress());
    }
    
    // 所有者であることを確認
    const ownerOf0 = await randomRain.ownerOf(0);
    expect(ownerOf0).to.equal(await owner.getAddress());
    
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
    expect(parsed0.name).to.equal("Random Rain 2025 NFT");
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
    expect(parsed1.name).to.equal("Random Rain 2025 NFT");
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

  it("Should compare deterministic mode true vs false", async function () {
    // テスト用の固定シードを設定
    const testSeed = 123456789n;
    const testWandering = true;

    // 出力ディレクトリを作成
    const outputDir = path.join(__dirname, "..", "output");
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    // deterministic mode = false の場合のSVGとHTMLを取得
    const svgFalse = await renderer.svg(testSeed, testWandering);
    const svgFalseBase64 = svgFalse.replace("data:image/svg+xml;base64,", "");
    const svgFalseContent = Buffer.from(svgFalseBase64, "base64").toString("utf-8");

    const htmlFalse = await renderer.html(testSeed, false, testWandering);
    const htmlFalseBase64 = htmlFalse.replace("data:text/html;base64,", "");
    const htmlFalseContent = Buffer.from(htmlFalseBase64, "base64").toString("utf-8");

    // deterministic mode = true の場合のSVGとHTMLを取得
    const svgTrue = await renderer.svg(testSeed, testWandering);
    const svgTrueBase64 = svgTrue.replace("data:image/svg+xml;base64,", "");
    const svgTrueContent = Buffer.from(svgTrueBase64, "base64").toString("utf-8");

    const htmlTrue = await renderer.html(testSeed, true, testWandering);
    const htmlTrueBase64 = htmlTrue.replace("data:text/html;base64,", "");
    const htmlTrueContent = Buffer.from(htmlTrueBase64, "base64").toString("utf-8");

    // ファイルに保存
    const svgFalsePath = path.join(outputDir, `deterministic-false-seed-${testSeed.toString()}.svg`);
    const htmlFalsePath = path.join(outputDir, `deterministic-false-seed-${testSeed.toString()}.html`);
    const svgTruePath = path.join(outputDir, `deterministic-true-seed-${testSeed.toString()}.svg`);
    const htmlTruePath = path.join(outputDir, `deterministic-true-seed-${testSeed.toString()}.html`);

    fs.writeFileSync(svgFalsePath, svgFalseContent, "utf-8");
    fs.writeFileSync(htmlFalsePath, htmlFalseContent, "utf-8");
    fs.writeFileSync(svgTruePath, svgTrueContent, "utf-8");
    fs.writeFileSync(htmlTruePath, htmlTrueContent, "utf-8");

    console.log("\n=== Files saved ===");
    console.log("SVG (deterministic=false):", svgFalsePath);
    console.log("HTML (deterministic=false):", htmlFalsePath);
    console.log("SVG (deterministic=true):", svgTruePath);
    console.log("HTML (deterministic=true):", htmlTruePath);

    // SVGとHTMLが生成されていることを確認
    expect(svgFalseContent).to.include("<svg");
    expect(svgTrueContent).to.include("<svg");
    expect(htmlFalseContent).to.include("<!DOCTYPE html>");
    expect(htmlTrueContent).to.include("<!DOCTYPE html>");

    // deterministic mode = false の場合、DM=false が含まれていることを確認
    expect(htmlFalseContent).to.include("const DM=false;");
    expect(htmlFalseContent).to.not.include("const DM=true;");

    // deterministic mode = true の場合、DM=true が含まれていることを確認
    expect(htmlTrueContent).to.include("const DM=true;");
    expect(htmlTrueContent).to.not.include("const DM=false;");

    // 両方とも同じシード値が含まれていることを確認
    expect(htmlFalseContent).to.include(`const IS=BigInt("${testSeed.toString()}");`);
    expect(htmlTrueContent).to.include(`const IS=BigInt("${testSeed.toString()}");`);

    // deterministic mode = false の場合、Date.now()が使われることを確認
    // 648行目のコード: cs=DM?IS+BigInt(rc)*RO:BigInt(Math.floor(Date.now()/1000));
    // false側のコードパスが含まれていることを確認
    expect(htmlFalseContent).to.include("BigInt(Math.floor(Date.now()/1000))");

    // deterministic mode = true の場合、IS+BigInt(rc)*ROが使われることを確認
    expect(htmlTrueContent).to.include("IS+BigInt(rc)*RO");
    // 注: 三項演算子のfalse側にDate.now()が文字列として含まれるが、実行されない
    // 実際のコードパスを確認するため、cs=DM?IS+BigInt(rc)*RO:...のパターンを確認
    expect(htmlTrueContent).to.match(/cs=DM\?IS\+BigInt\(rc\)\*RO:/);

    console.log("\n=== Deterministic Mode Comparison ===");
    console.log("Seed:", testSeed.toString());
    console.log("Deterministic Mode = false:");
    console.log("  - Contains DM=false:", htmlFalseContent.includes("const DM=false;"));
    console.log("  - Uses Date.now():", htmlFalseContent.includes("Date.now()"));
    console.log("Deterministic Mode = true:");
    console.log("  - Contains DM=true:", htmlTrueContent.includes("const DM=true;"));
    console.log("  - Uses IS+BigInt(rc)*RO:", htmlTrueContent.includes("IS+BigInt(rc)*RO"));
  });

  it("Should generate consistent HTML with deterministic mode true", async function () {
    // 同じシードで2回HTMLを生成し、deterministic mode = true の場合は同じ結果になることを確認
    const testSeed = 987654321n;
    const testWandering = false;

    const html1 = await renderer.html(testSeed, true, testWandering);
    const html2 = await renderer.html(testSeed, true, testWandering);

    // deterministic mode = true の場合、同じシードなら同じHTMLが生成される
    expect(html1).to.equal(html2);

    const html1Base64 = html1.replace("data:text/html;base64,", "");
    const html1Content = Buffer.from(html1Base64, "base64").toString("utf-8");
    const html2Base64 = html2.replace("data:text/html;base64,", "");
    const html2Content = Buffer.from(html2Base64, "base64").toString("utf-8");

    // JavaScriptコードも同じであることを確認
    expect(html1Content).to.equal(html2Content);

    console.log("\n=== Deterministic Mode Consistency Test ===");
    console.log("Seed:", testSeed.toString());
    console.log("Deterministic Mode = true");
    console.log("  - First HTML length:", html1Content.length);
    console.log("  - Second HTML length:", html2Content.length);
    console.log("  - HTMLs are identical:", html1Content === html2Content);
  });

  it("Should generate different HTML with deterministic mode false", async function () {
    // deterministic mode = false の場合、時間に依存するため異なる結果になる可能性がある
    // ただし、HTMLの構造自体は同じであることを確認
    const testSeed = 555555555n;
    const testWandering = true;

    const html1 = await renderer.html(testSeed, false, testWandering);
    const html2 = await renderer.html(testSeed, false, testWandering);

    const html1Base64 = html1.replace("data:text/html;base64,", "");
    const html1Content = Buffer.from(html1Base64, "base64").toString("utf-8");
    const html2Base64 = html2.replace("data:text/html;base64,", "");
    const html2Content = Buffer.from(html2Base64, "base64").toString("utf-8");

    // 両方ともDM=falseが含まれていることを確認
    expect(html1Content).to.include("const DM=false;");
    expect(html2Content).to.include("const DM=false;");

    // 両方ともDate.now()が使われていることを確認
    expect(html1Content).to.include("Date.now()");
    expect(html2Content).to.include("Date.now()");

    console.log("\n=== Non-Deterministic Mode Test ===");
    console.log("Seed:", testSeed.toString());
    console.log("Deterministic Mode = false");
    console.log("  - First HTML contains DM=false:", html1Content.includes("const DM=false;"));
    console.log("  - Second HTML contains DM=false:", html2Content.includes("const DM=false;"));
    console.log("  - Both use Date.now():", html1Content.includes("Date.now()") && html2Content.includes("Date.now()"));
  });

  it("Should correctly set deterministic mode in tokenURI", async function () {
    // tokenId 0を使用（既にmintされている前提）
    if (await randomRain.totalSupply() < 1) {
      await randomRain.mint(await owner.getAddress());
    }

    const testSeed = 111111111n;
    await randomRain.setSeed(0, testSeed);

    // deterministic mode = false の場合
    await randomRain.setDeterministicMode(0, false);
    const tokenURIFalse = await randomRain.tokenURI(0);
    const jsonFalseBase64 = tokenURIFalse.replace("data:application/json;base64,", "");
    const jsonFalse = Buffer.from(jsonFalseBase64, "base64").toString("utf-8");
    const parsedFalse = JSON.parse(jsonFalse);

    const htmlFalseBase64 = parsedFalse.animation_url.replace("data:text/html;base64,", "");
    const htmlFalseContent = Buffer.from(htmlFalseBase64, "base64").toString("utf-8");

    // deterministic mode = true の場合
    await randomRain.setDeterministicMode(0, true);
    const tokenURITrue = await randomRain.tokenURI(0);
    const jsonTrueBase64 = tokenURITrue.replace("data:application/json;base64,", "");
    const jsonTrue = Buffer.from(jsonTrueBase64, "base64").toString("utf-8");
    const parsedTrue = JSON.parse(jsonTrue);

    const htmlTrueBase64 = parsedTrue.animation_url.replace("data:text/html;base64,", "");
    const htmlTrueContent = Buffer.from(htmlTrueBase64, "base64").toString("utf-8");

    // 属性が正しく設定されていることを確認
    const deterministicAttrFalse = parsedFalse.attributes.find((attr: any) => attr.trait_type === "Deterministic");
    expect(deterministicAttrFalse).to.exist;
    expect(deterministicAttrFalse.value).to.equal("false");

    const deterministicAttrTrue = parsedTrue.attributes.find((attr: any) => attr.trait_type === "Deterministic");
    expect(deterministicAttrTrue).to.exist;
    expect(deterministicAttrTrue.value).to.equal("true");

    // HTML内のJavaScriptコードが正しく設定されていることを確認
    expect(htmlFalseContent).to.include("const DM=false;");
    expect(htmlTrueContent).to.include("const DM=true;");

    console.log("\n=== TokenURI Deterministic Mode Test ===");
    console.log("Seed:", testSeed.toString());
    console.log("Deterministic Mode = false:");
    console.log("  - Attribute value:", deterministicAttrFalse.value);
    console.log("  - HTML contains DM=false:", htmlFalseContent.includes("const DM=false;"));
    console.log("Deterministic Mode = true:");
    console.log("  - Attribute value:", deterministicAttrTrue.value);
    console.log("  - HTML contains DM=true:", htmlTrueContent.includes("const DM=true;"));
  });
});

