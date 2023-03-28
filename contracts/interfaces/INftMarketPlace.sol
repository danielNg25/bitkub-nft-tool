// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INftMarketPlace {
    event CreateTrade(
        uint256 indexed tradeId,
        address indexed nftTokenOwner,
        address indexed nftTokenAddress,
        uint256 nftTokenId,
        uint256 nftType,
        address kap20TokenAddress,
        uint256 price,
        uint256 amount,
        uint256 startTime
    );

    event CloseTrade(uint256 indexed tradeId);

    event CompleteTrade(uint256 indexed tradeId, address indexed userAddressComplete, uint256 amount);

    struct TradeInfo {
        uint256 tradeId;
        address nftTokenOwner;
        address nftTokenAddress;
        uint256 nftTokenId;
        uint256 nftType;
        address kap20TokenAddress;
        uint256 price;
        uint256 startTime;
        uint256 totalAmount;
        uint256 currentAmount;
        address[] userAddressComplete;
        uint256[] amountComplete;
        bool isClose;
    }

    function getTradeInfoById(uint256 _tradeId) external view returns (TradeInfo memory);

    function totalTradeInfo() external view returns (uint256);

    function getOpenTradeIdByPage(uint256 _page, uint256 _limit) external view returns (uint256[] memory);

    function getOpenTradeIdAll() external view returns (uint256[] memory);

    function totalOpenTradeId() external view returns (uint256);

    function createTradeNext(
        address _nftTokenOwner,
        address _nftTokenAddress,
        uint256 _nftTokenId,
        uint256 _nftType,
        address _kap20TokenAddress,
        uint256 _price,
        uint256 _amount,
        uint256 _startTime,
        uint256 _feeAmout
    ) external;

    function createTrade(
        address _nftTokenAddress,
        uint256 _nftTokenId,
        uint256 _nftType,
        address _kap20TokenAddress,
        uint256 _price,
        uint256 _amount,
        uint256 _startTime
    ) external;

    function closeTradeNext(
        uint256 _tradeId,
        address _userAddress,
        uint256 _feeAmount
    ) external;

    function batchCloseTradeNext(
        uint256 _tradeId,
        address _userAddress,
        uint256 _feeAmount
    ) external;

    function closeTrade(uint256 _tradeId) external;

    function completeTradeNext(
        uint256 _tradeId,
        address _userAddressComplete,
        uint256 _amount
    ) external;

    function batchCompleteTradeNext(
        uint256 _tradeId,
        address _userAddressComplete,
        uint256 _amount
    ) external;

    function completeTrade(uint256 _tradeId, uint256 _amount) external;
}