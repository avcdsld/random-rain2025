// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract RandomRainRenderer is Ownable {
    using Strings for uint256;
    uint256 private constant WIDTH = 80;
    uint256 private constant HEIGHT = 25;
    uint256 private constant BASE_FONT_SIZE = 12;
    uint256 private constant PADDING_X = 24;
    uint256 private constant PADDING_TOP = 10;
    uint256 private constant PADDING_BOTTOM = 10;
    uint256 private constant LINE_HEIGHT_RATIO = 12;
    uint256 private constant CHAR_WIDTH_RATIO = 6;
    uint256 private constant TEXT_WIDTH_OFFSET = 6;
    uint256 private constant TOTAL_EXTRA_LINES = 3;

    uint256 private constant RNG_MULTIPLIER = 1103515245;
    uint256 private constant RNG_INCREMENT = 12345;
    uint256 private constant RNG_MASK = 0x7fffffff;
    uint256 private constant RNG_MAX = 2147483648;

    string public fontBase64;
    string public befungeInterpreterJS;
    string public befungeRendererJS;
    string public randomRainGeneratorJS;

    struct LayoutMetrics {
        uint256 textWidth;
        uint256 actualTextWidth;
        uint256 contentWidth;
        uint256 contentHeight;
        uint256 textStartX;
        uint256 lineHeight;
    }

    constructor(
        string memory _fontBase64,
        string memory _befungeInterpreterJS,
        string memory _befungeRendererJS,
        string memory _randomRainGeneratorJS
    ) Ownable(msg.sender) {
        fontBase64 = _fontBase64;
        befungeInterpreterJS = _befungeInterpreterJS;
        befungeRendererJS = _befungeRendererJS;
        randomRainGeneratorJS = _randomRainGeneratorJS;
    }

    function setFontBase64(string memory _fontBase64) external onlyOwner {
        fontBase64 = _fontBase64;
    }

    function setBefungeInterpreterJS(string memory _befungeInterpreterJS) external onlyOwner {
        befungeInterpreterJS = _befungeInterpreterJS;
    }

    function setBefungeRendererJS(string memory _befungeRendererJS) external onlyOwner {
        befungeRendererJS = _befungeRendererJS;
    }

    function setRandomRainGeneratorJS(string memory _randomRainGeneratorJS) external onlyOwner {
        randomRainGeneratorJS = _randomRainGeneratorJS;
    }

    function svg(uint256 seed, bool startWandering) external view returns (string memory) {
        string memory sourceCode = _generateSourceCode(seed, startWandering);
        string memory svgContent = _generateSVGContent(sourceCode);
        return string.concat("data:image/svg+xml;base64,", Base64.encode(bytes(svgContent)));
    }

    function _generateSVGContent(string memory sourceCode) internal view returns (string memory) {
        string memory header = _generateSVGHeader();
        string memory stepLine = _generateSVGStepLine();
        string memory codeLines = _generateCodeLinesSVG(sourceCode);
        string memory statusLine = _generateSVGStatusLine();
        string memory outputLine = _generateSVGOutputLine();
        return string.concat(
            header,
            stepLine,
            codeLines,
            statusLine,
            outputLine,
            '</svg>'
        );
    }

    function _computeLayoutMetrics() internal pure returns (LayoutMetrics memory) {
        uint256 lineHeight = BASE_FONT_SIZE * LINE_HEIGHT_RATIO / 10;
        uint256 textWidth = WIDTH * BASE_FONT_SIZE * CHAR_WIDTH_RATIO / 10;
        uint256 actualTextWidth = textWidth + TEXT_WIDTH_OFFSET;
        uint256 contentWidth = PADDING_X + actualTextWidth + PADDING_X;
        uint256 totalLines = HEIGHT + TOTAL_EXTRA_LINES;
        uint256 contentHeight = totalLines * lineHeight + PADDING_TOP + PADDING_BOTTOM;
        uint256 textStartX = (contentWidth - textWidth) / 2;
        return LayoutMetrics({
            textWidth: textWidth,
            actualTextWidth: actualTextWidth,
            contentWidth: contentWidth,
            contentHeight: contentHeight,
            textStartX: textStartX,
            lineHeight: lineHeight
        });
    }

    function _generateSVGHeader() internal view returns (string memory) {
        LayoutMetrics memory metrics = _computeLayoutMetrics();
        string memory fontDef = '';
        if (bytes(fontBase64).length > 0) {
            fontDef = string.concat(
                '<defs><style type="text/css"><![CDATA[@font-face { font-family: "DejaVu Sans Mono"; src: url("data:font/woff2;base64,',
                fontBase64,
                '") format("woff2"); font-weight: normal; font-style: normal; }]]></style></defs>'
            );
        }
        return string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 ',
            metrics.contentWidth.toString(),
            ' ',
            metrics.contentHeight.toString(),
            '" preserveAspectRatio="xMidYMid meet" style="width:100%;height:100%;background:#000;font-family:\'DejaVu Sans Mono\',monospace;font-size:',
            BASE_FONT_SIZE.toString(),
            'px;fill:#fff;">',
            fontDef
        );
    }

    function _generateSVGStepLine() internal pure returns (string memory) {
        LayoutMetrics memory metrics = _computeLayoutMetrics();
        uint256 y = PADDING_TOP + metrics.lineHeight / 2;
        return string.concat(
            '<text x="',
            metrics.textStartX.toString(),
            '" y="',
            y.toString(),
            '" style="fill:#fff;">',
            unicode'––',
            ' Step 0 ',
            unicode'––',
            '</text>'
        );
    }

    function _generateSVGStatusLine() internal pure returns (string memory) {
        LayoutMetrics memory metrics = _computeLayoutMetrics();
        uint256 y = PADDING_TOP + metrics.lineHeight + HEIGHT * metrics.lineHeight + metrics.lineHeight / 2;
        return string.concat(
            '<text x="',
            metrics.textStartX.toString(),
            '" y="',
            y.toString(),
            '" style="fill:#fff;">IP:( 0,  0) Dir:(+1,+0) Cmd:\'v\'</text>'
        );
    }

    function _generateSVGOutputLine() internal pure returns (string memory) {
        LayoutMetrics memory metrics = _computeLayoutMetrics();
        uint256 y = PADDING_TOP + metrics.lineHeight + HEIGHT * metrics.lineHeight + metrics.lineHeight + metrics.lineHeight / 2;
        return string.concat(
            '<text x="',
            metrics.textStartX.toString(),
            '" y="',
            y.toString(),
            '" style="fill:#fff;"> </text>'
        );
    }

    function _generateCodeLinesSVG(string memory sourceCode) internal pure returns (string memory) {
        bytes memory codeBytes = bytes(sourceCode);
        return _buildCodeLinesSVG(codeBytes);
    }

    function _appendString(bytes memory result, uint256 idx, string memory str) internal pure returns (uint256) {
        bytes memory strBytes = bytes(str);
        for (uint256 i = 0; i < strBytes.length; i++) {
            result[idx++] = strBytes[i];
        }
        return idx;
    }

    function _appendEntity(bytes memory result, uint256 idx, bytes1 char) internal pure returns (uint256) {
        if (char == '<') return _appendString(result, idx, "&lt;");
        if (char == '>') return _appendString(result, idx, "&gt;");
        if (char == '&') return _appendString(result, idx, "&amp;");
        if (char == '"') return _appendString(result, idx, "&quot;");
        if (char == ' ') return _appendString(result, idx, "&#160;");
        result[idx++] = char;
        return idx;
    }

    function _appendCloseTag(bytes memory result, uint256 idx, string memory tag) internal pure returns (uint256) {
        result[idx++] = '<';
        result[idx++] = '/';
        idx = _appendString(result, idx, tag);
        result[idx++] = '>';
        return idx;
    }

    function _buildCodeLinesSVG(bytes memory codeBytes) internal pure returns (string memory) {
        bytes memory result = new bytes(codeBytes.length * 50);
        uint256 resultIndex = 0;
        uint256 lineIndex = 0;
        uint256 charIndex = 0;
        LayoutMetrics memory metrics = _computeLayoutMetrics();

        for (uint256 i = 0; i < codeBytes.length; i++) {
            bytes1 char = codeBytes[i];
            if (char == '\n') {
                if (lineIndex < HEIGHT) {
                    if (charIndex > 0) {
                        resultIndex = _appendCloseTag(result, resultIndex, "text");
                    }
                    lineIndex++;
                    charIndex = 0;
                }
            } else {
                if (lineIndex < HEIGHT && charIndex < WIDTH) {
                    if (charIndex == 0) {
                        uint256 y = 24 + lineIndex * 14 + 7;
                        resultIndex = _appendTextTag(result, resultIndex, metrics.textStartX, y);
                    }

                    resultIndex = _appendEntity(result, resultIndex, char);

                    charIndex++;
                    if (charIndex >= WIDTH) {
                        resultIndex = _appendCloseTag(result, resultIndex, "text");
                        charIndex = 0;
                    }
                }
            }
        }

        if (charIndex > 0 && lineIndex < HEIGHT) {
            resultIndex = _appendCloseTag(result, resultIndex, "text");
        }

        bytes memory trimmed = new bytes(resultIndex);
        for (uint256 i = 0; i < resultIndex; i++) {
            trimmed[i] = result[i];
        }
        return string(trimmed);
    }

    function _appendTextTag(bytes memory result, uint256 resultIndex, uint256 paddingX, uint256 y) internal pure returns (uint256) {
        uint256 idx = resultIndex;
        idx = _appendString(result, idx, "<text x=\"");
        idx = _appendString(result, idx, paddingX.toString());
        idx = _appendString(result, idx, "\" y=\"");
        idx = _appendString(result, idx, y.toString());
        idx = _appendString(result, idx, "\">");
        return idx;
    }

    function html(uint256 seed, bool deterministicMode, bool startWandering) external view returns (string memory) {
        string memory seedStr = seed.toString();
        string memory deterministicStr = deterministicMode ? "true" : "false";
        string memory startWanderingStr = startWandering ? "true" : "false";
        string memory interpreterJS = bytes(befungeInterpreterJS).length > 0 ? befungeInterpreterJS : _getBefungeInterpreterJS();
        string memory generatorJS = bytes(randomRainGeneratorJS).length > 0 ? randomRainGeneratorJS : _getRandomRainGeneratorJS();
        string memory rendererJS = bytes(befungeRendererJS).length > 0 ? befungeRendererJS : _getBefungeRendererJS();
        string memory htmlContent = string.concat(
            '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Befunge</title><style>',
            '@font-face { font-family: "DejaVu Sans Mono"; src: url("data:font/woff2;base64,',
            fontBase64,
            '") format("woff2"); font-weight: normal; font-style: normal; }',
            '@font-face { font-family: "DejaVu Sans Mono"; src: url("data:font/woff2;base64,',
            fontBase64,
            '") format("woff2"); font-weight: bold; font-style: normal; }',
            'body { margin: 0; padding: 0; background: #000; display: flex; justify-content: center; align-items: center; min-height: 100vh; overflow: hidden; }',
            'pre { display: block; font-family: "DejaVu Sans Mono", monospace; font-weight: normal; font-size: 12px; color: #fff; background: #000; margin: 0; padding: 3px 12px 8px 12px; white-space: pre; overflow: auto; max-width: 100vw; max-height: 100vh; line-height: 1.2; box-sizing: border-box; }',
            '.ip-highlight { background: #fff; color: #000; }',
            '</style></head><body><pre id="canvas"></pre><script>',
            interpreterJS,
            generatorJS,
            rendererJS,
            _getMainJS(seedStr, deterministicStr, startWanderingStr),
            '</script></body></html>'
        );
        return string.concat("data:text/html;base64,", Base64.encode(bytes(htmlContent)));
    }

    function _hashSeed(uint256 seed) internal pure returns (uint256) {
        uint256 hash = 0;
        string memory str = seed.toString();
        bytes memory strBytes = bytes(str);
        unchecked {
            for (uint256 i = 0; i < strBytes.length; i++) {
                uint256 char = uint256(uint8(strBytes[i]));
                hash = ((hash << 5) - hash) + char;
                hash = hash & hash;
            }
        }
        return hash & 0xFFFFFFFF;
    }

    function _nextRandom(uint256 seed) internal pure returns (uint256 newSeed, uint256 randomValue) {
        unchecked {
            newSeed = (seed * RNG_MULTIPLIER + RNG_INCREMENT) & RNG_MASK;
        }
        randomValue = newSeed;
    }

    function _randomInt(uint256 seed, uint256 min, uint256 max) internal pure returns (uint256 newSeed, uint256 result) {
        uint256 randomValue;
        (newSeed, randomValue) = _nextRandom(seed);
        unchecked {
            uint256 range = max - min + 1;
            uint256 numerator = randomValue * range;
            result = min + (numerator / RNG_MAX);
        }
    }

    function _sampleIndices(uint256 seed, uint256 count, uint256 total) internal pure returns (uint256 newSeed, uint256[] memory indices) {
        indices = new uint256[](count);
        uint256[] memory available = new uint256[](total);
        for (uint256 i = 0; i < total; i++) {
            available[i] = i;
        }
        
        newSeed = seed;
        uint256 availableCount = total;
        
        for (uint256 i = 0; i < count && availableCount > 0; i++) {
            uint256 idx;
            (newSeed, idx) = _randomInt(newSeed, 0, availableCount - 1);
            indices[i] = available[idx];
            for (uint256 j = idx; j < availableCount - 1; j++) {
                available[j] = available[j + 1];
            }
            availableCount--;
        }
    }

    function _generateSourceCode(uint256 seed, uint256 runCount) internal pure returns (string memory) {
        bool startWandering = (runCount % 2 == 0);
        return _generateSourceCode(seed + runCount, startWandering);
    }

    function _generateSourceCode(uint256 seed, bool startWandering) internal pure returns (string memory) {
        if (startWandering) {
            return _generateWandering(seed);
        } else {
            return _generateStraight(seed);
        }
    }

    function _generateWandering(uint256 seed) internal pure returns (string memory) {
        bytes memory b = new bytes(2024);
        uint256 p = 0;
        uint256 rngSeed = _hashSeed(seed);

        for (uint256 i = 0; i < WIDTH; i++) {
            b[p] = "v";
            p++;
        }
        b[p] = "\n";
        p++;

        for (uint256 L = 1; L < 22; L++) {
            uint256 numQ;
            (rngSeed, numQ) = _randomInt(rngSeed, 60, WIDTH);
            uint256[] memory qPositions;
            (rngSeed, qPositions) = _sampleIndices(rngSeed, numQ, WIDTH);

            bytes memory row = new bytes(WIDTH);
            for (uint256 i = 0; i < WIDTH; i++) {
                row[i] = " ";
            }

            for (uint256 i = 0; i < qPositions.length; i++) {
                row[qPositions[i]] = "?";
            }

            for (uint256 i = 0; i < WIDTH; i++) {
                b[p++] = row[i];
            }
            b[p++] = "\n";
        }

        uint256 numQ1;
        (rngSeed, numQ1) = _randomInt(rngSeed, 27, 36);
        uint256[] memory qPos1;
        (rngSeed, qPos1) = _sampleIndices(rngSeed, numQ1, 36);

        bytes memory row1 = new bytes(36);
        for (uint256 i = 0; i < 36; i++) {
            row1[i] = " ";
        }
        for (uint256 i = 0; i < qPos1.length; i++) {
            row1[qPos1[i]] = "?";
        }
        for (uint256 i = 0; i < 36; i++) {
            b[p++] = row1[i];
        }
        for (uint256 i = 0; i < 9;) { b[p++] = "^"; i++; }

        uint256 numQ2;
        (rngSeed, numQ2) = _randomInt(rngSeed, 25, 34);
        uint256[] memory qPos2;
        (rngSeed, qPos2) = _sampleIndices(rngSeed, numQ2, 35);

        bytes memory row2 = new bytes(35);
        for (uint256 i = 0; i < 35; i++) {
            row2[i] = " ";
        }
        for (uint256 i = 0; i < qPos2.length; i++) {
            row2[qPos2[i]] = "?";
        }
        for (uint256 i = 0; i < 35; i++) {
            b[p++] = row2[i];
        }
        b[p++] = "\n";

        for (uint256 i = 0; i < 36;) { b[p++] = "^"; i++; }
        for (uint256 i = 0; i < 10;) b[p++] = bytes('v"Rain."0<')[i++];
        for (uint256 i = 0; i < WIDTH - 46;) { b[p++] = "^"; i++; }
        b[p++] = "\n";

        for (uint256 i = 0; i < 36;) { b[p++] = " "; i++; }
        for (uint256 i = 0; i < 6;) b[p++] = bytes("<,_@#:")[i++];
        for (uint256 i = 0; i < WIDTH - 42;) { b[p++] = " "; i++; }

        assembly { mstore(b, p) }
        return string(b);
    }

    function _generateStraight(uint256 seed) internal pure returns (string memory) {
        bytes memory b = new bytes(2024);
        uint256 p = 0;
        uint256 rngSeed = _hashSeed(seed);

        for (uint256 i = 0; i < WIDTH; i++) {
            b[p] = "v";
            p++;
        }
        b[p] = "\n";
        p++;

        for (uint256 L = 1; L < 22; L++) {
            uint256[] memory qPositions;
            (rngSeed, qPositions) = _sampleIndices(rngSeed, 2, WIDTH);

            bytes memory row = new bytes(WIDTH);
            for (uint256 i = 0; i < WIDTH; i++) {
                row[i] = " ";
            }
            row[qPositions[0]] = "?";
            row[qPositions[1]] = "?";

            for (uint256 i = 0; i < WIDTH; i++) {
                b[p++] = row[i];
            }
            b[p++] = "\n";
        }

        for (uint256 i = 0; i < 37;) { b[p++] = " "; i++; }
        for (uint256 i = 0; i < 9;) b[p++] = bytes(">>>>>>>>v")[i++];
        for (uint256 i = 0; i < WIDTH - 46;) { b[p++] = " "; i++; }
        b[p++] = "\n";

        for (uint256 i = 0; i < 38;) { b[p++] = "v"; i++; }
        for (uint256 i = 0; i < 8;) b[p++] = bytes('"Rain."<')[i++];
        for (uint256 i = 0; i < WIDTH - 46;) { b[p++] = "v"; i++; }
        b[p++] = "\n";

        for (uint256 i = 0; i < 36;) { b[p++] = "?"; i++; }
        for (uint256 i = 0; i < 10;) b[p++] = bytes("<>,#$:_@ >")[i++];
        for (uint256 i = 0; i < WIDTH - 46;) { b[p++] = "?"; i++; }

        assembly { mstore(b, p) }
        return string(b);
    }

    function _getBefungeInterpreterJS() internal pure returns (string memory) {
        return string.concat(
            'class BefungeInterpreter{\n',
            '  constructor(w,h,rng){\n',
            '    this.w=w;this.h=h;this.rng=rng;\n',
            '    this.p=Array(h).fill().map(()=>Array(w).fill(\' \'));\n',
            '    this.x=0;this.y=0;this.dx=1;this.dy=0;\n',
            '    this.stepCount=0;this.stack=[];this.out=\'\';this.run=true;this.str=false\n',
            '  }\n',
            '  load(src){\n',
            '    src.split(\'\\n\').forEach((line,y)=>{\n',
            '      [...line].forEach((c,x)=>this.p[y]&&(this.p[y][x]=c))\n',
            '    })\n',
            '  }\n',
            '  pop(){return this.stack.pop()||0}\n',
            '  step(){\n',
            '    const c=this.p[this.y][this.x];\n',
            '    if(this.str){\n',
            '      if(c===\'"\')this.str=false;else this.stack.push(c.charCodeAt(0))\n',
            '    }else{\n',
            '      const ops={\n',
            '        \'>\':()=>[this.dx,this.dy]=[1,0],\n',
            '        \'<\':()=>[this.dx,this.dy]=[-1,0],\n',
            '        \'^\':()=>[this.dx,this.dy]=[0,-1],\n',
            '        \'v\':()=>[this.dx,this.dy]=[0,1],\n',
            '        \'?\':()=>{\n',
            '          const r=this.rng?this.rng.next():Math.random();\n',
            '          const d=[[1,0],[-1,0],[0,1],[0,-1]];\n',
            '          const i=r<0.3?0:r<0.5?1:r<0.8?2:3;\n',
            '          [this.dx,this.dy]=d[i]\n',
            '        },\n',
            '        \'_\':()=>[this.dx,this.dy]=[this.pop()?-1:1,0],\n',
            '        \'|\':()=>[this.dx,this.dy]=[0,this.pop()?-1:1],\n',
            '        \'"\':()=>this.str=true,\n',
            '        \'+\':()=>this.stack.push(this.pop()+this.pop()),\n',
            '        \'-\':()=>{const[a,b]=[this.pop(),this.pop()];this.stack.push(b-a)},\n',
            '        \'*\':()=>this.stack.push(this.pop()*this.pop()),\n',
            '        \'/\':()=>{const[a,b]=[this.pop(),this.pop()];this.stack.push(a?Math.floor(b/a):0)},\n',
            '        \'%\':()=>{const[a,b]=[this.pop(),this.pop()];this.stack.push(a?b%a:0)},\n',
            '        \'!\':()=>this.stack.push(this.pop()?0:1),\n',
            '        \'`\':()=>{const[a,b]=[this.pop(),this.pop()];this.stack.push(b>a?1:0)},\n',
            '        \':\':()=>this.stack.push(this.stack[this.stack.length-1]||0),\n',
            '        \'\\\\\':()=>{const[a,b]=[this.pop(),this.pop()];this.stack.push(a,b)},\n',
            '        \'$\':()=>this.pop(),\n',
            '        \'.\':()=>this.out+=this.pop()+\' \',\n',
            '        \',\':()=>this.out+=String.fromCharCode(this.pop()),\n',
            '        \'#\':()=>this.move(),\n',
            '        \'g\':()=>{const[y,x]=[this.pop(),this.pop()];this.stack.push(this.p[y%this.h][x%this.w].charCodeAt(0))},\n',
            '        \'p\':()=>{const[y,x,v]=[this.pop(),this.pop(),this.pop()];this.p[y%this.h][x%this.w]=String.fromCharCode(v%256)},\n',
            '        \'&\':()=>this.stack.push(0),\n',
            '        \'~\':()=>this.stack.push(0),\n',
            '        \'@\':()=>this.run=false\n',
            '      };\n',
            '      if(/\\d/.test(c))this.stack.push(+c);else if(ops[c])ops[c]()\n',
            '    }\n',
            '    this.move();this.stepCount++;return this.run\n',
            '  }\n',
            '  move(){\n',
            '    this.x=(this.x+this.dx)%this.w;this.y=(this.y+this.dy)%this.h;\n',
            '    if(this.x<0)this.x+=this.w;if(this.y<0)this.y+=this.h\n',
            '  }\n',
            '}'
        );
    }

    function _getRandomRainGeneratorJS() internal pure returns (string memory) {
        return string.concat(
            'const RNG_MULT=1103515245n;const RNG_INC=12345n;const RNG_MASK=0x7fffffffn;const RNG_MAX=2147483648n;\n',
            'function hashSeed(seed){\n',
            '  let h=0n;const s=typeof seed==="bigint"?seed.toString():(typeof seed==="number"&&seed>Number.MAX_SAFE_INTEGER?BigInt(seed).toString():String(seed));\n',
            '  for(let i=0;i<s.length;i++)h=((h<<5n)-h)+BigInt(s.charCodeAt(i));\n',
            '  return h&0xFFFFFFFFn\n',
            '}\n',
            'class SeededRandom{\n',
            '  constructor(seed){this.seed=hashSeed(seed)}\n',
            '  next(){this.seed=(this.seed*RNG_MULT+RNG_INC)&RNG_MASK;return Number(this.seed)/Number(RNG_MAX)}\n',
            '  int(min,max){this.next();const r=BigInt(max-min+1);return min+Number((this.seed*r)/RNG_MAX)}\n',
            '  sampleIndices(total,count){\n',
            '    const available=Array.from({length:total},(_,i)=>i);\n',
            '    const indices=[];\n',
            '    let availableCount=total;\n',
            '    for(let i=0;i<count&&availableCount>0;i++){\n',
            '      const idx=this.int(0,availableCount-1);\n',
            '      indices.push(available[idx]);\n',
            '      for(let j=idx;j<availableCount-1;j++){\n',
            '        available[j]=available[j+1]\n',
            '      }\n',
            '      availableCount--\n',
            '    }\n',
            '    return indices\n',
            '  }\n',
            '}\n',
            'function createRowWithQuestions(w,qc,rng){\n',
            '  const r=Array(w).fill(\' \');rng.sampleIndices(w,qc).forEach(p=>r[p]=\'?\');return r.join(\'\')\n',
            '}\n',
            'function generateWandering(seed){\n',
            '  const W=80;const rng=new SeededRandom(seed);const l=[\'v\'.repeat(W)];\n',
            '  for(let i=1;i<22;i++)l.push(createRowWithQuestions(W,rng.int(60,W),rng));\n',
            '  const ur=createRowWithQuestions(36,rng.int(27,36),rng);\n',
            '  const lr=createRowWithQuestions(35,rng.int(25,34),rng);\n',
            '  l.push(ur+\'^\'.repeat(9)+lr);\n',
            '  l.push(\'^\'.repeat(36)+\'v"Rain."0<\'+\'^\'.repeat(W-46));\n',
            '  l.push(\' \'.repeat(36)+\'<,_@#:\'+\' \'.repeat(W-42));\n',
            '  return l.join(\'\\n\')\n',
            '}\n',
            'function generateStraight(seed){\n',
            '  const W=80;const rng=new SeededRandom(seed);const l=[\'v\'.repeat(W)];\n',
            '  for(let i=1;i<22;i++)l.push(createRowWithQuestions(W,2,rng));\n',
            '  l.push(\' \'.repeat(37)+\'>>>>>>>>v\'+\' \'.repeat(W-46));\n',
            '  l.push(\'v\'.repeat(38)+\'"Rain."<\'+\'v\'.repeat(W-46));\n',
            '  l.push(\'?\'.repeat(36)+\'<>,#$:_@ >\'+\'?\'.repeat(W-46));\n',
            '  return l.join(\'\\n\')\n',
            '}\n',
            'function generateRandomRain(seed,rc){\n',
            '  const sv=(typeof seed==="bigint"?seed:BigInt(seed))+BigInt(rc);\n',
            '  return rc%2===0?generateWandering(sv):generateStraight(sv)\n',
            '}'
        );
    }

    function _getBefungeRendererJS() internal pure returns (string memory) {
        return string.concat(
            'class BefungeRenderer{\n',
            '  constructor(id,w,h){\n',
            '    this.elem=document.getElementById(id);this.w=w;this.h=h;this.updateFontSize()\n',
            '  }\n',
            '  updateFontSize(){\n',
            '    const BFS=12;const CWR=0.6;const LHR=1.2;const PX=24;const PT=10;const PB=10;const EL=3;const MS=0.5;\n',
            '    const cw=BFS*CWR;const lh=BFS*LHR;const py=PT+PB;const tl=this.h+EL;\n',
            '    const sx=(window.innerWidth-PX)/(this.w*cw);const sy=(window.innerHeight-py)/(tl*lh);\n',
            '    const s=Math.max(MS,Math.min(sx,sy));this.elem.style.fontSize=`${Math.floor(BFS*s)}px`\n',
            '  }\n',
            '  render(s,p){\n',
            '    let o=`', unicode'––', ' Step ${s.stepCount.toString()} ', unicode'––', '\\n`;\n',
            '    for(let y=0;y<this.h;y++){\n',
            '      for(let x=0;x<this.w;x++){\n',
            '        const c=p[y][x];const ip=(x===s.x&&y===s.y);\n',
            '        const dc=c===\' \'?\'&nbsp;\':this.escapeHtml(c);\n',
            '        o+=ip?`<span class="ip-highlight">${dc}</span>`:dc\n',
            '      }\n',
            '      o+=\'\\n\'\n',
            '    }\n',
            '    const cmd=p[s.y][s.x];const dx=s.dx>=0?\'+\':\'\';const dy=s.dy>=0?\'+\':\'\';\n',
            '    o+=`IP:(${s.x.toString().padStart(2)}, ${s.y.toString().padStart(2)}) Dir:(${dx}${s.dx},${dy}${s.dy}) Cmd:\'${this.escapeHtml(cmd)}\'`+\'\\n\';\n',
            '    o+=s.outputBuffer?this.escapeHtml(s.outputBuffer):\' \';\n',
            '    this.elem.innerHTML=o\n',
            '  }\n',
            '  escapeHtml(t){const d=document.createElement(\'div\');d.textContent=t;return d.innerHTML}\n',
            '}'
        );
    }

    function _getMainJS(string memory seedStr, string memory deterministicStr, string memory startWanderingStr) internal pure returns (string memory) {
        return string.concat(
            'const W=80;const H=25;const MS=20000;const SD=50;const RD=30000;const RO=10000n;\n',
            'const IS=BigInt("', seedStr, '");const DM=', deterministicStr, ';const IW=', startWanderingStr, ';\n',
            'let cs=IS;let rc=0;let i,r;\n',
            'function runBefunge(){\n',
            '  const rs=DM?IS+BigInt(rc)*RO:null;\n',
            '  i=new BefungeInterpreter(W,H,rs?new SeededRandom(rs):null);\n',
            '  r=new BefungeRenderer(\'canvas\',W,H);\n',
            '  const initialLayout=(rc===0)?IW:(rc%2===0);\n',
            '  i.load(initialLayout?generateWandering(cs):generateStraight(cs));\n',
            '  async function exec(){\n',
            '    while(i.step()){\n',
            '      r.render({x:i.x,y:i.y,dx:i.dx,dy:i.dy,stepCount:i.stepCount,outputBuffer:i.out,running:i.run},i.p);\n',
            '      await new Promise(resolve=>setTimeout(resolve,SD));\n',
            '      if(i.stepCount>=MS){i.run=false;break}\n',
            '    }\n',
            '    if(i.stepCount>=MS||!i.run){\n',
            '      rc++;cs=DM?IS+BigInt(rc):BigInt(Math.floor(Date.now()/1000));\n',
            '      setTimeout(runBefunge,RD)\n',
            '    }\n',
            '  }\n',
            '  window.addEventListener(\'resize\',()=>{\n',
            '    if(r){r.updateFontSize();r.render({x:i.x,y:i.y,dx:i.dx,dy:i.dy,stepCount:i.stepCount,outputBuffer:i.out,running:i.run},i.p)}\n',
            '  });\n',
            '  exec()\n',
            '}\n',
            'runBefunge();'
        );
    }
}

