// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./abstracts/token/NftHolder.sol";
import "./abstracts/Pausable.sol";
import "./libraries/EnumerableSetUint.sol";
import "./libraries/EnumerableSetAddress.sol";
import "./interfaces/token/IKAP20.sol";
import "./interfaces/token/IKAP721.sol";
import "./interfaces/token/IKAP721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract NftMarketPlace is Ownable, Pausable, NftHolder {
    using EnumerableSetUint for EnumerableSetUint.UintSet;
    using EnumerableSetAddress for EnumerableSetAddress.AddressSet;

    struct TradeInfo {
        uint256 tradeId;
        address nftTokenOwner;
        address nftTokenAddress;
        uint256 nftTypeId;
        EnumerableSetUint.UintSet allTokenId;
        EnumerableSetUint.UintSet remainingTokenId;
        address paymentToken;
        uint256 price;
        uint256 startTime;
    }

    struct TradeInfoReturn {
        uint256 tradeId;
        address nftTokenOwner;
        address nftTokenAddress;
        uint256 nftTypeId;
        uint256[] remainingTokenId;
        uint256 totalSupply;
        string typeIdUri;
        address paymentToken;
        uint256 price;
        uint256 startTime;
    }

    struct TypeIdInfoReturn {
        address storeAddress;
        uint256 typeId;
        string typeIdUri;
        uint256 totalSupply;
        uint256 remaining;
    }
    ///////////////////////////////////////////////////////////////////////////////////////
    uint256 private constant bitOffset = 17;
    uint256 public totalTradeInfo;
    mapping (uint256 => TradeInfo) private _allTradeInfo;
    EnumerableSetUint.UintSet private _openTradeID;
    EnumerableSetAddress.AddressSet private _activeStore;

    mapping (address => EnumerableSetUint.UintSet) private _storeToOpenTypeId;

    mapping (address => mapping(uint256 => uint256)) private _typeIdToTradeIdByStore;

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

    event AddTradeItem(
        uint256 indexed tradeId,
        address indexed nftTokenOwner,
        address indexed nftTokenAddress,
        uint256 nftTypeId,
        uint256 nftTokenId
    );

    event UpdateTrade(
        uint256 indexed tradeId,
        address indexed nftTokenOwner,
        address paymentToken,
        uint256 price,
        uint256 startTime
    );

    event CloseTrade(uint256 indexed tradeId);

    event CompleteTrade(uint256 indexed tradeId, address indexed userAddressComplete, uint256 amount);
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

    function getTradeInfoById(uint256 _tradeId) external view returns (TradeInfoReturn memory) {
        TradeInfo storage tradeInfo = _allTradeInfo[_tradeId - 1];
        return _getTradeInfoReturn(tradeInfo);
    }

    function getOpenTradeIdByPage(uint256 _page, uint256 _limit) external view returns (uint256[] memory) {
        return _openTradeID.get(_page, _limit);
    }

    function getOpenTradeIdAll() external view returns (uint256[] memory) {
        return _openTradeID.getAll();
    }

    function totalOpenTradeId() external view returns (uint256) {
        return _openTradeID.length();
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function getAllActiveStore() external view returns (address[] memory) {
        return _activeStore.getAll();
    }

    function getActiveStoreByPage(uint256 _page, uint256 _limit) external view returns (address[] memory) {
        return _activeStore.get(_page, _limit);
    }

    function totalActiveStore() external view returns (uint256) {
        return _activeStore.length();
    }

    function getAllOpenTradeIdByStore(address _store) external view returns (uint256[] memory) {
        uint256[] memory typeIds = _storeToOpenTypeId[_store].getAll();
        uint256[] memory tradeIds = new uint256[](typeIds.length);
        for (uint256 i = 0; i < typeIds.length; i++) {
            tradeIds[i] = _typeIdToTradeIdByStore[_store][typeIds[i]];
        }
        return tradeIds;
    }
    
    function getOpenTradeIdByStoreByPage(address _store, uint256 _page, uint256 _limit) external view returns (uint256[] memory) {
        uint256[] memory typeIds = _storeToOpenTypeId[_store].get(_page, _limit);
        uint256[] memory tradeIds = new uint256[](typeIds.length);
        for (uint256 i = 0; i < typeIds.length; i++) {
            tradeIds[i] = _typeIdToTradeIdByStore[_store][typeIds[i]];
        }
        return tradeIds;
    }

    function totalOpenTradeByStore(address _store) external view returns (uint256) {
        return _storeToOpenTypeId[_store].length();
    }

    function getAllOpenTradeInfoByStore(address _store) external view returns (TradeInfoReturn[] memory) {
        uint256[] memory typeIds = _storeToOpenTypeId[_store].getAll();
        TradeInfoReturn[] memory tradeInfoReturns = new TradeInfoReturn[](typeIds.length);
        for (uint256 i = 0; i < typeIds.length; i++) {
            uint256 tradeId = _typeIdToTradeIdByStore[_store][typeIds[i]];
            TradeInfo storage tradeInfo = _allTradeInfo[tradeId - 1];
            tradeInfoReturns[i] = _getTradeInfoReturn(tradeInfo);
        }
        return tradeInfoReturns;
    }
    
    function getTypeIdOfStoreByPage(address _store, uint256 _page, uint256 _limit) external view returns (uint256[] memory) {
        return _storeToOpenTypeId[_store].get(_page, _limit);
    }


    function getOpenTradeInfoByStoreByPage(address _store, uint256 _page, uint256 _limit) external view returns (TradeInfoReturn[] memory) {
        uint256[] memory typeIds = _storeToOpenTypeId[_store].get(_page, _limit);
        TradeInfoReturn[] memory tradeInfoReturns = new TradeInfoReturn[](typeIds.length);
        for (uint256 i = 0; i < typeIds.length; i++) {
            uint256 tradeId = _typeIdToTradeIdByStore[_store][typeIds[i]];
            TradeInfo storage tradeInfo = _allTradeInfo[tradeId - 1];
            tradeInfoReturns[i] = _getTradeInfoReturn(tradeInfo);
        }
        return tradeInfoReturns;
    }

    function _getTradeInfoReturn(TradeInfo storage tradeInfo) private view returns (TradeInfoReturn memory) {
        string memory tokenUri = IKAP721Metadata(tradeInfo.nftTokenAddress).tokenURI(tradeInfo.allTokenId.at(0));
        return TradeInfoReturn(
            tradeInfo.tradeId,
            tradeInfo.nftTokenOwner,
            tradeInfo.nftTokenAddress,
            tradeInfo.nftTypeId,
            tradeInfo.remainingTokenId.getAll(),
            tradeInfo.allTokenId.length(),
            tokenUri,
            tradeInfo.paymentToken,
            tradeInfo.price,
            tradeInfo.startTime
        );
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

    ///////////////////////////////////////////////////////////////////////////////////////

    function createTrade(
        address _nftTokenAddress,
        uint256 _nftTokenId,
        address _paymentToken,
        uint256 _price,
        uint256 _startTime
    ) external whenNotPaused {
        _createTrade(
            msg.sender,
            _nftTokenAddress,
            _nftTokenId,
            _paymentToken,
            _price,
            _startTime,
            msg.sender
        );
    }

    function addTradeItem(
        address _nftTokenAddress,
        uint256 _nftTypeId,
        uint256 _nftTokenId
    ) external whenNotPaused {
        _addTradeItem(msg.sender, _nftTokenAddress, _nftTypeId, _nftTokenId);
    }

    function updateTrade(
        uint256 _tradeId,
        address _newNftOwner,
        address _paymentToken,
        uint256 _price,
        uint256 _startTime
    ) external whenNotPaused {
        _updateTrade(_tradeId, _newNftOwner, _paymentToken, _price, _startTime);
    }

    function createTradeAndDelegate(
        address _nftTokenAddress,
        uint256 _nftTokenId,
        address _paymentToken,
        uint256 _price,
        uint256 _startTime,
        address _tradeOperator
    )   external whenNotPaused {
        _createTrade(
            msg.sender,
            _nftTokenAddress,
            _nftTokenId,
            _paymentToken,
            _price,
            _startTime,
            _tradeOperator
        );
    }

    function closeTrade(uint256 _tradeId) external whenNotPaused {
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

    function completeTrade(uint256 _tradeId) external payable whenNotPaused {
        _completeTrade(_tradeId, msg.sender);
    }

    function batchCompleteTrade(
        uint256[] memory _tradeIds
    ) external payable whenNotPaused {
        uint256 length = _tradeIds.length;
        uint256 totalWeiPrice = 0;
        for (uint256 i = 0; i < length; i++) {
            totalWeiPrice += _completeTrade(_tradeIds[i], msg.sender);
        }
        require(msg.value >= totalWeiPrice, "Not enough price");
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function _createTrade(
        address _nftTokenOwner,
        address _nftTokenAddress,
        uint256 _nftTokenId,
        address _paymentToken,
        uint256 _price,
        uint256 _startTime,
        address _tradeOperator
    ) internal {
        IKAP721(_nftTokenAddress).safeTransferFrom(_nftTokenOwner, address(this), _nftTokenId);
        uint256 _typeId = (_nftTokenId >> bitOffset) << bitOffset;
        require(_typeIdToTradeIdByStore[_nftTokenAddress][_typeId] == 0, "This type of NFT is already on sale");
        uint256 tradeId = totalTradeInfo + 1;

        TradeInfo storage tradeInfo = _allTradeInfo[tradeId - 1];
        tradeInfo.tradeId = tradeId;
        tradeInfo.nftTokenOwner = _tradeOperator;
        tradeInfo.nftTokenAddress = _nftTokenAddress;
        tradeInfo.nftTypeId = _typeId;
        tradeInfo.paymentToken = _paymentToken;
        tradeInfo.price = _price;
        tradeInfo.startTime = _startTime;
        tradeInfo.allTokenId.add(_nftTokenId);
        tradeInfo.remainingTokenId.add(_nftTokenId);

        _openTradeID.add(tradeId);
        if(_storeToOpenTypeId[_nftTokenAddress].length() == 0){
            _activeStore.add(_nftTokenAddress);
        }
        
        if (!_storeToOpenTypeId[_nftTokenAddress].contains(_typeId))
        {
            _storeToOpenTypeId[_nftTokenAddress].add(_typeId);
        }
        _typeIdToTradeIdByStore[_nftTokenAddress][_typeId] = tradeId;
        totalTradeInfo++;
        emit CreateTrade(
            tradeId,
            _tradeOperator,
            _nftTokenAddress,
            _nftTokenId,
            _typeId,
            _paymentToken,
            _price,
            1,
            _startTime
        );
    }

    function _addTradeItem(
        address _nftTokenOwner,
        address _nftTokenAddress,
        uint256 _nftTypeId,
        uint256 _nftTokenId
    ) internal {
        uint256 _typeId = (_nftTokenId >> bitOffset) << bitOffset;
        require(_typeId == _nftTypeId, "Type Id is not match");
        uint256 tradeId = _typeIdToTradeIdByStore[_nftTokenAddress][_typeId];
        require(tradeId != 0, "Use createTrade instead");
        TradeInfo storage tradeInfo = _allTradeInfo[tradeId - 1];
        IKAP721(_nftTokenAddress).safeTransferFrom(_nftTokenOwner, address(this), _nftTokenId);
        if (!tradeInfo.allTokenId.contains(_nftTokenId))
        {
            tradeInfo.allTokenId.add(_nftTokenId);
        }
        tradeInfo.remainingTokenId.add(_nftTokenId);
        emit AddTradeItem(
            tradeId,
            _nftTokenOwner,
            _nftTokenAddress,
            _typeId,
            _nftTokenId
        );

        emit CreateTrade(
            tradeId,
            tradeInfo.nftTokenOwner,
            _nftTokenAddress,
            _nftTokenId,
            _typeId,
            tradeInfo.paymentToken,
            tradeInfo.price,
            1,
            tradeInfo.startTime
        );
    }

    function _updateTrade(
        uint256 _tradeId,
        address _nftTokenOwner,
        address _paymentToken,
        uint256 _price,
        uint256 _startTime
    ) internal {
        TradeInfo storage tradeInfo = _allTradeInfo[_tradeId - 1];
        require(tradeInfo.nftTokenOwner == msg.sender, "Not owner of this trade");
        tradeInfo.nftTokenOwner = _nftTokenOwner;
        tradeInfo.paymentToken = _paymentToken;
        tradeInfo.price = _price;
        tradeInfo.startTime = _startTime;
        emit UpdateTrade(
            _tradeId,
            tradeInfo.nftTokenOwner,
            tradeInfo.paymentToken,
            tradeInfo.price,
            tradeInfo.startTime
        );
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function _closeTrade(uint256 _tradeId) internal {
        TradeInfo storage tradeInfoTmp = _allTradeInfo[_tradeId - 1];
        require(_openTradeID.contains(_tradeId), "Trade is not open");

        _closeTradeInternal(tradeInfoTmp);
    }

    function _closeTradeInternal(TradeInfo storage tradeInfoTmp) internal {
        address nftTokenAddress = tradeInfoTmp.nftTokenAddress;
        console.log(tradeInfoTmp.tradeId);

        uint256 length = tradeInfoTmp.remainingTokenId.length();
        for (uint i = 0; i < length; i++) {
            uint256 tokenId = tradeInfoTmp.remainingTokenId.at(0);
            IKAP721(nftTokenAddress).safeTransferFrom(address(this), tradeInfoTmp.nftTokenOwner, tokenId);
            tradeInfoTmp.remainingTokenId.remove(tokenId);
        }
        console.log(tradeInfoTmp.nftTypeId);
        _storeToOpenTypeId[nftTokenAddress].remove(tradeInfoTmp.nftTypeId);
        _openTradeID.remove(tradeInfoTmp.tradeId);

        emit CloseTrade(tradeInfoTmp.tradeId);
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function _completeTrade(
        uint256 _tradeId,
        address _userAddressComplete
    ) internal returns (uint256) {
        TradeInfo storage tradeInfoTmp = _allTradeInfo[_tradeId - 1];
        require(_openTradeID.contains(_tradeId), "Trade is not open");
        require(block.timestamp > tradeInfoTmp.startTime, "Not time to trade");

        return _completeTradeInternal(tradeInfoTmp, _userAddressComplete);
    }

    function _completeTradeInternal(
        TradeInfo storage tradeInfoTmp,
        address _userAddressComplete
    ) internal returns (uint256 price) {
        price = tradeInfoTmp.price;
        address nftTokenAddress = tradeInfoTmp.nftTokenAddress;
        if (tradeInfoTmp.paymentToken != address(0)){
            IKAP20(tradeInfoTmp.paymentToken).transferFrom(_userAddressComplete, tradeInfoTmp.nftTokenOwner,  price);
            price = 0;
        } else {
            require(msg.value >= price, "Insufficient price amount");
            payable(tradeInfoTmp.nftTokenOwner).transfer(price);
        }

        uint256 tokenId = tradeInfoTmp.remainingTokenId.at(0);
        IKAP721(nftTokenAddress).safeTransferFrom(address(this), _userAddressComplete, tokenId);

        tradeInfoTmp.remainingTokenId.remove(tokenId);
        if (tradeInfoTmp.remainingTokenId.length() == 0){
            _storeToOpenTypeId[nftTokenAddress].remove(tradeInfoTmp.nftTypeId);
            _openTradeID.remove(tradeInfoTmp.tradeId);
        }

        if(_storeToOpenTypeId[nftTokenAddress].length() == 0){
            _activeStore.remove(nftTokenAddress);
        }

        emit CompleteTrade(tradeInfoTmp.tradeId, _userAddressComplete, 1);
    }
}