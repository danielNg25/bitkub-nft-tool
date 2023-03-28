// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/INftMarketPlace.sol";
import "./abstracts/project/Authorization.sol";
import "./abstracts/token/NftHolder.sol";
import "./abstracts/Pausable.sol";
import "./libraries/EnumerableSetUint.sol";
import "./interfaces/INftTransferRouterWithView.sol";
import "./interfaces/token/IKAP20.sol";
import "./interfaces/token/IKAP1155.sol";

contract NftMarketPlace is INftMarketPlace, Authorization, Pausable, NftHolder {
    using EnumerableSetUint for EnumerableSetUint.UintSet;

    INftTransferRouterWithViewer public nftTransferRouter;
    bool public isAllowMetamask;

    ///////////////////////////////////////////////////////////////////////////////////////

    TradeInfo[] private _allTradeInfo;
    EnumerableSetUint.UintSet private _openTradeID;

    ///////////////////////////////////////////////////////////////////////////////////////

    constructor(address nftTransferRouter_, address adminRouter_) Authorization("bitkub-tool-marketplace") {
        nftTransferRouter = INftTransferRouterWithViewer(nftTransferRouter_);
        adminRouter = IAdminProjectRouter(adminRouter_);
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    modifier whenAllowMetamask() {
        require(isAllowMetamask == true, "Restricted only bitkub next");
        _;
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function setNftTransferRouter(address _nftTransferRouter) external onlySuperAdmin {
        nftTransferRouter = INftTransferRouterWithViewer(_nftTransferRouter);
    }

    function setIsAllowMetamask(bool _isAllowMetamask) external onlySuperAdmin {
        isAllowMetamask = _isAllowMetamask;
    }

    function pause() external onlySuperAdmin {
        _pause();
    }

    function unpause() external onlySuperAdmin {
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
    ) external onlySuperAdmin whenNotPaused returns (bool) {
        IKAP20(_tokenAddress).approve(_spender, _value);
        return true;
    }

    function setApprovalForAll(
        address _tokenAddress,
        address _operator,
        bool _approved
    ) external onlySuperAdmin whenNotPaused returns (bool) {
        IKAP1155(_tokenAddress).setApprovalForAll(_operator, _approved);
        return true;
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function createTradeNext(
        address _nftTokenOwner,
        address _nftTokenAddress,
        uint256 _nftTokenId,
        uint256 _nftType,
        address _kap20TokenAddress,
        uint256 _price,
        uint256 _amount,
        uint256 _startTime,
        uint256 _feeAmount
    ) external override onlySuperAdmin whenNotPaused {
        _createTrade(
            _nftTokenOwner,
            _nftTokenAddress,
            _nftTokenId,
            _nftType,
            _kap20TokenAddress,
            _price,
            _amount,
            _startTime,
            _feeAmount
        );
    }

    function createTrade(
        address _nftTokenAddress,
        uint256 _nftTokenId,
        uint256 _nftType,
        address _kap20TokenAddress,
        uint256 _price,
        uint256 _amount,
        uint256 _startTime
    ) external override whenAllowMetamask whenNotPaused {
        _createTrade(
            msg.sender,
            _nftTokenAddress,
            _nftTokenId,
            _nftType,
            _kap20TokenAddress,
            _price,
            _amount,
            _startTime,
            0
        );
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function closeTradeNext(
        uint256 _tradeId,
        address _userAddress,
        uint256 _feeAmount
    ) external override onlySuperAdmin whenNotPaused {
        require(_allTradeInfo[_tradeId - 1].nftTokenOwner == _userAddress, "Not owner of this trade");

        if (_feeAmount > 0) {
            nftTransferRouter.transferKAP20(
                nftTransferRouter.kkubToken(),
                _allTradeInfo[_tradeId - 1].nftTokenOwner,
                nftTransferRouter.feeWallet(),
                _feeAmount
            );
        }

        _closeTrade(_tradeId);
    }

    function batchCloseTradeNext(
        uint256 _tradeId,
        address _userAddress,
        uint256 _feeAmount
    ) external override onlySuperAdmin whenNotPaused {
        if (_allTradeInfo[_tradeId - 1].nftTokenOwner == _userAddress) {
            if (_feeAmount > 0) {
                nftTransferRouter.transferKAP20(
                    nftTransferRouter.kkubToken(),
                    _allTradeInfo[_tradeId - 1].nftTokenOwner,
                    nftTransferRouter.feeWallet(),
                    _feeAmount
                );
            }
            _batchCloseTrade(_tradeId);
        }
    }

    function closeTrade(uint256 _tradeId) external override whenAllowMetamask whenNotPaused {
        require(_allTradeInfo[_tradeId - 1].nftTokenOwner == msg.sender, "Not owner of this trade");
        _closeTrade(_tradeId);
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function completeTradeNext(
        uint256 _tradeId,
        address _userAddressComplete,
        uint256 _amount
    ) external override onlySuperAdmin whenNotPaused {
        _completeTrade(_tradeId, _userAddressComplete, _amount);
    }

    function batchCompleteTradeNext(
        uint256 _tradeId,
        address _userAddressComplete,
        uint256 _amount
    ) external override onlySuperAdmin whenNotPaused {
        _batchCompleteTrade(_tradeId, _userAddressComplete, _amount);
    }

    function completeTrade(uint256 _tradeId, uint256 _amount) external override whenAllowMetamask whenNotPaused {
        _completeTrade(_tradeId, msg.sender, _amount);
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
        uint256 _startTime,
        uint256 _feeAmount
    ) internal {
        require(_amount > 0, "Amount must be more than 0");

        if (_nftType == 0) {
            nftTransferRouter.transferKAP721(_nftTokenAddress, _nftTokenOwner, address(this), _nftTokenId, _feeAmount);
            _amount = 1;
        } else {
            nftTransferRouter.transferKAP1155(
                _nftTokenAddress,
                _nftTokenOwner,
                address(this),
                _nftTokenId,
                _amount,
                _feeAmount
            );
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

    function _batchCloseTrade(uint256 _tradeId) internal {
        TradeInfo storage tradeInfoTmp = _allTradeInfo[_tradeId - 1];

        if (!_openTradeID.contains(_tradeId)) {
            return;
        }

        _closeTradeInternal(tradeInfoTmp);
    }

    function _closeTradeInternal(TradeInfo storage tradeInfoTmp) internal {
        if (tradeInfoTmp.nftType == 0) {
            nftTransferRouter.transferKAP721(
                tradeInfoTmp.nftTokenAddress,
                address(this),
                tradeInfoTmp.nftTokenOwner,
                tradeInfoTmp.nftTokenId,
                0
            );
        } else {
            nftTransferRouter.transferKAP1155(
                tradeInfoTmp.nftTokenAddress,
                address(this),
                tradeInfoTmp.nftTokenOwner,
                tradeInfoTmp.nftTokenId,
                tradeInfoTmp.currentAmount,
                0
            );
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
    ) internal {
        TradeInfo storage tradeInfoTmp = _allTradeInfo[_tradeId - 1];
        require(_openTradeID.contains(_tradeId), "Trade is not open");
        require(block.timestamp > tradeInfoTmp.startTime, "Not time to trade");
        require(_amount > 0, "Amount must be more than 0");
        require(tradeInfoTmp.currentAmount >= _amount, "Insufficient amount");

        _completeTradeInternal(tradeInfoTmp, _userAddressComplete, _amount);
    }

    function _batchCompleteTrade(
        uint256 _tradeId,
        address _userAddressComplete,
        uint256 _amount
    ) internal {
        TradeInfo storage tradeInfoTmp = _allTradeInfo[_tradeId - 1];

        if (!_openTradeID.contains(_tradeId)) {
            return;
        }

        if (block.timestamp <= tradeInfoTmp.startTime) {
            return;
        }

        if (_amount == 0) {
            return;
        }

        if (tradeInfoTmp.currentAmount < _amount) {
            return;
        }

        _completeTradeInternal(tradeInfoTmp, _userAddressComplete, _amount);
    }

    function _completeTradeInternal(
        TradeInfo storage tradeInfoTmp,
        address _userAddressComplete,
        uint256 _amount
    ) internal {
        nftTransferRouter.transferKAP20(
            tradeInfoTmp.kap20TokenAddress,
            _userAddressComplete,
            address(this),
            tradeInfoTmp.price * _amount
        );

        nftTransferRouter.transferKAP20WhenComplete(
            tradeInfoTmp.nftTokenAddress,
            tradeInfoTmp.nftTokenId,
            tradeInfoTmp.kap20TokenAddress,
            address(this),
            tradeInfoTmp.nftTokenOwner,
            tradeInfoTmp.price * _amount
        );

        if (tradeInfoTmp.nftType == 0) {
            nftTransferRouter.transferKAP721(
                tradeInfoTmp.nftTokenAddress,
                address(this),
                _userAddressComplete,
                tradeInfoTmp.nftTokenId,
                0
            );
        } else {
            nftTransferRouter.transferKAP1155(
                tradeInfoTmp.nftTokenAddress,
                address(this),
                _userAddressComplete,
                tradeInfoTmp.nftTokenId,
                _amount,
                0
            );
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