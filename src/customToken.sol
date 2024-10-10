// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CustomToken is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        string memory description,
        string memory imageUrl,
        string memory twitter,
        string memory telegram,
        string memory website,
        address mainEngine,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(mainEngine, initialSupply);
    }
}
