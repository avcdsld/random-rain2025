// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./RandomRainRenderer.sol";

contract RandomRain is ERC721, Ownable {
    using Strings for uint256;
    uint256 public totalSupply;
    uint256 public constant MAX_SUPPLY = 2;
    mapping(uint256 => uint256) public seeds;
    mapping(uint256 => bool) public deterministicMode;
    RandomRainRenderer public renderer;

    constructor(address _renderer) ERC721("Random Rain 2025", "RAIN") Ownable(msg.sender) {
        renderer = RandomRainRenderer(_renderer);
    }

    function mint(address to) public onlyOwner {
        require(totalSupply < MAX_SUPPLY, "exceeds max supply");
        _safeMint(to, totalSupply);
        uint256 seed = uint256(keccak256(abi.encodePacked("rain", block.timestamp)));
        seeds[totalSupply] = seed;
        deterministicMode[totalSupply] = false;
        totalSupply++;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "not exists");
        uint256 seed = seeds[tokenId];
        bool deterministic = deterministicMode[tokenId];
        string memory svg = renderer.svg(seed);
        string memory html = renderer.html(seed, deterministic);
        string memory json = string.concat(
            '{',
            '"name":"Random Rain #', tokenId.toString(), '",',
            '"description":"Random Rain.",',
            '"image":"', svg, '",',
            '"animation_url":"', html, '",',
            '"attributes":[',
            '{"trait_type":"Seed","value":"', seed.toString(), '"},',
            '{"trait_type":"Deterministic","value":"', deterministic ? "true" : "false", '"}',
            ']',
            '}'
        );
        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    function setSeed(uint256 tokenId, uint256 seed) external {
        require(_ownerOf(tokenId) == msg.sender, "not owner");
        seeds[tokenId] = seed;
    }

    function preview(uint256 seed) external view returns (string memory) {
        string memory svg = renderer.svg(seed);
        string memory html = renderer.html(seed, true);
        string memory json = string.concat(
            '{',
            '"name":"Random Rain Preview",',
            '"description":"Random Rain Preview.",',
            '"image":"', svg, '",',
            '"animation_url":"', html, '"',
            '}'
        );
        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    function setDeterministicMode(uint256 tokenId, bool _deterministic) external {
        require(_ownerOf(tokenId) == msg.sender, "not owner");
        deterministicMode[tokenId] = _deterministic;
    }

    function setRenderer(address _renderer) external onlyOwner {
        renderer = RandomRainRenderer(_renderer);
    }
}
