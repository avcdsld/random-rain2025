// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBefungeViewer {
    function toSVG(string memory code) external view returns (string memory);
    function toHTML(string memory code) external view returns (string memory);
}
