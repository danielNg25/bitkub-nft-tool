// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IStore.sol";
import "../abstracts/token/KAP721.sol";

contract Store is IStore, KAP721 {
    using EnumerableSetUint for EnumerableSetUint.UintSet;

    uint256 public constant bitOffset = 17;

    string public image;

    // Mapping from typeID to mintNum
    mapping(uint256 => mintNum) public override mintInfo;

    ///////////////////////////////////////////////////////////////////////////////////////

    constructor(
        string memory name_,
        string memory symbol_,
        string memory project_,
        string memory baseURI_,
        address transferRouter_,
        address adminRouter_,
        address kyc_,
        uint256 acceptedKycLevel_
    ) KAP721(name_, symbol_, project_, adminRouter_, transferRouter_, kyc_, acceptedKycLevel_) {
        _setBaseURI(baseURI_);
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function exists(uint256 _tokenId) external view override returns (bool) {
        return _exists(_tokenId);
    }

    function tokenOfOwnerByPage(
        address _owner,
        uint256 _page,
        uint256 _limit
    ) external view override returns (uint256[] memory) {
        return _holderTokens[_owner].get(_page, _limit);
    }

    function tokenOfOwnerAll(address _owner) external view override returns (uint256[] memory) {
        return _holderTokens[_owner].getAll();
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function setTypeURI(uint256 _typeId, string calldata _typeURI) external override onlySuperAdmin {
        _setTypeURI(_typeId, _typeURI);
    }

    function setBaseURI(string calldata _baseURI) external override onlySuperAdmin {
        _setBaseURI(_baseURI);
    }

    function setImage(string calldata _image) external onlySuperAdmin {
        image = _image;
    }

    function setMintMax(uint256[] memory _typeIds, uint256[] memory _mintMaxs) external override onlySuperAdmin {
        require(_typeIds.length == _mintMaxs.length, "typeIds & mintMaxs must have same length");
        for (uint256 i = 0; i < _typeIds.length; i++) {
            mintInfo[_typeIds[i]].mintMax = _mintMaxs[i];
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function mint(address _to, uint256 _tokenId) external override onlySuperAdmin {
        _mintInternal(_to, _tokenId);
    }

    function mintBatch(address _to, uint256[] memory _tokenIds) external override onlySuperAdmin {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _mintInternal(_to, _tokenIds[i]);
        }

        emit MintBatch(_to, _tokenIds);
    }

    function burn(address _from, uint256 _tokenId) external override onlySuperAdmin {
        require(ownerOf(_tokenId) == _from, "Not owner of token");
        _burn(_tokenId);
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function _mintInternal(address _to, uint256 _tokenId) internal {
        uint256 typeId = (_tokenId >> bitOffset) << bitOffset;
        require(mintInfo[typeId].mintCounter < mintInfo[typeId].mintMax, "Exceed mint max");
        mintInfo[typeId].mintCounter += 1;
        _mint(_to, _tokenId);
    }
}