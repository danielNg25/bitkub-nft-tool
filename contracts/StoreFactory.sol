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
    uint256 totalStore;
    uint256 private constant bitOffset = 17;
    struct StoreInfo {
        string name;
        string image;
        address storeAddress;
        uint256 currentTypeIdIndex;
    }

    struct StoreInfoReturn {
        string name;
        string image;
        address storeAddress;
        uint256 totalSupply;
    }

    mapping(uint256 => StoreInfo) private stores;

    /* ========== EVENTS ========== */

    event StoreCreated(
        uint256 indexed storeId,
        string name,
        string image,
        address storeAddress,
        address indexed caller
    );

    event MintedAndListed(
        uint256 indexed storeId,
        uint256 indexed typeId,
        uint256[] tokenIds,
        uint256 amount,
        uint256 price,
        address paymentToken,
        uint256 startTime,
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
        string calldata _baseURI
    ) external onlyOwner {
        totalStore++;
        uint256 storeIndex = totalStore;
        Store store = new Store(
            _name,
            _symbol,
            project,
            _baseURI,
            transferRouter,
            address(adminRouter),
            owner()
        );
        address storeAddress = address(store);
        stores[storeIndex] = StoreInfo(_name, _image, storeAddress, 0);
        emit StoreCreated(storeIndex, _name, _image, storeAddress, msg.sender);
    }

    function mintAndListExistingTypeId(
        uint256 _storeId,
        uint256 _typeId,
        uint256 _amount,
        uint256 _price,
        address _paymentToken,
        uint256 _startTime
    ) external onlyOwner {
        require(_amount > 0, "StoreFactory: invalid amount");
        StoreInfo memory storeInfo = stores[_storeId];
        require(_typeId < storeInfo.currentTypeIdIndex, "StoreFactory: invalid typeId");
        if (_amount == 1) {
            uint256 tokenId = Store(storeInfo.storeAddress).mintByTypeId(address(this), _typeId);
            _listOnSale(storeInfo.storeAddress, tokenId, _price, _paymentToken, _startTime);
            uint256[] memory tokenIds = new uint256[](1);
            tokenIds[0] = tokenId;
            emit MintedAndListed(_storeId, _typeId, tokenIds, _amount, _price, _paymentToken, _startTime, msg.sender);
        } else {
            uint256[] memory tokenIds = Store(storeInfo.storeAddress).mintBatchByTypeId(address(this), _typeId, _amount);
            for (uint256 i = 0; i < _amount; i++) {
                _listOnSale(storeInfo.storeAddress, tokenIds[i], _price, _paymentToken, _startTime);
            }
            emit MintedAndListed(_storeId, _typeId, tokenIds, _amount, _price, _paymentToken, _startTime, msg.sender);
        }
    }

    function mintAndListNewTypeId(
        uint256 _storeId,
        uint256 _amount,
        uint256 _price,
        address _paymentToken,
        uint256 _startTime
    ) external onlyOwner {
        require(_amount > 0, "StoreFactory: invalid amount");
        StoreInfo memory storeInfo = stores[_storeId];
        uint256 _typeId = storeInfo.currentTypeIdIndex - 1;
        if (_amount == 1) {
            uint256 tokenId = Store(storeInfo.storeAddress).mintByTypeId(address(this), _typeId);
            _listOnSale(storeInfo.storeAddress, tokenId, _price, _paymentToken, _startTime);
            uint256[] memory tokenIds = new uint256[](1);
            tokenIds[0] = tokenId;
            emit MintedAndListed(_storeId, _typeId, tokenIds, _amount, _price, _paymentToken, _startTime, msg.sender);
        } else {
            uint256[] memory tokenIds = Store(storeInfo.storeAddress).mintBatchByTypeId(address(this), _typeId, _amount);
            for (uint256 i = 0; i < _amount; i++) {
                _listOnSale(storeInfo.storeAddress, tokenIds[i], _price, _paymentToken, _startTime);
            }
            emit MintedAndListed(_storeId, _typeId, tokenIds, _amount, _price, _paymentToken, _startTime, msg.sender);
        }
        stores[_storeId].currentTypeIdIndex += 1;
    }

    function _listOnSale(
        address _storeAddress,
        uint256 _tokenId,
        uint256 _price,
        address _paymentToken,
        uint256 _startTime
    ) internal {
        nftMarketPlace.createTrade(
            _storeAddress,
            _tokenId,
            0,
            _paymentToken,
            _price,
            1,
            _startTime
        );
    }

    /* ========== VIEW FUNCTIONS ========== */

    function getStoreInfo(uint256 _storeId) external view returns (StoreInfoReturn memory storeInfoReturn) {
        StoreInfo memory storeInfo = stores[_storeId];
        storeInfoReturn.name = storeInfo.name;
        storeInfoReturn.image = storeInfo.image;
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
            storeInfoReturns[i].name = storeInfo.name;
            storeInfoReturns[i].image = storeInfo.image;
            storeInfoReturns[i].storeAddress = storeInfo.storeAddress;
            storeInfoReturns[i].totalSupply = Store(storeInfoReturns[i].storeAddress).totalSupply();
        }
        return storeInfoReturns;
    }

    function getTypeIdByIndex(uint256 _index) external pure returns (uint256) {
        return _index << bitOffset;
    }
}