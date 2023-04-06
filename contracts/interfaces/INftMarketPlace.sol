// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INftMarketPlace {
    function createTrade(
        address _nftTokenAddress,
        uint256 _nftTokenId,
        address _paymentToken,
        uint256 _price,
        uint256 _startTime
    ) external;

    function addTradeItem(
        address _nftTokenAddress,
        uint256 _nftTypeId,
        uint256 _nftTokenId
    ) external;

    function updateTrade(
        uint256 _tradeId,
        address _newNftOwner,
        address _paymentToken,
        uint256 _price,
        uint256 _startTime
    ) external;

    function createTradeAndDelegate(
        address _nftTokenAddress,
        uint256 _nftTokenId,
        address _paymentToken,
        uint256 _price,
        uint256 _startTime,
        address _tradeOperator
    ) external;

    function batchCloseTrade(
        uint256[] memory _tradeIds
    ) external;

    function closeTrade(uint256 _tradeId) external;

    function batchCompleteTrade(
        uint256[] memory _tradeIds
    ) external payable;

    function completeTrade(uint256 _tradeId) external payable;
}