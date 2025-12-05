// SPDX-License-Identifier: MIT
/*
vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
?                                                                              ?
?     ????    ??   ?   ?  ????    ??   ?   ?       ????    ??   ???  ?   ?     ?
?     ?  ?   ?  ?  ??  ?  ?   ?  ?  ?  ?? ??       ?  ?   ?  ?   ?   ??  ?     ?
?     ????   ????  ? ? ?  ?   ?  ?  ?  ? ? ?       ????   ????   ?   ? ? ?     ?
?     ? ?    ?  ?  ?  ??  ?   ?  ?  ?  ?   ?       ? ?    ?  ?   ?   ?  ??     ?
?     ?  ?   ?  ?  ?   ?  ????    ??   ?   ?       ?  ?   ?  ?  ???  ?   ?  @  ?
?                                                                              ?
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
*/
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./RandomRainRenderer.sol";

contract RandomRain2025 is ERC721, Ownable {
    using Strings for uint256;
    uint256 public totalSupply;
    mapping(uint256 => uint256) public seeds;
    mapping(uint256 => bool) public deterministicMode;
    mapping(uint256 => bool) public startWandering;
    RandomRainRenderer public renderer;

    constructor(address rendererAddress) ERC721("Random Rain 2025", "RAIN") Ownable(msg.sender) {
        renderer = RandomRainRenderer(rendererAddress);
    }

    function mint(address to) public onlyOwner {
        seeds[totalSupply] = uint256(keccak256(abi.encodePacked("rain", block.timestamp)));
        deterministicMode[totalSupply] = false;
        startWandering[totalSupply] = true;
        _safeMint(to, totalSupply++);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "not exists");
        uint256 seed = seeds[tokenId];
        bool deterministic = deterministicMode[tokenId];
        bool wandering = startWandering[tokenId];
        string memory svg = renderer.svg(seed, wandering);
        string memory html = renderer.html(seed, deterministic, wandering);
        string memory json = string.concat(
            '{',
            '"name":"Random Rain 2025 NFT",',
            '"description":"Random Rain 2025 NFT is a newly revised, NFT-based edition of the award-winning code poem Random Rain (2019, Source Code Poetry Spirit Award). This work reimagines Seiichi Niikuni', unicode'’', 's seminal concrete poem Rain (1966) through the stack-based, two-dimensional programming language Befunge-93, granting the poem machine readability and executable form while extending its avant-garde spirit into the computational domain.",',
            '"image":"', svg, '",',
            '"animation_url":"', html, '",',
            '"attributes":[',
            '{"trait_type":"Seed","value":"', seed.toString(), '"},',
            '{"trait_type":"Deterministic","value":"', deterministic ? "true" : "false", '"},',
            '{"trait_type":"StartWandering","value":"', wandering ? "true" : "false", '"},',
            '{"trait_type":"Edition","value":"', tokenId.toString(), '"},',
            '{"trait_type":"Artist","value":"Akihiro Kubota + Zeroichi Arakawa"}',
            ']',
            '}'
        );
        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    function setSeed(uint256 tokenId, uint256 seed) external {
        // require(_ownerOf(tokenId) == msg.sender, "not owner");
        seeds[tokenId] = seed;
    }

    function preview(uint256 seed) external view returns (string memory) {
        return preview(seed, true);
    }

    function preview(uint256 seed, bool wandering) public view returns (string memory) {
        string memory svg = renderer.svg(seed, wandering);
        string memory html = renderer.html(seed, true, wandering);
        string memory json = string.concat(
            '{',
            '"name":"Random Rain 2025 Preview",',
            '"description":"Random Rain 2025 Preview.",',
            '"image":"', svg, '",',
            '"animation_url":"', html, '"',
            '}'
        );
        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    function setDeterministicMode(uint256 tokenId, bool deterministic) external {
        // require(_ownerOf(tokenId) == msg.sender, "not owner");
        deterministicMode[tokenId] = deterministic;
    }

    function setStartWandering(uint256 tokenId, bool wandering) external {
        // require(_ownerOf(tokenId) == msg.sender, "not owner");
        startWandering[tokenId] = wandering;
    }

    function setRenderer(address rendererAddress) external onlyOwner {
        renderer = RandomRainRenderer(rendererAddress);
    }
}
