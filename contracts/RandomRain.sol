// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IRandomRainGenerator.sol";
import "./interfaces/IBefungeViewer.sol";

contract RandomRain is ERC721, Ownable {
    using Strings for uint256;
    
    uint256 public totalSupply;
    uint256 public constant MAX_SUPPLY = 1000;
    
    IRandomRainGenerator public generator;
    IBefungeViewer public viewer;

    mapping(uint256 => uint256) public tokenSeeds;
    
    constructor(
        address _generator,
        address _viewer
    ) ERC721("Random Rain Poetry", "RAIN") Ownable(msg.sender) {
        generator = IRandomRainGenerator(_generator);
        viewer = IBefungeViewer(_viewer);
    }
    
    function mint(address to) public onlyOwner {
        require(totalSupply < MAX_SUPPLY, "exceeds max supply");
        _safeMint(to, totalSupply);

        uint256 seed = uint256(keccak256(abi.encodePacked("rain", block.timestamp)));
        tokenSeeds[totalSupply] = seed;

        totalSupply++;
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "not exists");

        uint256 seed = tokenSeeds[tokenId];
        string memory code = generator.generateCode(seed);
        string memory svg = viewer.toSVG(code);
        string memory html;
        try viewer.toHTML(code) returns (string memory res) {
            html = res;
        } catch {
            html = svg;
        }

        string memory json = string.concat(
            '{',
                '"name":"Random Rain #', tokenId.toString(), '",',
                '"description":"Random Rain.",',
                '"image":"', svg, '",',
                '"animation_url":"', html, '",',
                '"attributes":[',
                    '{"trait_type":"Seed","value":"', seed.toString(), '"},',
                    '{"trait_type":"Type","value":"', generator.getType(seed), '"}'
                ']',
            '}'
        );
        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }
    
    function getTokenCode(uint256 tokenId) external view returns (string memory) {
        require(ownerOf(tokenId) != address(0), "not exists");
        return generator.generateCode(tokenSeeds[tokenId]);
    }
    
    function setGenerator(address _generator) external onlyOwner {
        generator = IRandomRainGenerator(_generator);
    }
    
    function setViewer(address _viewer) external onlyOwner {
        viewer = IBefungeViewer(_viewer);
    }
}
