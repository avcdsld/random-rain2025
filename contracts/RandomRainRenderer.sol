// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract RandomRainRenderer is Ownable {
    using Strings for uint256;
    
    string public fontBase64;
    string public befungeInterpreterJS;
    string public befungeRendererJS;
    string public randomRainGeneratorJS;
    
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
    
    function svg(uint256 seed) external view returns (string memory) {
        string memory sourceCode = _generateSourceCode(seed, 0);
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
    
    function _generateSVGHeader() internal view returns (string memory) {
        uint256 WIDTH = 80;
        uint256 HEIGHT = 25;
        uint256 baseFontSize = 12;
        uint256 lineHeight = baseFontSize * 12 / 10;
        uint256 paddingX = 24;
        uint256 paddingTop = 10;
        uint256 paddingBottom = 10;
        uint256 totalLines = HEIGHT + 3;
        
        uint256 textWidth = WIDTH * baseFontSize * 6 / 10;
        uint256 actualTextWidth = textWidth + 6;
        uint256 contentWidth = paddingX + actualTextWidth + paddingX;
        uint256 contentHeight = totalLines * lineHeight + paddingTop + paddingBottom;
        
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
            contentWidth.toString(),
            ' ',
            contentHeight.toString(),
            '" preserveAspectRatio="xMidYMid meet" style="width:100%;height:100%;background:#000;font-family:\'DejaVu Sans Mono\',monospace;font-size:',
            baseFontSize.toString(),
            'px;fill:#fff;">',
            fontDef
        );
    }
    
    function _generateSVGStepLine() internal pure returns (string memory) {
        uint256 WIDTH = 80;
        uint256 paddingX = 24;
        uint256 paddingTop = 10;
        uint256 baseFontSize = 12;
        uint256 lineHeight = baseFontSize * 12 / 10;
        uint256 textWidth = WIDTH * baseFontSize * 6 / 10;
        uint256 actualTextWidth = textWidth + 6;
        uint256 contentWidth = paddingX + actualTextWidth + paddingX;
        uint256 textStartX = (contentWidth - textWidth) / 2;
        
        return string.concat(
            '<text x="',
            textStartX.toString(),
            '" y="',
            (paddingTop + lineHeight / 2).toString(),
            '" style="fill:#fff;">',
            unicode'––',
            ' Step 0 ',
            unicode'––',
            '</text>'
        );
    }
    
    function _generateSVGStatusLine() internal pure returns (string memory) {
        uint256 WIDTH = 80;
        uint256 paddingX = 24;
        uint256 paddingTop = 10;
        uint256 HEIGHT = 25;
        uint256 baseFontSize = 12;
        uint256 lineHeight = baseFontSize * 12 / 10;
        uint256 textWidth = WIDTH * baseFontSize * 6 / 10;
        uint256 actualTextWidth = textWidth + 6;
        uint256 contentWidth = paddingX + actualTextWidth + paddingX;
        uint256 textStartX = (contentWidth - textWidth) / 2;
        
        return string.concat(
            '<text x="',
            textStartX.toString(),
            '" y="',
            (paddingTop + lineHeight + HEIGHT * lineHeight + lineHeight / 2).toString(),
            '" style="fill:#fff;">IP:( 0,  0) Dir:(+1,+0) Cmd:\'v\'</text>'
        );
    }
    
    function _generateSVGOutputLine() internal pure returns (string memory) {
        uint256 WIDTH = 80;
        uint256 paddingX = 24;
        uint256 paddingTop = 10;
        uint256 HEIGHT = 25;
        uint256 baseFontSize = 12;
        uint256 lineHeight = baseFontSize * 12 / 10;
        uint256 textWidth = WIDTH * baseFontSize * 6 / 10;
        uint256 actualTextWidth = textWidth + 6;
        uint256 contentWidth = paddingX + actualTextWidth + paddingX;
        uint256 textStartX = (contentWidth - textWidth) / 2;
        
        return string.concat(
            '<text x="',
            textStartX.toString(),
            '" y="',
            (paddingTop + lineHeight + HEIGHT * lineHeight + lineHeight + lineHeight / 2).toString(),
            '" style="fill:#fff;"> </text>'
        );
    }
    
    function _generateCodeLinesSVG(string memory sourceCode) internal pure returns (string memory) {
        bytes memory codeBytes = bytes(sourceCode);
        return _buildCodeLinesSVG(codeBytes);
    }
    
    function _buildCodeLinesSVG(bytes memory codeBytes) internal pure returns (string memory) {
        bytes memory result = new bytes(codeBytes.length * 50);
        uint256 resultIndex = 0;
        uint256 lineIndex = 0;
        uint256 charIndex = 0;
        
        for (uint256 i = 0; i < codeBytes.length; i++) {
            bytes1 char = codeBytes[i];
            if (char == '\n') {
                if (lineIndex < 25) {
                    if (charIndex > 0) {
                        result[resultIndex++] = '<';
                        result[resultIndex++] = '/';
                        result[resultIndex++] = 't';
                        result[resultIndex++] = 'e';
                        result[resultIndex++] = 'x';
                        result[resultIndex++] = 't';
                        result[resultIndex++] = '>';
                    }
                    lineIndex++;
                    charIndex = 0;
                }
            } else {
                if (lineIndex < 25 && charIndex < 80) {
                    if (charIndex == 0) {
                        uint256 WIDTH = 80;
                        uint256 paddingX = 24;
                        uint256 baseFontSize = 12;
                        uint256 textWidth = WIDTH * baseFontSize * 6 / 10;
                        uint256 actualTextWidth = textWidth + 6;
                        uint256 contentWidth = paddingX + actualTextWidth + paddingX;
                        uint256 textStartX = (contentWidth - textWidth) / 2;
                        uint256 y = 24 + lineIndex * 14 + 7;
                        resultIndex = _appendTextTag(result, resultIndex, textStartX, y);
                    }
                    
                    bool isIP = (lineIndex == 0 && charIndex == 0);
                    if (isIP) {
                        result[resultIndex++] = '<';
                        result[resultIndex++] = 't';
                        result[resultIndex++] = 's';
                        result[resultIndex++] = 'p';
                        result[resultIndex++] = 'a';
                        result[resultIndex++] = 'n';
                        result[resultIndex++] = ' ';
                        result[resultIndex++] = 's';
                        result[resultIndex++] = 't';
                        result[resultIndex++] = 'y';
                        result[resultIndex++] = 'l';
                        result[resultIndex++] = 'e';
                        result[resultIndex++] = '=';
                        result[resultIndex++] = '"';
                        result[resultIndex++] = 'b';
                        result[resultIndex++] = 'a';
                        result[resultIndex++] = 'c';
                        result[resultIndex++] = 'k';
                        result[resultIndex++] = 'g';
                        result[resultIndex++] = 'r';
                        result[resultIndex++] = 'o';
                        result[resultIndex++] = 'u';
                        result[resultIndex++] = 'n';
                        result[resultIndex++] = 'd';
                        result[resultIndex++] = ':';
                        result[resultIndex++] = '#';
                        result[resultIndex++] = 'f';
                        result[resultIndex++] = 'f';
                        result[resultIndex++] = 'f';
                        result[resultIndex++] = ';';
                        result[resultIndex++] = 'c';
                        result[resultIndex++] = 'o';
                        result[resultIndex++] = 'l';
                        result[resultIndex++] = 'o';
                        result[resultIndex++] = 'r';
                        result[resultIndex++] = ':';
                        result[resultIndex++] = '#';
                        result[resultIndex++] = '0';
                        result[resultIndex++] = '0';
                        result[resultIndex++] = '0';
                        result[resultIndex++] = ';';
                        result[resultIndex++] = '"';
                        result[resultIndex++] = '>';
                    }
                    
                    if (char == '<') {
                        result[resultIndex++] = '&';
                        result[resultIndex++] = 'l';
                        result[resultIndex++] = 't';
                        result[resultIndex++] = ';';
                    } else if (char == '>') {
                        result[resultIndex++] = '&';
                        result[resultIndex++] = 'g';
                        result[resultIndex++] = 't';
                        result[resultIndex++] = ';';
                    } else if (char == '&') {
                        result[resultIndex++] = '&';
                        result[resultIndex++] = 'a';
                        result[resultIndex++] = 'm';
                        result[resultIndex++] = 'p';
                        result[resultIndex++] = ';';
                    } else if (char == '"') {
                        result[resultIndex++] = '&';
                        result[resultIndex++] = 'q';
                        result[resultIndex++] = 'u';
                        result[resultIndex++] = 'o';
                        result[resultIndex++] = 't';
                        result[resultIndex++] = ';';
                    } else if (char == ' ') {
                        result[resultIndex++] = '&';
                        result[resultIndex++] = '#';
                        result[resultIndex++] = '1';
                        result[resultIndex++] = '6';
                        result[resultIndex++] = '0';
                        result[resultIndex++] = ';';
                    } else {
                        result[resultIndex++] = char;
                    }
                    
                    if (isIP) {
                        result[resultIndex++] = '<';
                        result[resultIndex++] = '/';
                        result[resultIndex++] = 't';
                        result[resultIndex++] = 's';
                        result[resultIndex++] = 'p';
                        result[resultIndex++] = 'a';
                        result[resultIndex++] = 'n';
                        result[resultIndex++] = '>';
                    }
                    
                    charIndex++;
                    if (charIndex >= 80) {
                        result[resultIndex++] = '<';
                        result[resultIndex++] = '/';
                        result[resultIndex++] = 't';
                        result[resultIndex++] = 'e';
                        result[resultIndex++] = 'x';
                        result[resultIndex++] = 't';
                        result[resultIndex++] = '>';
                        charIndex = 0;
                    }
                }
            }
        }
        
        if (charIndex > 0 && lineIndex < 25) {
            result[resultIndex++] = '<';
            result[resultIndex++] = '/';
            result[resultIndex++] = 't';
            result[resultIndex++] = 'e';
            result[resultIndex++] = 'x';
            result[resultIndex++] = 't';
            result[resultIndex++] = '>';
        }
        
        bytes memory trimmed = new bytes(resultIndex);
        for (uint256 i = 0; i < resultIndex; i++) {
            trimmed[i] = result[i];
        }
        return string(trimmed);
    }
    
    function _appendTextTag(bytes memory result, uint256 resultIndex, uint256 paddingX, uint256 y) internal pure returns (uint256) {
        string memory yStr = y.toString();
        bytes memory yBytes = bytes(yStr);
        bytes memory xBytes = bytes(paddingX.toString());
        uint256 idx = resultIndex;
        
        result[idx++] = '<';
        result[idx++] = 't';
        result[idx++] = 'e';
        result[idx++] = 'x';
        result[idx++] = 't';
        result[idx++] = ' ';
        result[idx++] = 'x';
        result[idx++] = '=';
        result[idx++] = '"';
        for (uint256 j = 0; j < xBytes.length; j++) {
            result[idx++] = xBytes[j];
        }
        result[idx++] = '"';
        result[idx++] = ' ';
        result[idx++] = 'y';
        result[idx++] = '=';
        result[idx++] = '"';
        for (uint256 j = 0; j < yBytes.length; j++) {
            result[idx++] = yBytes[j];
        }
        result[idx++] = '"';
        result[idx++] = '>';
        
        return idx;
    }
    
    function html(uint256 seed, bool deterministicMode) external view returns (string memory) {
        string memory seedStr = seed.toString();
        string memory deterministicStr = deterministicMode ? "true" : "false";
        
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
            _getMainJS(seedStr, deterministicStr),
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
            newSeed = (seed * 1103515245 + 12345) & 0x7fffffff;
        }
        randomValue = newSeed;
    }
    
    function _randomInt(uint256 seed, uint256 min, uint256 max) internal pure returns (uint256 newSeed, uint256 result) {
        uint256 randomValue;
        (newSeed, randomValue) = _nextRandom(seed);
        unchecked {
            uint256 range = max - min + 1;
            uint256 numerator = randomValue * range;
            result = min + (numerator / 2147483648);
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
        bool isWandering = (runCount % 2 == 0);
        if (isWandering) {
            return _generateWandering(seed + runCount);
        } else {
            return _generateStraight(seed + runCount);
        }
    }
    
    function _generateWandering(uint256 seed) internal pure returns (string memory) {
        bytes memory b = new bytes(2024);
        uint256 p;
        uint256 rngSeed = _hashSeed(seed);
        
        for (; p < 80;) b[p++] = "v";
        b[p++] = "\n";
        
        for (uint256 L = 1; L < 22; L++) {
            uint256 numQ;
            (rngSeed, numQ) = _randomInt(rngSeed, 60, 80);
            uint256[] memory qPositions;
            (rngSeed, qPositions) = _sampleIndices(rngSeed, numQ, 80);
            
            bytes memory row = new bytes(80);
            for (uint256 i = 0; i < 80; i++) {
                row[i] = " ";
            }
            
            for (uint256 i = 0; i < qPositions.length; i++) {
                row[qPositions[i]] = "?";
            }
            
            for (uint256 i = 0; i < 80; i++) {
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
        for (uint256 i = 0; i < 34;) { b[p++] = "^"; i++; }
        b[p++] = "\n";
        
        for (uint256 i = 0; i < 36;) { b[p++] = " "; i++; }
        for (uint256 i = 0; i < 6;) b[p++] = bytes("<,_@#:")[i++];
        for (uint256 i = 0; i < 38;) { b[p++] = " "; i++; }
        
        assembly { mstore(b, p) }
        return string(b);
    }
    
    function _generateStraight(uint256 seed) internal pure returns (string memory) {
        bytes memory b = new bytes(2024);
        uint256 p;
        uint256 rngSeed = _hashSeed(seed);
        
        for (; p < 80;) b[p++] = "v";
        b[p++] = "\n";
        
        for (uint256 L = 1; L < 22; L++) {
            uint256[] memory qPositions;
            (rngSeed, qPositions) = _sampleIndices(rngSeed, 2, 80);
            
            bytes memory row = new bytes(80);
            for (uint256 i = 0; i < 80; i++) {
                row[i] = " ";
            }
            row[qPositions[0]] = "?";
            row[qPositions[1]] = "?";
            
            for (uint256 i = 0; i < 80; i++) {
                b[p++] = row[i];
            }
            b[p++] = "\n";
        }
        
        for (uint256 i = 0; i < 37;) { b[p++] = " "; i++; }
        for (uint256 i = 0; i < 9;) b[p++] = bytes(">>>>>>>>v")[i++];
        for (uint256 i = 0; i < 34;) { b[p++] = " "; i++; }
        b[p++] = "\n";
        
        for (uint256 i = 0; i < 38;) { b[p++] = "v"; i++; }
        for (uint256 i = 0; i < 8;) b[p++] = bytes('"Rain."<')[i++];
        for (uint256 i = 0; i < 34;) { b[p++] = "v"; i++; }
        b[p++] = "\n";
        
        for (uint256 i = 0; i < 36;) { b[p++] = "?"; i++; }
        for (uint256 i = 0; i < 10;) b[p++] = bytes("<>,#$:_@ >")[i++];
        for (uint256 i = 0; i < 34;) { b[p++] = "?"; i++; }
        
        assembly { mstore(b, p) }
        return string(b);
    }
    
    function _escapeSVG(string memory text) internal pure returns (string memory) {
        bytes memory textBytes = bytes(text);
        bytes memory result = new bytes(textBytes.length * 6);
        uint256 resultIndex = 0;
        
        for (uint256 i = 0; i < textBytes.length; i++) {
            bytes1 char = textBytes[i];
            if (char == '<') {
                result[resultIndex++] = '&';
                result[resultIndex++] = 'l';
                result[resultIndex++] = 't';
                result[resultIndex++] = ';';
            } else if (char == '>') {
                result[resultIndex++] = '&';
                result[resultIndex++] = 'g';
                result[resultIndex++] = 't';
                result[resultIndex++] = ';';
            } else if (char == '&') {
                result[resultIndex++] = '&';
                result[resultIndex++] = 'a';
                result[resultIndex++] = 'm';
                result[resultIndex++] = 'p';
                result[resultIndex++] = ';';
            } else if (char == '"') {
                result[resultIndex++] = '&';
                result[resultIndex++] = 'q';
                result[resultIndex++] = 'u';
                result[resultIndex++] = 'o';
                result[resultIndex++] = 't';
                result[resultIndex++] = ';';
            } else {
                result[resultIndex++] = char;
            }
        }
        
        bytes memory trimmed = new bytes(resultIndex);
        for (uint256 i = 0; i < resultIndex; i++) {
            trimmed[i] = result[i];
        }
        return string(trimmed);
    }
    
    function _escapeSVGWithNewlines(string memory text) internal pure returns (string memory) {
        bytes memory textBytes = bytes(text);
        bytes memory result = new bytes(textBytes.length * 20);
        uint256 resultIndex = 0;
        bool firstLine = true;
        
        for (uint256 i = 0; i < textBytes.length; i++) {
            bytes1 char = textBytes[i];
            if (char == '\n') {
                result[resultIndex++] = '<';
                result[resultIndex++] = '/';
                result[resultIndex++] = 't';
                result[resultIndex++] = 's';
                result[resultIndex++] = 'p';
                result[resultIndex++] = 'a';
                result[resultIndex++] = 'n';
                result[resultIndex++] = '>';
                result[resultIndex++] = '<';
                result[resultIndex++] = 't';
                result[resultIndex++] = 's';
                result[resultIndex++] = 'p';
                result[resultIndex++] = 'a';
                result[resultIndex++] = 'n';
                result[resultIndex++] = ' ';
                result[resultIndex++] = 'x';
                result[resultIndex++] = '=';
                result[resultIndex++] = '"';
                result[resultIndex++] = '1';
                result[resultIndex++] = '0';
                result[resultIndex++] = '"';
                result[resultIndex++] = ' ';
                result[resultIndex++] = 'd';
                result[resultIndex++] = 'y';
                result[resultIndex++] = '=';
                result[resultIndex++] = '"';
                result[resultIndex++] = '1';
                result[resultIndex++] = '2';
                result[resultIndex++] = '"';
                result[resultIndex++] = '>';
                firstLine = false;
            } else {
                if (firstLine && i == 0) {
                    result[resultIndex++] = '<';
                    result[resultIndex++] = 't';
                    result[resultIndex++] = 's';
                    result[resultIndex++] = 'p';
                    result[resultIndex++] = 'a';
                    result[resultIndex++] = 'n';
                    result[resultIndex++] = ' ';
                    result[resultIndex++] = 'x';
                    result[resultIndex++] = '=';
                    result[resultIndex++] = '"';
                    result[resultIndex++] = '1';
                    result[resultIndex++] = '0';
                    result[resultIndex++] = '"';
                    result[resultIndex++] = '>';
                }
                if (char == '<') {
                    result[resultIndex++] = '&';
                    result[resultIndex++] = 'l';
                    result[resultIndex++] = 't';
                    result[resultIndex++] = ';';
                } else if (char == '>') {
                    result[resultIndex++] = '&';
                    result[resultIndex++] = 'g';
                    result[resultIndex++] = 't';
                    result[resultIndex++] = ';';
                } else if (char == '&') {
                    result[resultIndex++] = '&';
                    result[resultIndex++] = 'a';
                    result[resultIndex++] = 'm';
                    result[resultIndex++] = 'p';
                    result[resultIndex++] = ';';
                } else if (char == '"') {
                    result[resultIndex++] = '&';
                    result[resultIndex++] = 'q';
                    result[resultIndex++] = 'u';
                    result[resultIndex++] = 'o';
                    result[resultIndex++] = 't';
                    result[resultIndex++] = ';';
                } else {
                    result[resultIndex++] = char;
                }
            }
        }
        
        result[resultIndex++] = '<';
        result[resultIndex++] = '/';
        result[resultIndex++] = 't';
        result[resultIndex++] = 's';
        result[resultIndex++] = 'p';
        result[resultIndex++] = 'a';
        result[resultIndex++] = 'n';
        result[resultIndex++] = '>';
        
        bytes memory trimmed = new bytes(resultIndex);
        for (uint256 i = 0; i < resultIndex; i++) {
            trimmed[i] = result[i];
        }
        return string(trimmed);
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
            'let hash = 0n;',
            'let str;',
            'if (typeof seed === "bigint") {',
            'str = seed.toString();',
            '} else if (typeof seed === "number" && seed > Number.MAX_SAFE_INTEGER) {',
            'str = BigInt(seed).toString();',
            '} else {',
            'str = String(seed);',
            '}',
            'for (let i = 0; i < str.length; i++) {',
            'const char = BigInt(str.charCodeAt(i));',
            'hash = ((hash << 5n) - hash) + char;',
            '}',
            'return hash & 0xFFFFFFFFn;',
            '}',
            'class SeededRandom {',
            'constructor(seed) {',
            'this.seed = hashSeed(seed);',
            '}',
            'next() {',
            'this.seed = (this.seed * 1103515245n + 12345n) & 0x7fffffffn;',
            'return Number(this.seed) / 2147483648;',
            '}',
            'int(min, max) {',
            'const range = BigInt(max - min + 1);',
            'this.next();',
            'const numerator = this.seed * range;',
            'return min + Number(numerator / 2147483648n);',
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
            'const qPos2 = rng.sample(Array.from({length: 35}, (_, i) => i), numQ2);',
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
            'const seedValue = typeof seed === "bigint" ? seed + BigInt(runCount) : BigInt(seed) + BigInt(runCount);',
            'return isWandering ? generateWandering(seedValue) : generateStraight(seedValue);',
            '}'
        );
    }
    
    function _getBefungeRendererJS() internal pure returns (string memory) {
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
            '}'
        );
    }
    
    function _getMainJS(string memory seedStr, string memory deterministicStr) internal pure returns (string memory) {
        return string.concat(
            'const WIDTH = 80;',
            'const HEIGHT = 25;',
            'const INITIAL_SEED = BigInt("', seedStr, '");',
            'const DETERMINISTIC_MODE = ', deterministicStr, ';',
            'let currentSeed = INITIAL_SEED;',
            'let runCount = 0;',
            'let b, r;',
            'function runBefunge() {',
            'const rng = DETERMINISTIC_MODE ? new SeededRandom(INITIAL_SEED + BigInt(runCount) * 10000n) : null;',
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
            'currentSeed = INITIAL_SEED + BigInt(runCount);',
            '} else {',
            'currentSeed = BigInt(Math.floor(Date.now() / 1000));',
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

