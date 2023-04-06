// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/interfaces/IAdminProjectRouter.sol


pragma solidity 0.8.0;

interface IAdminProjectRouter {
    function isSuperAdmin(address _addr, string calldata _project) external view returns (bool);

    function isAdmin(address _addr, string calldata _project) external view returns (bool);
}


// File contracts/abstracts/Authorization.sol


pragma solidity 0.8.0;

abstract contract Authorization {
    IAdminProjectRouter public adminRouter;
    string public constant PROJECT = "nft-marketplace";

    event SetAdmin(address indexed oldAdmin, address indexed newAdmin, address indexed caller);

    modifier onlySuperAdmin() {
        require(adminRouter.isSuperAdmin(msg.sender, PROJECT), "Restricted only super admin");
        _;
    }

    modifier onlyAdmin() {
        require(adminRouter.isAdmin(msg.sender, PROJECT), "Restricted only admin");
        _;
    }

    modifier onlySuperAdminOrAdmin() {
        require(
            adminRouter.isSuperAdmin(msg.sender, PROJECT) || adminRouter.isAdmin(msg.sender, PROJECT),
            "Restricted only super admin or admin"
        );
        _;
    }

    function setAdmin(address _adminRouter) external onlySuperAdmin {
        emit SetAdmin(address(adminRouter), _adminRouter, msg.sender);
        adminRouter = IAdminProjectRouter(_adminRouter);
    }
}


// File contracts/abstracts/Pauseable.sol


pragma solidity 0.8.0;

abstract contract Pauseable {
    event Paused(address account);

    event Unpaused(address account);

    bool public paused;

    constructor() {
        paused = false;
    }

    modifier whenNotPaused() {
        require(!paused, "Pauseable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pauseable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal virtual whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }
}


// File contracts/interfaces/token/IKAP721Receiver.sol


pragma solidity 0.8.0;

interface IKAP721Receiver {
    function onKAP721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File contracts/interfaces/token/IKAP1155Receiver.sol


pragma solidity 0.8.0;

interface IKAP1155Receiver {
    function onKAP1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onKAP1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


// File contracts/abstracts/NftHolder.sol


pragma solidity ^0.8.0;


abstract contract NftHolder is IKAP721Receiver, IKAP1155Receiver {
    function onKAP721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onKAP721Received.selector;
    }

    function onKAP1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onKAP1155Received.selector;
    }

    function onKAP1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onKAP1155BatchReceived.selector;
    }
}


// File contracts/interfaces/INftTransferRouterWithViewer.sol


pragma solidity 0.8.0;

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


// File contracts/interfaces/INftMarketPlace.sol


pragma solidity 0.8.0;

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


// File contracts/interfaces/token/IKAP20.sol


pragma solidity 0.8.0;

interface IKAP20 {
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner) external view returns (uint256 balance);

    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);

    function transfer(address to, uint256 tokens) external returns (bool success);

    function approve(address spender, uint256 tokens) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    function getOwner() external view returns (address);

    function batchTransfer(
        address[] calldata _from,
        address[] calldata _to,
        uint256[] calldata _value
    ) external returns (bool success);

    function adminTransfer(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
}


// File contracts/interfaces/token/IKAP165.sol


pragma solidity 0.8.0;

interface IKAP165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File contracts/interfaces/token/IKAP1155.sol


pragma solidity 0.8.0;

interface IKAP1155 is IKAP165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function adminTransfer(
        address sender,
        address recipient,
        uint256 id,
        uint256 amount
    ) external;

    function internalTransfer(
        address sender,
        address recipient,
        uint256 id,
        uint256 amount
    ) external returns (bool);

    function externalTransfer(
        address sender,
        address recipient,
        uint256 id,
        uint256 amount
    ) external returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


// File contracts/libraries/EnumerableSetUint.sol


pragma solidity 0.8.0;

library EnumerableSetUint {
    struct UintSet {
        uint256[] _values;
        mapping(uint256 => uint256) _indexes;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        if (!contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            uint256 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1;
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return set._indexes[value] != 0;
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    function getAll(UintSet storage set) internal view returns (uint256[] memory) {
        return set._values;
    }

    function get(
        UintSet storage set,
        uint256 _page,
        uint256 _limit
    ) internal view returns (uint256[] memory) {
        require(_page > 0 && _limit > 0);
        uint256 tempLength = _limit;
        uint256 cursor = (_page - 1) * _limit;
        uint256 _uintLength = length(set);
        if (cursor >= _uintLength) {
            return new uint256[](0);
        }
        if (tempLength > _uintLength - cursor) {
            tempLength = _uintLength - cursor;
        }
        uint256[] memory uintList = new uint256[](tempLength);
        for (uint256 i = 0; i < tempLength; i++) {
            uintList[i] = at(set, cursor + i);
        }
        return uintList;
    }
}


// File contracts/NftMarketPlace.sol


pragma solidity 0.8.0;






contract NftMarketPlace is INftMarketPlace, Authorization, Pauseable, NftHolder {
    using EnumerableSetUint for EnumerableSetUint.UintSet;

    INftTransferRouterWithViewer public nftTransferRouter;
    bool public isAllowMetamask;

    ///////////////////////////////////////////////////////////////////////////////////////

    TradeInfo[] private _allTradeInfo;
    EnumerableSetUint.UintSet private _openTradeID;

    ///////////////////////////////////////////////////////////////////////////////////////

    constructor(address nftTransferRouter_, address adminRouter_) {
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