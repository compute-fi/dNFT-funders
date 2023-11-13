// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract dynNFT is ERC721, ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;
    mapping(uint256 => uint256) private fundSizes; // Mapping to store fund sizes for each NFT

    // Metadata information for each stage of the NFT on IPFS.
    string[] IpfsUri = [
        "https://ipfs.io/ipfs/QmWntXFtDqxPUuMmBbxcRvypZEkWc4WKSRzwx1c6aBjqXu?filename=robotRest.json",
        "https://ipfs.io/ipfs/QmfPKm1AYNqncqP7PmW3y2vrgp7NTqhmcSGwxJx9G5dssF?filename=robotStage1.json",
        "https://ipfs.io/ipfs/QmXWtgRuYJN4uLzw2aiA6twuq5iCE9gKTdR9yPZhjGrYu6?filename=robotStage2.json",
        "https://ipfs.io/ipfs/QmUBKkMtaArdJSgsc246uZJuszk57EJCZLomJGGTSJWDQc?filename=robotStage3.json",
        "https://ipfs.io/ipfs/QmSnZsz8BMbnXwavL5PDWgFyxDAoNbwxtuvbxxhtumaXFC?filename=robotStage4.json"
    ];

    constructor(
        address initialOwner
    ) ERC721("dNFTs", "dNFT") Ownable(initialOwner) {
        _nextTokenId = 1;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    ) external view returns (bool upkeepNeeded, bytes memory performData) {
        for (uint256 i = 1; i < _nextTokenId; i++) {
            uint256 currentFundSize = checkFundSize(i);
            if (currentFundSize != fundSizes[i]) {
                return (true, abi.encode(i));
            }
        }
        return (false, bytes(""));
    }

    function performUpkeep(bytes calldata performData) external {
        uint256 tokenId = abi.decode(performData, (uint256));
        setRobotLvl(tokenId);
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, IpfsUri[0]);
        fundSizes[tokenId] = 0; // Initialize fund size for new NFT
    }

    uint256 private mockFundSize = 0.1 ether;

    function setMockFundSize(uint256 _size) public onlyOwner {
        mockFundSize = _size;
    }

    function checkFundSize(
        uint256 /* tokenId */
    ) public view returns (uint256) {
        // Implement logic to check the actual fund size of the NFT
        // This is a mock implementation
        return mockFundSize;
    }

    function setRobotLvl(uint256 tokenId) public {
        uint256 fundSize = checkFundSize(tokenId);
        uint256 newLevel = determineLevel(fundSize);

        if (checkRobotlvl(tokenId) != newLevel) {
            _setTokenURI(tokenId, IpfsUri[newLevel]);
            fundSizes[tokenId] = fundSize; // Update stored fund size
        }
    }

    // determine the level of the robot
    function determineLevel(uint256 fundSize) public pure returns (uint256) {
        if (fundSize <= 0.1 ether) {
            return 0; // Level 0
        } else if (fundSize <= 0.5 ether) {
            return 1; // Level 1
        } else if (fundSize <= 2.5 ether) {
            return 2; // Level 2
        } else if (fundSize <= 12 ether) {
            return 3; // Level 3
        } else {
            return 4; // Level 4
        }
    }

    function checkRobotlvl(uint256 tokenId) public view returns (uint256) {
        string memory currentUri = tokenURI(tokenId);
        for (uint256 i = 0; i < IpfsUri.length; i++) {
            if (compareStrings(currentUri, IpfsUri[i])) {
                return i; // Returns the level (index) that matches the current URI
            }
        }
        revert("Invalid Token ID or URI not set."); // In case the URI doesn't match any level
    }

    /*
     ********************
     * HELPER FUNCTIONS *
     ********************
     */
    // helper function to compare strings
    function compareStrings(
        string memory a,
        string memory b
    ) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
