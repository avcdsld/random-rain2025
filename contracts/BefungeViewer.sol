// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IBefungeViewer.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract BefungeViewer is IBefungeViewer {
    function toSVG(string memory code) external view override returns (string memory) {
        // TODO: implement
        return "";
    }
    
    function toHTML(string memory code) external view override returns (string memory) {
        // TODO: implement
        return "";
    }
}
