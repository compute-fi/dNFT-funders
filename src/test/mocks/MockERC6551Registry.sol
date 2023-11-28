// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract MockERC6551Registry {
    function createAccount(
        // address implementation,
        // uint256 chainId,
        // address tokenContract,
        uint256 tokenId,
        uint256 salt
    )
        external
        pure
        returns (
            // bytes calldata initData
            address
        )
    {
        // Mock logic, return a predictable address
        return
            address(
                uint160(uint256(keccak256(abi.encodePacked(tokenId, salt))))
            );
    }
}
