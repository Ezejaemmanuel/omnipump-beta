// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
//make deploy ARGS="--network sepolia"
/// @title CustomToken
/// @notice This contract implements a custom ERC20 token with additional metadata

contract CustomToken is ERC20, Ownable {
    struct TokenInfo {
        string name;
        string symbol;
        string description;
        string imageUrl;
        string twitter;
        string telegram;
        string website;
        address mainEngineAddress;
        bool mintingDisabled;
        address creator;
    }

    TokenInfo private _tokenInfo;

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
    ) ERC20(name, symbol) Ownable(mainEngine) {
        _tokenInfo = TokenInfo({
            name: name,
            symbol: symbol,
            description: description,
            imageUrl: imageUrl,
            twitter: twitter,
            telegram: telegram,
            website: website,
            mainEngineAddress: mainEngine,
            mintingDisabled: true,
            creator: msg.sender
        });

        _mint(mainEngine, initialSupply);
    }

  
}
