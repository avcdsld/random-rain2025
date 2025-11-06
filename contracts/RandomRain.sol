// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract RandomRain is ERC721, Ownable {
    using Strings for uint256;
    
    uint256 public totalSupply;
    uint256 public constant MAX_SUPPLY = 2;

    mapping(uint256 => uint256) public tokenSeeds;
    mapping(uint256 => bool) public deterministicMode;
    
    constructor() ERC721("Random Rain", "RAIN") Ownable(msg.sender) {}
    
    function mint(address to) public onlyOwner {
        require(totalSupply < MAX_SUPPLY, "exceeds max supply");
        _safeMint(to, totalSupply);

        uint256 seed = uint256(keccak256(abi.encodePacked("rain", block.timestamp)));
        tokenSeeds[totalSupply] = seed;
        deterministicMode[totalSupply] = true;

        totalSupply++;
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "not exists");
        return _generateHTML(tokenId, tokenSeeds[tokenId], deterministicMode[tokenId]);
    }
    
    function setSeed(uint256 tokenId, uint256 seed) external {
        require(_ownerOf(tokenId) == msg.sender, "not owner");
        tokenSeeds[tokenId] = seed;
    }
    
    function preview(uint256 seed) external pure returns (string memory) {
        return _generateHTML(0, seed, true);
    }
    
    function setDeterministicMode(uint256 tokenId, bool _deterministic) external {
        require(_ownerOf(tokenId) == msg.sender, "not owner");
        deterministicMode[tokenId] = _deterministic;
    }
    
    function _generateHTML(uint256 /* tokenId */, uint256 seed, bool deterministic) internal pure returns (string memory) {
        string memory fontCSS = _getFontCSS();
        string memory befungeJS = _getBefungeInterpreterJS();
        string memory generatorJS = _getRandomRainGeneratorJS();
        string memory mainJS = _getMainJS(seed, deterministic);
        
        string memory html = string.concat(
            '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Befunge</title><style>',
            '@font-face { font-family: "DejaVu Sans Mono"; src: url("data:font/truetype;charset=utf-8;base64,',
            fontCSS,
            '"); font-weight: normal; font-style: normal; }',
            '@font-face { font-family: "DejaVu Sans Mono"; src: url("data:font/truetype;charset=utf-8;base64,',
            fontCSS,
            '"); font-weight: bold; font-style: normal; }',
            'body { margin: 0; padding: 0; background: #000; display: flex; justify-content: center; align-items: center; min-height: 100vh; overflow: hidden; }',
            'pre { display: block; font-family: "DejaVu Sans Mono", monospace; font-weight: normal; font-size: 12px; color: #fff; background: #000; margin: 0; padding: 3px 12px 8px 12px; white-space: pre; overflow: auto; max-width: 100vw; max-height: 100vh; line-height: 1.2; box-sizing: border-box; }',
            '.ip-highlight { background: #fff; color: #000; }',
            '</style></head><body><pre id="canvas"></pre><script>',
            befungeJS,
            generatorJS,
            mainJS,
            '</script></body></html>'
        );
        
        return string.concat("data:text/html;base64,", Base64.encode(bytes(html)));
    }
    
    function _getFontCSS() internal pure returns (string memory) {
        // フォントのBase64データは省略（実際のデプロイ時には必要）
        // ここでは空文字を返す（フォントは別途読み込むか、インラインで埋め込む）
        return '';
    }
    
    function _getBefungeInterpreterJS() internal pure returns (string memory) {
        return string.concat(
            'class BefungeInterpreter {',
            'constructor(w, h, rng) {',
            'this.w = w; this.h = h;',
            'this.rng = rng;',
            'this.p = Array(h).fill().map(() => Array(w).fill(\' \'));',
            'this.x = this.y = this.dx = this.dy = this.stepCount = 0;',
            'this.dx = 1; this.stack = []; this.out = \'\'; this.run = true;',
            'this.str = false;',
            '}',
            'load(src) {',
            'src.split(\'\\n\').forEach((line, y) => {',
            '[...line].forEach((c, x) => this.p[y] && (this.p[y][x] = c));',
            '});',
            '}',
            'pop() { return this.stack.pop() || 0; }',
            'step() {',
            'const c = this.p[this.y][this.x];',
            'if (this.str) {',
            'if (c === \'"\') this.str = false;',
            'else this.stack.push(c.charCodeAt(0));',
            '} else {',
            'const ops = {',
            '\'>\': () => [this.dx, this.dy] = [1, 0],',
            '\'<\': () => [this.dx, this.dy] = [-1, 0],',
            '\'^\': () => [this.dx, this.dy] = [0, -1],',
            '\'v\': () => [this.dx, this.dy] = [0, 1],',
            '\'?\': () => { const r = this.rng ? this.rng.next() : Math.random(); [this.dx, this.dy] = [[1, 0], [-1, 0], [0, 1], [0, -1]][r < 0.3 ? 0 : r < 0.5 ? 1 : r < 0.8 ? 2 : 3]; },',
            '\'_\': () => [this.dx, this.dy] = [this.pop() ? -1 : 1, 0],',
            '\'|\': () => [this.dx, this.dy] = [0, this.pop() ? -1 : 1],',
            '\'"\': () => this.str = true,',
            '\'+\': () => this.stack.push(this.pop() + this.pop()),',
            '\'-\': () => { const [a,b] = [this.pop(), this.pop()]; this.stack.push(b - a); },',
            '\'*\': () => this.stack.push(this.pop() * this.pop()),',
            '\'/\': () => { const [a,b] = [this.pop(), this.pop()]; this.stack.push(a ? Math.floor(b/a) : 0); },',
            '\'%\': () => { const [a,b] = [this.pop(), this.pop()]; this.stack.push(a ? b%a : 0); },',
            '\'!\': () => this.stack.push(this.pop() ? 0 : 1),',
            '\'`\': () => { const [a,b] = [this.pop(), this.pop()]; this.stack.push(b > a ? 1 : 0); },',
            '\':\': () => this.stack.push(this.stack[this.stack.length-1] || 0),',
            '\'\\\\\': () => { const [a,b] = [this.pop(), this.pop()]; this.stack.push(a, b); },',
            '\'$\': () => this.pop(),',
            '\'.\': () => this.out += this.pop() + \' \',',
            '\',\': () => this.out += String.fromCharCode(this.pop()),',
            '\'#\': () => this.move(),',
            '\'g\': () => { const [y,x] = [this.pop(), this.pop()]; this.stack.push(this.p[y%this.h][x%this.w].charCodeAt(0)); },',
            '\'p\': () => { const [y,x,v] = [this.pop(), this.pop(), this.pop()]; this.p[y%this.h][x%this.w] = String.fromCharCode(v%256); },',
            '\'&\': () => this.stack.push(0),',
            '\'~\': () => this.stack.push(0),',
            '\'@\': () => this.run = false',
            '};',
            'if (/\\d/.test(c)) this.stack.push(+c);',
            'else if (ops[c]) ops[c]();',
            '}',
            'this.move();',
            'this.stepCount++;',
            'return this.run;',
            '}',
            'move() {',
            'this.x = (this.x + this.dx) % this.w;',
            'this.y = (this.y + this.dy) % this.h;',
            'if (this.x < 0) this.x += this.w;',
            'if (this.y < 0) this.y += this.h;',
            '}',
            '}'
        );
    }
    
    function _getRandomRainGeneratorJS() internal pure returns (string memory) {
        return string.concat(
            'function hashSeed(seed) {',
            'let hash = 0;',
            'const str = seed.toString();',
            'for (let i = 0; i < str.length; i++) {',
            'const char = str.charCodeAt(i);',
            'hash = ((hash << 5) - hash) + char;',
            'hash = hash & hash;',
            '}',
            'return hash >>> 0;',
            '}',
            'class SeededRandom {',
            'constructor(seed) {',
            'this.seed = hashSeed(seed);',
            '}',
            'next() {',
            'this.seed = (this.seed * 1103515245 + 12345) & 0x7fffffff;',
            'return this.seed / 2147483648;',
            '}',
            'int(min, max) {',
            'return Math.floor(this.next() * (max - min + 1)) + min;',
            '}',
            'sample(arr, count) {',
            'const result = [];',
            'const indices = Array.from({length: arr.length}, (_, i) => i);',
            'for (let i = 0; i < count && indices.length > 0; i++) {',
            'const idx = this.int(0, indices.length - 1);',
            'result.push(arr[indices[idx]]);',
            'indices.splice(idx, 1);',
            '}',
            'return result;',
            '}',
            '}',
            'function generateWandering(seed) {',
            'const WIDTH = 80;',
            'const rng = new SeededRandom(seed);',
            'const lines = [];',
            'lines.push(\'v\'.repeat(WIDTH));',
            'for (let i = 1; i < 22; i++) {',
            'const row = Array(WIDTH).fill(\' \');',
            'const numQ = rng.int(60, 80);',
            'const qPositions = rng.sample(Array.from({length: WIDTH}, (_, i) => i), numQ);',
            'qPositions.forEach(pos => row[pos] = \'?\');',
            'lines.push(row.join(\'\'));',
            '}',
            'const row1 = Array(36).fill(\' \');',
            'const numQ1 = rng.int(27, 36);',
            'const qPos1 = rng.sample(Array.from({length: 36}, (_, i) => i), numQ1);',
            'qPos1.forEach(pos => row1[pos] = \'?\');',
            'const row2 = Array(35).fill(\' \');',
            'const numQ2 = rng.int(25, 34);',
            'const qPos2 = rng.sample(Array.from({length: 34}, (_, i) => i), numQ2);',
            'qPos2.forEach(pos => row2[pos] = \'?\');',
            'lines.push(row1.join(\'\') + \'^\'.repeat(9) + row2.join(\'\'));',
            'lines.push(\'^\'.repeat(36) + \'v"Rain."0<\' + \'^\'.repeat(WIDTH - 46));',
            'lines.push(\' \'.repeat(36) + \'<,_@#:\' + \' \'.repeat(WIDTH - 42));',
            'return lines.join(\'\\n\');',
            '}',
            'function generateStraight(seed) {',
            'const WIDTH = 80;',
            'const rng = new SeededRandom(seed);',
            'const lines = [];',
            'lines.push(\'v\'.repeat(WIDTH));',
            'for (let i = 1; i < 22; i++) {',
            'const row = Array(WIDTH).fill(\' \');',
            'const qPositions = rng.sample(Array.from({length: WIDTH}, (_, i) => i), 2);',
            'qPositions.forEach(pos => row[pos] = \'?\');',
            'lines.push(row.join(\'\'));',
            '}',
            'lines.push(\' \'.repeat(37) + \'>>>>>>>>v\' + \' \'.repeat(WIDTH - 46));',
            'lines.push(\'v\'.repeat(38) + \'"Rain."<\' + \'v\'.repeat(WIDTH - 46));',
            'lines.push(\'?\'.repeat(36) + \'<>,#$:_@ >\' + \'?\'.repeat(WIDTH - 46));',
            'return lines.join(\'\\n\');',
            '}',
            'function generateRandomRain(seed, runCount) {',
            'const isWandering = (runCount % 2 === 0);',
            'return isWandering ? generateWandering(seed + runCount) : generateStraight(seed + runCount);',
            '}'
        );
    }
    
    function _getMainJS(uint256 seed, bool deterministic) internal pure returns (string memory) {
        string memory seedStr = seed.toString();
        string memory deterministicStr = deterministic ? "true" : "false";
        
        return string.concat(
            'class BefungeRenderer {',
            'constructor(id, w, h) {',
            'this.elem = document.getElementById(id);',
            'this.w = w; this.h = h;',
            'this.updateFontSize();',
            '}',
            'updateFontSize() {',
            'const baseFontSize = 12;',
            'const charWidth = baseFontSize * 0.6;',
            'const lineHeightRatio = 1.2;',
            'const baseLineHeight = baseFontSize * lineHeightRatio;',
            'const paddingX = 24;',
            'const paddingTop = 10;',
            'const paddingBottom = 10;',
            'const paddingY = paddingTop + paddingBottom;',
            'const totalLines = this.h + 3;',
            'const scaleX = (window.innerWidth - paddingX) / (this.w * charWidth);',
            'const scaleY = (window.innerHeight - paddingY) / (totalLines * baseLineHeight);',
            'const scale = Math.max(0.5, Math.min(scaleX, scaleY));',
            'const fontSize = Math.floor(baseFontSize * scale);',
            'this.elem.style.fontSize = `${fontSize}px`;',
            '}',
            'render(s, p) {',
            'let output = \'\';',
            'output += `', unicode'––', ' Step ${s.stepCount.toString()} ', unicode'––', '\\n`;',
            'for (let y = 0; y < this.h; y++) {',
            'for (let x = 0; x < this.w; x++) {',
            'const c = p[y][x];',
            'if (x === s.x && y === s.y) {',
            'output += `<span class="ip-highlight">${c === \' \' ? \'&nbsp;\' : this.escapeHtml(c)}</span>`;',
            '} else {',
            'output += c === \' \' ? \'&nbsp;\' : this.escapeHtml(c);',
            '}',
            '}',
            'output += \'\\n\';',
            '}',
            'const cmd = p[s.y][s.x];',
            'const status = `IP:(${s.x.toString().padStart(2)}, ${s.y.toString().padStart(2)}) Dir:(${s.dx>=0?\'+\':\'\'}${s.dx},${s.dy>=0?\'+\':\'\'}${s.dy}) Cmd:\'${this.escapeHtml(cmd)}\'`;',
            'output += status;',
            'output += \'\\n\';',
            'if (s.outputBuffer) {',
            'output += this.escapeHtml(s.outputBuffer);',
            '} else {',
            'output += \' \';',
            '}',
            'this.elem.innerHTML = output;',
            '}',
            'escapeHtml(text) {',
            'const div = document.createElement(\'div\');',
            'div.textContent = text;',
            'return div.innerHTML;',
            '}',
            '}',
            'const WIDTH = 80;',
            'const HEIGHT = 25;',
            'const INITIAL_SEED = ', seedStr, ';',
            'const DETERMINISTIC_MODE = ', deterministicStr, ';',
            'let currentSeed = INITIAL_SEED;',
            'let runCount = 0;',
            'let b, r;',
            'function runBefunge() {',
            'const rng = DETERMINISTIC_MODE ? new SeededRandom(INITIAL_SEED + runCount * 10000) : null;',
            'b = new BefungeInterpreter(WIDTH, HEIGHT, rng);',
            'r = new BefungeRenderer(\'canvas\', WIDTH, HEIGHT);',
            'const sourceCode = generateRandomRain(currentSeed, runCount);',
            'b.load(sourceCode);',
            'async function exec() {',
            'while (b.step()) {',
            'r.render({x:b.x,y:b.y,dx:b.dx,dy:b.dy,stepCount:b.stepCount,outputBuffer:b.out,running:b.run}, b.p);',
            'await new Promise(resolve => setTimeout(resolve, 50));',
            'if (b.stepCount >= 20000) {',
            'b.run = false;',
            'break;',
            '}',
            '}',
            'if (b.stepCount >= 20000 || !b.run) {',
            'runCount++;',
            'if (DETERMINISTIC_MODE) {',
            'currentSeed = INITIAL_SEED + runCount;',
            '} else {',
            'currentSeed = Math.floor(Date.now() / 1000);',
            '}',
            'setTimeout(runBefunge, 30000);',
            '}',
            '}',
            'window.addEventListener(\'resize\', () => {',
            'if (r) {',
            'r.updateFontSize();',
            'r.render({x:b.x,y:b.y,dx:b.dx,dy:b.dy,stepCount:b.stepCount,outputBuffer:b.out,running:b.run}, b.p);',
            '}',
            '});',
            'exec();',
            '}',
            'runBefunge();'
        );
    }
}
