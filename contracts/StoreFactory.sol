// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./token/Store.sol";
import "./abstracts/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/INftMarketPlace.sol";

contract StoreFactory is 
    Ownable,
    Pausable 
{
    string public project;
    address public adminRouter;
    address public transferRouter;
    INftMarketPlace public nftMarketPlace;
    uint256 public totalStore;
    uint256 private constant bitOffset = 17;
    struct StoreInfo {
        string name;
        string image;
        string profile;
        string description;
        address storeAddress;
        uint256 currentTypeIdIndex;
    }

    struct StoreInfoReturn {
        uint256 storeId;
        string name;
        string image;
        string profile;
        string description;
        address storeAddress;
        uint256 totalSupply;
    }

    mapping(uint256 => StoreInfo) private stores;

    /* ========== EVENTS ========== */

    event StoreCreated(
        uint256 indexed storeId,
        string name,
        string image,
        string profile,
        string description,
        address storeAddress,
        address indexed caller
    );

    event MintedAndListed(
        uint256 indexed storeId,
        uint256 indexed typeId,
        uint256[] tokenIds,
        address indexed caller
    );

    constructor(
        string memory project_,
        address _adminRouter,
        address _transferRouter,
        address _nftMarketPlace
    ) {
        adminRouter = _adminRouter;
        transferRouter = _transferRouter;
        project = project_;
        nftMarketPlace = INftMarketPlace(_nftMarketPlace);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createStore(
        string calldata _name,
        string calldata _symbol,
        string calldata _image,
        string calldata _profile,
        string calldata _description
    ) external onlyOwner {
        uint256 storeIndex = totalStore;
        Store store = new Store(
            _name,
            _symbol,
            project,
            "",
            transferRouter,
            address(adminRouter),
            owner()
        );
        address storeAddress = address(store);
        stores[storeIndex] = StoreInfo(_name, _image, _profile, _description, storeAddress, 0);
        totalStore++;
        emit StoreCreated(storeIndex, _name, _image, _profile, _description, storeAddress, msg.sender);
    }

    function mintAndListExistingTypeId(
        uint256 _storeId,
        uint256 _typeId,
        uint256 _amount
    ) external onlyOwner {
        require(_storeId < totalStore, "StoreFactory: invalid storeId");
        require(_amount > 0, "StoreFactory: invalid amount");
        StoreInfo memory storeInfo = stores[_storeId];
        require((_typeId >> bitOffset) < storeInfo.currentTypeIdIndex, "StoreFactory: invalid typeId");
        if (_amount == 1) {
            uint256 tokenId = Store(storeInfo.storeAddress).mintByTypeId(address(this), _typeId);
            _listOnSale(storeInfo.storeAddress, tokenId, _typeId);
            uint256[] memory tokenIds = new uint256[](1);
            tokenIds[0] = tokenId;
            emit MintedAndListed(_storeId, _typeId, tokenIds, msg.sender);
        } else {
            uint256[] memory tokenIds = Store(storeInfo.storeAddress).mintBatchByTypeId(address(this), _typeId, _amount);
            for (uint256 i = 0; i < _amount; i++) {
                _listOnSale(storeInfo.storeAddress, tokenIds[i], _typeId);
            }
            emit MintedAndListed(_storeId, _typeId, tokenIds, msg.sender);
        }
    }

    function mintAndListNewTypeId(
        uint256 _storeId,
        string calldata _typeIdURI,
        uint256 _amount,
        uint256 _price,
        address _paymentToken,
        uint256 _startTime
    ) external onlyOwner {
        require(_storeId < totalStore, "StoreFactory: invalid storeId");
        require(_amount > 0, "StoreFactory: invalid amount");
        StoreInfo memory storeInfo = stores[_storeId];
        Store store = Store(storeInfo.storeAddress);
        uint256 _typeId = storeInfo.currentTypeIdIndex << bitOffset;
        store.setTypeURI(_typeId, _typeIdURI);

        if (_amount == 1) {
            uint256 tokenId = store.mintByTypeId(address(this), _typeId);
            _initialListTypeIdOnSale(storeInfo.storeAddress, tokenId, _price, _paymentToken, _startTime);
            uint256[] memory tokenIds = new uint256[](1);
            tokenIds[0] = tokenId;
            emit MintedAndListed(_storeId, _typeId, tokenIds, msg.sender);
        } else {
            uint256[] memory tokenIds = store.mintBatchByTypeId(address(this), _typeId, _amount);
            _initialListTypeIdOnSale(storeInfo.storeAddress, tokenIds[0], _price, _paymentToken, _startTime);
            for (uint256 i = 1; i < _amount; i++) {
                _listOnSale(storeInfo.storeAddress, tokenIds[i], _typeId);
            }
            emit MintedAndListed(_storeId, _typeId, tokenIds, msg.sender);
        }
        stores[_storeId].currentTypeIdIndex += 1;
    }

    function _initialListTypeIdOnSale(
        address _storeAddress,
        uint256 _tokenId,
        uint256 _price,
        address _paymentToken,
        uint256 _startTime
    ) internal {
        Store(_storeAddress).approve(address(nftMarketPlace), _tokenId);
        nftMarketPlace.createTradeAndDelegate(
            _storeAddress,
            _tokenId,
            _paymentToken,
            _price,
            _startTime,
            msg.sender
        );
    }

    function _listOnSale(
        address _storeAddress,
        uint256 _tokenId,
        uint256 _typeId
    ) internal {
        Store(_storeAddress).approve(address(nftMarketPlace), _tokenId);
        nftMarketPlace.addTradeItem(
            _storeAddress,
            _typeId,
            _tokenId
        );
    }

    /* ========== VIEW FUNCTIONS ========== */

    function getStoreInfo(uint256 _storeId) external view returns (StoreInfoReturn memory storeInfoReturn) {
        require(_storeId < totalStore, "StoreFactory: invalid storeId");
        StoreInfo memory storeInfo = stores[_storeId];
        storeInfoReturn.storeId = _storeId;
        storeInfoReturn.name = storeInfo.name;
        storeInfoReturn.image = storeInfo.image;
        storeInfoReturn.profile = storeInfo.profile;
        storeInfoReturn.description = storeInfo.description;
        storeInfoReturn.storeAddress = storeInfo.storeAddress;
        storeInfoReturn.totalSupply = Store(storeInfoReturn.storeAddress).totalSupply();
    }

    function getListStoreInfo(uint256 page, uint256 limit) external view returns (StoreInfoReturn[] memory) {
        require (page > 0 && limit > 0, "StoreFactory: invalid pagination params");
        uint256 tempLength = limit;
        uint256 cursor = (page - 1) * limit;
        uint256 storeLength = totalStore;
        if (cursor >= storeLength) {
            return new StoreInfoReturn[](0);
        }

        if (tempLength > storeLength - cursor) {
            tempLength = storeLength - cursor;
        }

        StoreInfoReturn[] memory storeInfoReturns = new StoreInfoReturn[](tempLength);
        for (uint256 i = 0; i < tempLength; i++) {
            StoreInfo memory storeInfo = stores[cursor + i];
            storeInfoReturns[i].storeId = cursor + i;
            storeInfoReturns[i].name = storeInfo.name;
            storeInfoReturns[i].image = storeInfo.image;
            storeInfoReturns[i].profile = storeInfo.profile;
            storeInfoReturns[i].description = storeInfo.description;
            storeInfoReturns[i].storeAddress = storeInfo.storeAddress;
            storeInfoReturns[i].totalSupply = Store(storeInfoReturns[i].storeAddress).totalSupply();
        }
        return storeInfoReturns;
    }

    function getTypeIdByIndex(uint256 _index) external pure returns (uint256) {
        return _index << bitOffset;
    }
}