// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./token/Store.sol";
import "./abstracts/Pausable.sol";
import "./abstracts/KYCHandler.sol";
import "./abstracts/project/Authorization.sol";

contract StoreFactory is 
    Authorization,
    KYCHandler,
    Pausable 
{
    uint256 totalStore;

    struct StoreInfo {
        string name;
        string image;
        address storeAddress;
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

    constructor(
        string memory project_,
        address _adminRouter,
        address _transferRouter,
        address _kyc,
        uint256 _acceptedKycLevel
    ) 
        Authorization(project_)
    {
        adminRouter = IAdminProjectRouter(_adminRouter);
        transferRouter = _transferRouter;
        kyc = IKYCBitkubChain(_kyc);
        acceptedKycLevel = _acceptedKycLevel;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createStore(
        string calldata _name,
        string calldata _symbol,
        string calldata _image,
        string calldata _baseURI
    ) external onlySuperAdminOrAdmin {
        totalStore++;
        uint256 storeIndex = totalStore;
        Store store = new Store(
            _name,
            _symbol,
            project,
            _baseURI,
            transferRouter,
            address(adminRouter),
            address(kyc),
            acceptedKycLevel
        );
        address storeAddress = address(store);
        stores[storeIndex] = StoreInfo(_name, _image, storeAddress);
        emit StoreCreated(storeIndex, _name, _image, storeAddress, msg.sender);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function getStoreInfo(uint256 _storeId) external view returns (StoreInfo memory) {
        return stores[_storeId];
    }

    function getListStoreInfo(uint256 page, uint256 limit) external view returns (StoreInfo[] memory) {
        require (page > 0 && limit > 0, "StoreFactory: invalid pagination params");
        uint256 tempLength = limit;
        uint256 cursor = (page - 1) * limit;
        uint256 storeLength = totalStore;
        if (cursor >= storeLength) {
            return new StoreInfo[](0);
        }

        if (tempLength > storeLength - cursor) {
            tempLength = storeLength - cursor;
        }

        StoreInfo[] memory storeInfos = new StoreInfo[](tempLength);
        for (uint256 i = 0; i < tempLength; i++) {
            storeInfos[i] = stores[cursor + i];
        }
        return storeInfos;
    }
}