// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {HelperConfig} from "script/HelperConfig.sol";
import {dynNFT} from "src/dynamic-nft.sol";

contract dynNFTTest is Test {
    dynNFT public nft;
    address owner;

    function setUp() public {
        nft = new dynNFT();
        owner = address(this);
    }

    function testSafeMint() public {
        address to = address(1);
        nft.safeMint(to);

        string memory expectedInitialUri = nft.getIpfsUriAtIndex(0);

        assertEq(nft.ownerOf(1), to, "Owner should be set correctly");
        assertEq(
            nft.tokenURI(1),
            expectedInitialUri,
            "Token URI should match initial value"
        );
        assertEq(
            nft.checkFundSize(1),
            0,
            "Fund size should be initialized to 0"
        );
    }

    function testSafeMintByNonOwnerShouldFail() public {
        address nonOwner = address(2);
        vm.prank(nonOwner); // Simulate call from non-owner
        vm.expectRevert(); // Expect any revert
        nft.safeMint(nonOwner);
    }

    function testPublicMintWithCorrectFee() public {
        uint256 mintingFee = 0.1 ether;
        address recipient = address(1); // Regular address, not a contract
        vm.deal(recipient, mintingFee); // Ensure the recipient has enough ETH

        vm.prank(recipient); // Simulate call from the recipient address
        nft.publicMint{value: mintingFee}(); // Mint without passing recipient as an argument

        uint256 mintedTokenId = nft.totalSupply();
        assertEq(
            nft.ownerOf(mintedTokenId),
            recipient,
            "Token should be minted to the recipient"
        );
    }

    function testPublicMintWithInsufficientFeeShouldFail() public {
        uint256 insufficientFee = 0.05 ether;
        address recipient = address(1); // Regular address, not a contract
        vm.deal(recipient, insufficientFee); // Ensure the recipient has enough ETH

        vm.prank(recipient); // Simulate call from the recipient address
        vm.expectRevert(); // Expect any revert
        nft.publicMint{value: insufficientFee}(); // Mint without passing recipient as an argument
    }

    function testSetMockFundSize() public {
        address mockEOA = address(1); // Mock EOA address
        nft.safeMint(mockEOA);
        uint256 tokenId = 1;
        uint256 mockFundSize = 0.5 ether;
        nft.setMockFundSize(tokenId, mockFundSize);

        assertEq(
            nft.checkNewMockFundSize(tokenId),
            mockFundSize,
            "Mock fund size should be updated correctly"
        );
    }

    function testCheckFundSizeWithValidTokenId() public {
        uint256 tokenId = 1;
        uint256 mockFundSize = 1 ether;
        address recipient = address(1);

        nft.safeMint(recipient);
        nft.setMockFundSize(tokenId, mockFundSize);

        assertEq(
            nft.checkNewMockFundSize(tokenId),
            mockFundSize,
            "Mock fund size should match the set value"
        );
    }

    function testCheckFundSizeWithInvalidTokenIdShouldFail() public {
        uint256 invalidTokenId = 999;
        vm.expectRevert(); // Expect any revert
        nft.checkFundSize(invalidTokenId);
    }

    function testSetRobotLvl() public {
        address mockEOA = address(1); // Mock EOA address
        nft.safeMint(mockEOA);
        uint256 tokenId = 1;
        uint256 mockFundSize = 0.5 ether;
        nft.setMockFundSize(tokenId, mockFundSize);

        // Simulate performUpkeep to update fundSizes
        nft.performUpkeep(abi.encode(tokenId));

        nft.setRobotLvl(tokenId);

        assertEq(
            nft.checkRobotlvl(tokenId),
            1,
            "Robot level should be updated based on the updated fund size"
        );
    }

    function testSetRobotLvlWithInvalidTokenIdShouldFail() public {
        uint256 invalidTokenId = 999;
        vm.expectRevert(); // Expect any revert
        nft.setRobotLvl(invalidTokenId);
    }

    function testDetermineLevel() public {
        assertEq(
            nft.determineLevel(0.05 ether),
            0,
            "Level should be 0 for fund size <= 0.1 ether"
        );
        assertEq(
            nft.determineLevel(0.3 ether),
            1,
            "Level should be 1 for fund size <= 0.5 ether"
        );
        assertEq(
            nft.determineLevel(1 ether),
            2,
            "Level should be 2 for fund size <= 2.5 ether"
        );
        assertEq(
            nft.determineLevel(6 ether),
            3,
            "Level should be 3 for fund size <= 12 ether"
        );
        assertEq(
            nft.determineLevel(20 ether),
            4,
            "Level should be 4 for fund size > 12 ether"
        );
    }

    function testUriUpdateWithLevelChange() public {
        uint256 tokenId = 1;
        address recipient = address(1);
        nft.safeMint(recipient);

        // Changing the fund size to update the level
        uint256 newFundSize = 2 ether; // updates the level
        nft.setMockFundSize(tokenId, newFundSize);
        nft.setRobotLvl(tokenId);

        uint256 newLevel = nft.checkRobotlvl(tokenId);
        string memory expectedNewUri = nft.getIpfsUriAtIndex(newLevel);
        assertEq(
            nft.tokenURI(tokenId),
            expectedNewUri,
            "URI should be updated to match the new level"
        );
    }

    function testCompareStringsIdentical() public {
        string memory string1 = "Hello, World!";
        string memory string2 = "Hello, World!";

        bool result = nft.compareStrings(string1, string2);
        assertTrue(result, "Identical strings should return true");
    }

    function testCompareStringsDifferent() public {
        string memory string1 = "Hello, World!";
        string memory string2 = "Goodbye, World!";

        bool result = nft.compareStrings(string1, string2);
        assertFalse(result, "Different strings should return false");
    }

    function testCompareStringsEmpty() public {
        string memory string1 = "";
        string memory string2 = "";

        bool result = nft.compareStrings(string1, string2);
        assertTrue(result, "Empty strings should return true");
    }

    function testTokensOwnedByWithMultipleTokens() public {
        address _owner = address(1);
        uint256[] memory expectedTokenIds = new uint256[](3);

        for (uint256 i = 0; i < 3; i++) {
            nft.safeMint(_owner);
            expectedTokenIds[i] = i + 1; // Assuming token IDs start from 1
        }

        uint256[] memory actualTokenIds = nft.tokensOwnedBy(_owner);
        for (uint256 i = 0; i < 3; i++) {
            assertEq(
                actualTokenIds[i],
                expectedTokenIds[i],
                "Token ID should match expected value"
            );
        }
    }

    function testTokensOwnedByWithNoTokens() public {
        address _owner = address(2);
        uint256[] memory actualTokenIds = nft.tokensOwnedBy(_owner);
        assertEq(
            actualTokenIds.length,
            0,
            "Owner with no tokens should have an empty array"
        );
    }

    function testTokensOwnedByWithSingleToken() public {
        address _owner = address(3);
        nft.safeMint(_owner);
        uint256[] memory actualTokenIds = nft.tokensOwnedBy(_owner);

        assertEq(
            actualTokenIds.length,
            1,
            "Array length should be 1 for a single token"
        );
        assertEq(
            actualTokenIds[0],
            1,
            "Token ID should be 1 for the first minted token"
        );
    }

    function testOwnsAnyNFTWithNoNFTs() public {
        address noNftOwner = address(1);
        bool result = nft.ownsAnyNFT(noNftOwner);
        assertFalse(
            result,
            "Should return false for an address owning no NFTs"
        );
    }

    function testOwnsAnyNFTWithNFTs() public {
        address nftOwner = address(2);
        nft.safeMint(nftOwner); // Mint an NFT to this address

        bool result = nft.ownsAnyNFT(nftOwner);
        assertTrue(result, "Should return true for an address owning NFTs");
    }

    function testOwnsSpecificNFTWithOwner() public {
        address _owner = address(1);
        uint256 tokenId = 1;
        nft.safeMint(_owner);

        bool result = nft.ownsSpecificNFT(_owner, tokenId);
        assertTrue(result, "Owner should own the specific NFT");
    }

    function testOwnsSpecificNFTWithNonOwner() public {
        address _owner = address(1);
        address nonOwner = address(2);
        uint256 tokenId = 1;
        nft.safeMint(_owner);

        bool result = nft.ownsSpecificNFT(nonOwner, tokenId);
        assertFalse(result, "Non-owner should not own the specific NFT");
    }

    function testOwnsSpecificNFTWithNonExistentToken() public {
        address _owner = address(1);
        uint256 nonExistentTokenId = 999;

        bool result = nft.ownsSpecificNFT(_owner, nonExistentTokenId);
        assertFalse(result, "Should return false for non-existent token ID");
    }

    function testGetIpfsUriAtIndexWithValidIndex() public {
        uint256 validIndex = 0; // Adjust according to your contract's data
        string
            memory expectedUri = "https://ipfs.io/ipfs/QmWntXFtDqxPUuMmBbxcRvypZEkWc4WKSRzwx1c6aBjqXu?filename=robotRest.json"; // Replace with the actual URI for this index

        string memory actualUri = nft.getIpfsUriAtIndex(validIndex);
        assertEq(
            actualUri,
            expectedUri,
            "URI should match the expected value for valid index"
        );
    }

    function testGetIpfsUriAtIndexWithInvalidIndexShouldFail() public {
        uint256 invalidIndex = 999; // An index that is out of bounds

        vm.expectRevert("Index out of bounds");
        nft.getIpfsUriAtIndex(invalidIndex);
    }
}
