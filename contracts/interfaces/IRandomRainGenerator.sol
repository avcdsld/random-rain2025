// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRandomRainGenerator {
    function generateCode(uint256 seed) external view returns (string memory);
}
