// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INftTransferRouterWithViewer {
    function transferKAP20(
        address tokenAddress,
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferKAP721(
        address tokenAddress,
        address sender,
        address recipient,
        uint256 tokenId,
        uint256 feeAmount
    ) external returns (bool);

    function transferKAP1155(
        address tokenAddress,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        uint256 feeAmount
    ) external returns (bool);

    function transferKAP20WhenComplete(
        address nftTokenAddress,
        uint256 nftTokenId,
        address tokenAddress,
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function feeWallet() external view returns (address);

    function feePercent() external view returns (uint256);

    function kkubToken() external view returns (address);
}