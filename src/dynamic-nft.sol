// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@chainlink/contracts/src/v0.8/AutomationBase.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

interface IERC6551Registry {
    /**
     * @notice Creates a token bound account for a non-fungible token.
     * @param implementation The address of the token bound account proxy
     * @param salt The unique salt value for account creation
     * @param chainId The chain ID of the network
     * @param tokenContract The address of the token contract
     * @param tokenId The token ID for which to create the account
     * @return account The address of the created token bound account
     */
    function createAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (address account);
}

contract dynNFT is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    AutomationCompatible
{
    uint256 private _nextTokenId;
    mapping(uint256 => uint256) private fundSizes; // Mapping to store fund sizes for each NFT
    IERC6551Registry private ERC6551Registry;
    mapping(uint256 => address) private tokenBoundAccountAddresses; // Mapping to store token-bound account addresses for each NFT

    // Metadata information for each stage of the NFT on IPFS.
    string[] IpfsUri = [
        "https://ipfs.io/ipfs/QmWntXFtDqxPUuMmBbxcRvypZEkWc4WKSRzwx1c6aBjqXu?filename=robotRest.json",
        "https://ipfs.io/ipfs/QmfPKm1AYNqncqP7PmW3y2vrgp7NTqhmcSGwxJx9G5dssF?filename=robotStage1.json",
        "https://ipfs.io/ipfs/QmXWtgRuYJN4uLzw2aiA6twuq5iCE9gKTdR9yPZhjGrYu6?filename=robotStage2.json",
        "https://ipfs.io/ipfs/QmUBKkMtaArdJSgsc246uZJuszk57EJCZLomJGGTSJWDQc?filename=robotStage3.json",
        "https://ipfs.io/ipfs/QmSnZsz8BMbnXwavL5PDWgFyxDAoNbwxtuvbxxhtumaXFC?filename=robotStage4.json"
    ];

    // Events
    event Minted(address indexed to, uint256 indexed tokenId);
    event LevelUpdated(uint256 indexed tokenId, uint256 newLevel);
    event FundSizeChanged(uint256 indexed tokenId, uint256 newFundSize);
    event TokenBoundAccountCreated(
        address indexed creator,
        address indexed tokenContract,
        uint256 indexed tokenId,
        address account
    );

    constructor() ERC721("dNFTs", "dNFT") Ownable(msg.sender) {
        _nextTokenId = 1;
        ERC6551Registry = IERC6551Registry(
            0x000000006551c19487814612e58FE06813775758
        );
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        for (uint256 i = 1; i < _nextTokenId; i++) {
            uint256 currentFundSize = checkNewMockFundSize(i);
            if (currentFundSize != fundSizes[i]) {
                return (true, abi.encode(i));
            }
        }
        return (false, bytes(""));
    }

    function performUpkeep(bytes calldata performData) external override {
        uint256 tokenId = abi.decode(performData, (uint256));
        uint256 newFundSize = mockFundSizes[tokenId];
        fundSizes[tokenId] = newFundSize; // Update fundSize with the value from mockFundSize
        setRobotLvl(tokenId);
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, IpfsUri[0]);
        fundSizes[tokenId] = 0; // Initialize fund size for new NFT
        mockFundSizes[tokenId] = 0; // Initialize mock fund size for new NFT

        emit Minted(to, tokenId);
    }

    function publicMint() public payable {
        require(msg.value == 0.001 ether, "Minting fee is 0.001 ETH");
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, IpfsUri[0]);
        fundSizes[tokenId] = 0; // Initialize fund size for new NFT
        mockFundSizes[tokenId] = 0; // Initialize mock fund size for new NFT

        emit Minted(msg.sender, tokenId);
    }

    function checkFundSize(uint256 tokenId) public view returns (uint256) {
        require(ownerOf(tokenId) != address(0), "Token ID does not exist");
        return fundSizes[tokenId];
    }

    function setRobotLvl(uint256 tokenId) public {
        uint256 fundSize = fundSizes[tokenId]; // fundSizes gets updated in performUpkeep
        uint256 newLevel = determineLevel(fundSize);

        if (checkRobotlvl(tokenId) != newLevel) {
            _setTokenURI(tokenId, IpfsUri[newLevel]);
            // fundSizes[tokenId] = fundSize; // Update stored fund size

            emit LevelUpdated(tokenId, newLevel);
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

    function createTokenBoundAccount(uint256 tokenId) external {
        // Generate a unique salt
        uint256 salt = uint256(
            keccak256(abi.encodePacked(tokenId, block.timestamp, msg.sender))
        );

        // Chain ID for Goerli testnet
        uint256 chainId = 5;

        // Create a token-bound account
        address tokenBoundAccount = ERC6551Registry.createAccount(
            0x55266d75D1a14E4572138116aF39863Ed6596E7F, // Tokenbound Account Proxy address
            bytes32(salt),
            chainId,
            address(this), // Token contract address
            tokenId
        );

        // Store the token-bound account address in a mapping
        tokenBoundAccountAddresses[tokenId] = tokenBoundAccount;

        // Emit the event with creator and token contract address
        emit TokenBoundAccountCreated(
            msg.sender,
            address(this),
            tokenId,
            tokenBoundAccount
        );
    }

    /*
     ********************
     * MOCKING  *
     ********************
     */
    // Mocking the change in Funds for testing purposes, this would be funds in a vault on a different contract

    mapping(uint256 => uint256) private mockFundSizes;

    function setMockFundSize(uint256 tokenId, uint256 _size) public {
        require(ownerOf(tokenId) != address(0), "Token ID does not exist");
        mockFundSizes[tokenId] = _size; // Update the mock fund size for the given tokenId

        emit FundSizeChanged(tokenId, _size); // Emit event for the fund size change
    }

    function checkNewMockFundSize(
        uint256 tokenId
    ) public view returns (uint256) {
        require(ownerOf(tokenId) != address(0), "Token ID does not exist");
        return mockFundSizes[tokenId];
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

    // This function will return an array of token IDs owned by a given address
    function tokensOwnedBy(
        address _owner
    ) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // function returns the number of NFTs owned by a specific address
    function ownsAnyNFT(address _owner) public view returns (bool) {
        return balanceOf(_owner) > 0;
    }

    // function is used to check the owner of a specific NFT, identified by its tokenId
    function ownsSpecificNFT(
        address _owner,
        uint256 tokenId
    ) public view returns (bool) {
        try this.ownerOf(tokenId) returns (address tokenOwner) {
            return _owner == tokenOwner;
        } catch {
            return false;
        }
    }

    function getIpfsUriAtIndex(
        uint256 index
    ) public view returns (string memory) {
        require(index < IpfsUri.length, "Index out of bounds");
        return IpfsUri[index];
    }

    // Let the owner of the contract withdraw funds
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool sent, ) = msg.sender.call{value: balance}("");
        require(sent, "Failed to send Ether");
    }

    // Token bound account Address Retrieval Function for a given Token ID
    function getTokenBoundAccountAddress(
        uint256 tokenId
    ) public view returns (address) {
        require(ownerOf(tokenId) != address(0), "Token ID does not exist");
        return tokenBoundAccountAddresses[tokenId];
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
