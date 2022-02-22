
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPokeBallNFT {
    function isApproved(uint256 _tokenId, address _spender) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
    function exists(uint256 _tokenId) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function totalSupply() external view returns (uint256);
    function latestBallId() external view returns (uint256);
    function latestTokenId() external view returns (uint256);
}