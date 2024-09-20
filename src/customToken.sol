// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

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
        address creator,
        uint256 initialSupply
    ) ERC20(name, symbol) Ownable(creator) {
        _tokenInfo = TokenInfo({
            name: name,
            symbol: symbol,
            description: description,
            imageUrl: imageUrl,
            twitter: twitter,
            telegram: telegram,
            website: website,
            mainEngineAddress: creator,
            mintingDisabled: true,
            creator: msg.sender
        });

        _mint(creator, initialSupply);
    }

    /// @notice Returns all token information
    function getTokenInfo() public view returns (TokenInfo memory) {
        return _tokenInfo;
    }

    /// @notice Returns the name of the token
    function getName() public view returns (string memory) {
        return _tokenInfo.name;
    }

    /// @notice Returns the symbol of the token
    function getSymbol() public view returns (string memory) {
        return _tokenInfo.symbol;
    }

    /// @notice Returns the description of the token
    function getDescription() public view returns (string memory) {
        return _tokenInfo.description;
    }

    /// @notice Returns the image URL of the token
    function getImageUrl() public view returns (string memory) {
        return _tokenInfo.imageUrl;
    }

    /// @notice Returns the Twitter URL of the token
    function getTwitter() public view returns (string memory) {
        return _tokenInfo.twitter;
    }

    /// @notice Returns the Telegram URL of the token
    function getTelegram() public view returns (string memory) {
        return _tokenInfo.telegram;
    }

    /// @notice Returns the website URL of the token
    function getWebsite() public view returns (string memory) {
        return _tokenInfo.website;
    }

    /// @notice Returns the main engine address
    function getMainEngineAddress() public view returns (address) {
        return _tokenInfo.mainEngineAddress;
    }

    /// @notice Checks if minting is disabled
    function isMintingDisabled() public view returns (bool) {
        return _tokenInfo.mintingDisabled;
    }
}
