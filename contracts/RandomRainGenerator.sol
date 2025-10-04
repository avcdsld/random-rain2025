// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract RandomRainGenerator {
    function rnd(uint256 s, uint256 i, uint256 p) private pure returns (bool) {
        return uint256(keccak256(abi.encodePacked(s, i))) % 100 < p;
    }
    
    function generateCode(uint256 seed) public pure returns (string memory) {
        bytes32 hash = keccak256(abi.encodePacked(seed));
        return (uint256(hash) & 1 == 0) ? generateWandering(seed) : generateStraight(seed);
    }
    
    function generateWandering(uint256 seed) private pure returns (string memory) {
        bytes memory b = new bytes(2024);
        uint256 p;
        
        for (; p < 80;) b[p++] = "v";
        b[p++] = "\n";
        
        for (uint256 L = 1; L < 22; L++) {
            for (uint256 i = 0; i < 80;) 
                b[p++] = rnd(seed, L * 1000 + i++, 75) ? bytes1("?") : bytes1(" ");
            b[p++] = "\n";
        }
        
        for (uint256 i = 0; i < 36;) b[p++] = rnd(seed, 23000 + i++, 80) ? bytes1("?") : bytes1(" ");
        for (uint256 i = 0; i < 9;) { b[p++] = "^"; i++; }
        for (uint256 i = 0; i < 35;) b[p++] = rnd(seed, 24000 + i++, 75) ? bytes1("?") : bytes1(" ");
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
    
    function generateStraight(uint256 seed) private pure returns (string memory) {
        bytes memory b = new bytes(2024);
        uint256 p;
        
        for (; p < 80;) b[p++] = "v";
        b[p++] = "\n";
        
        for (uint256 L = 1; L < 22; L++) {
            uint256 pos1 = uint256(keccak256(abi.encodePacked(seed, L * 1000))) % 80;
            uint256 pos2 = uint256(keccak256(abi.encodePacked(seed, L * 1000 + 1))) % 80;
            if (pos2 == pos1) pos2 = (pos2 + 1) % 80;
            
            for (uint256 i = 0; i < 80; i++) {
                b[p++] = (i == pos1 || i == pos2) ? bytes1("?") : bytes1(" ");
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
    
    function getType(uint256 seed) public pure returns (string memory) {
        return (uint256(keccak256(abi.encodePacked(seed))) & 1 == 0) ? "wandering" : "straight";
    }
}
