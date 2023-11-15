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

    function testSetRobotLvl() public {
        address mockEOA = address(1); // Mock EOA address
        nft.safeMint(mockEOA);
        uint256 tokenId = 1;
        uint256 mockFundSize = 0.5 ether;
        nft.setMockFundSize(mockFundSize);
        nft.setRobotLvl(tokenId);

        assertEq(
            nft.checkRobotlvl(tokenId),
            1,
            "Robot level should be updated based on fund size"
        );
        assertEq(
            nft.checkFundSize(tokenId),
            mockFundSize,
            "Fund size should be updated"
        );
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

    // Additional tests can be added here for other functions and scenarios
}
