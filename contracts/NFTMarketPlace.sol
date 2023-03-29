// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/INftMarketPlace.sol";
import "./abstracts/token/NftHolder.sol";
import "./abstracts/Pausable.sol";
import "./libraries/EnumerableSetUint.sol";
import "./interfaces/token/IKAP20.sol";
import "./interfaces/token/IKAP721.sol";
import "./interfaces/token/IKAP1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NftMarketPlace is INftMarketPlace, Ownable, Pausable, NftHolder {
    using EnumerableSetUint for EnumerableSetUint.UintSet;

    ///////////////////////////////////////////////////////////////////////////////////////

    TradeInfo[] private _allTradeInfo;
    EnumerableSetUint.UintSet private _openTradeID;

    ///////////////////////////////////////////////////////////////////////////////////////

    constructor() {
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function getTradeInfoById(uint256 _tradeId) external view override returns (TradeInfo memory) {
        return _allTradeInfo[_tradeId - 1];
    }

    function totalTradeInfo() external view override returns (uint256) {
        return _allTradeInfo.length;
    }

    function getOpenTradeIdByPage(uint256 _page, uint256 _limit) external view override returns (uint256[] memory) {
        return _openTradeID.get(_page, _limit);
    }

    function getOpenTradeIdAll() external view override returns (uint256[] memory) {
        return _openTradeID.getAll();
    }

    function totalOpenTradeId() external view override returns (uint256) {
        return _openTradeID.length();
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function approve(
        address _tokenAddress,
        address _spender,
        uint256 _value
    ) external onlyOwner whenNotPaused returns (bool) {
        IKAP20(_tokenAddress).approve(_spender, _value);
        return true;
    }

    function setApprovalForAll(
        address _tokenAddress,
        address _operator,
        bool _approved
    ) external onlyOwner whenNotPaused returns (bool) {
        IKAP1155(_tokenAddress).setApprovalForAll(_operator, _approved);
        return true;
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function createTrade(
        address _nftTokenAddress,
        uint256 _nftTokenId,
        uint256 _nftType,
        address _kap20TokenAddress,
        uint256 _price,
        uint256 _amount,
        uint256 _startTime
    ) external override whenNotPaused {
        _createTrade(
            msg.sender,
            _nftTokenAddress,
            _nftTokenId,
            _nftType,
            _kap20TokenAddress,
            _price,
            _amount,
            _startTime
        );
    }

    function closeTrade(uint256 _tradeId) external override whenNotPaused {
        require(_allTradeInfo[_tradeId - 1].nftTokenOwner == msg.sender, "Not owner of this trade");
        _closeTrade(_tradeId);
    }

    function batchCloseTrade(
        uint256[] memory _tradeIds
    ) external whenNotPaused {
        for (uint256 i = 0; i < _tradeIds.length; i++) {
            if (_allTradeInfo[_tradeIds[i] - 1].nftTokenOwner == msg.sender) {
                _closeTrade(_tradeIds[i]);
            }
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function completeTrade(uint256 _tradeId, uint256 _amount) external override payable whenNotPaused {
        _completeTrade(_tradeId, msg.sender, _amount);
    }

    function batchCompleteTrade(
        uint256[] memory _tradeIds,
        uint256[] memory _amounts
    ) external payable whenNotPaused {
        uint256 length = _tradeIds.length;
        require(length == _amounts.length, "Length not match");
        uint256 totalWeiPrice = 0;
        for (uint256 i = 0; i < length; i++) {
            totalWeiPrice += _completeTrade(_tradeIds[i], msg.sender, _amounts[i]);
        }
        require(msg.value >= totalWeiPrice, "Not enough price");
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function _createTrade(
        address _nftTokenOwner,
        address _nftTokenAddress,
        uint256 _nftTokenId,
        uint256 _nftType,
        address _kap20TokenAddress,
        uint256 _price,
        uint256 _amount,
        uint256 _startTime
    ) internal {
        require(_amount > 0, "Amount must be more than 0");

        if (_nftType == 0) {
            IKAP721(_nftTokenAddress).safeTransferFrom(_nftTokenOwner, address(this), _nftTokenId);
            _amount = 1;
        } else {
            IKAP1155(_nftTokenAddress).safeTransferFrom(_nftTokenOwner, address(this), _nftTokenId, _amount, "");
        }

        _allTradeInfo.push(
            TradeInfo({
                tradeId: _allTradeInfo.length + 1,
                nftTokenOwner: _nftTokenOwner,
                nftTokenAddress: _nftTokenAddress,
                nftTokenId: _nftTokenId,
                nftType: _nftType,
                kap20TokenAddress: _kap20TokenAddress,
                price: _price,
                startTime: _startTime,
                totalAmount: _amount,
                currentAmount: _amount,
                userAddressComplete: new address[](0),
                amountComplete: new uint256[](0),
                isClose: false
            })
        );

        _openTradeID.add(_allTradeInfo.length);

        emit CreateTrade(
            _allTradeInfo.length,
            _nftTokenOwner,
            _nftTokenAddress,
            _nftTokenId,
            _nftType,
            _kap20TokenAddress,
            _price,
            _amount,
            _startTime
        );
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function _closeTrade(uint256 _tradeId) internal {
        TradeInfo storage tradeInfoTmp = _allTradeInfo[_tradeId - 1];
        require(_openTradeID.contains(_tradeId), "Trade is not open");

        _closeTradeInternal(tradeInfoTmp);
    }

    function _closeTradeInternal(TradeInfo storage tradeInfoTmp) internal {
        if (tradeInfoTmp.nftType == 0) {
            IKAP721(tradeInfoTmp.nftTokenAddress).safeTransferFrom(address(this), tradeInfoTmp.nftTokenOwner, tradeInfoTmp.nftTokenId);
        } else {
            IKAP1155(tradeInfoTmp.nftTokenAddress).safeTransferFrom(address(this), tradeInfoTmp.nftTokenOwner, tradeInfoTmp.nftTokenId, tradeInfoTmp.currentAmount, "");
        }

        tradeInfoTmp.isClose = true;
        _openTradeID.remove(tradeInfoTmp.tradeId);

        emit CloseTrade(tradeInfoTmp.tradeId);
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function _completeTrade(
        uint256 _tradeId,
        address _userAddressComplete,
        uint256 _amount
    ) internal returns (uint256) {
        TradeInfo storage tradeInfoTmp = _allTradeInfo[_tradeId - 1];
        require(_openTradeID.contains(_tradeId), "Trade is not open");
        require(block.timestamp > tradeInfoTmp.startTime, "Not time to trade");
        require(_amount > 0, "Amount must be more than 0");
        require(tradeInfoTmp.currentAmount >= _amount, "Insufficient amount");

        return _completeTradeInternal(tradeInfoTmp, _userAddressComplete, _amount);
    }

    function _completeTradeInternal(
        TradeInfo storage tradeInfoTmp,
        address _userAddressComplete,
        uint256 _amount
    ) internal returns (uint256 price) {
        price = tradeInfoTmp.price * _amount;
        if (tradeInfoTmp.kap20TokenAddress != address(0)){
            IKAP20(tradeInfoTmp.kap20TokenAddress).transferFrom(_userAddressComplete, address(this),  price);
            price = 0;
        } else {
            require(msg.value >= price, "Insufficient price amount");
        }

        if (tradeInfoTmp.nftType == 0) {
            IKAP721(tradeInfoTmp.nftTokenAddress).safeTransferFrom(address(this), _userAddressComplete, tradeInfoTmp.nftTokenId);
        } else {
            IKAP1155(tradeInfoTmp.nftTokenAddress).safeTransferFrom(address(this), _userAddressComplete, tradeInfoTmp.nftTokenId, _amount, "");
        }

        tradeInfoTmp.currentAmount -= _amount;
        tradeInfoTmp.userAddressComplete.push(_userAddressComplete);
        tradeInfoTmp.amountComplete.push(_amount);

        if (tradeInfoTmp.currentAmount == 0) {
            tradeInfoTmp.isClose = true;
            _openTradeID.remove(tradeInfoTmp.tradeId);
        }

        emit CompleteTrade(tradeInfoTmp.tradeId, _userAddressComplete, _amount);
    }
}