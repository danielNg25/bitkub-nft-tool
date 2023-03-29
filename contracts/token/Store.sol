// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IStore.sol";
import "../abstracts/token/KAP721.sol";

contract Store is IStore, KAP721 {
    using EnumerableSetUint for EnumerableSetUint.UintSet;

    uint256 public constant bitOffset = 17;

    string public image;

    // Mapping from typeID to mintNum
    mapping(uint256 => uint256) public mintCounter;
    
    mapping(address => bool) public operators;
    ///////////////////////////////////////////////////////////////////////////////////////

    modifier onlyOperator {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory project_,
        string memory baseURI_,
        address transferRouter_,
        address adminRouter_,
        address operator
    ) KAP721(name_, symbol_, project_, adminRouter_, transferRouter_) {
        _setBaseURI(baseURI_);
        operators[msg.sender] = true;
        operators[operator] = true;
        _transferOwnership(operator);
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

    function addOperator(address operator) external onlyOwner {
        require(!operators[operator], "Operator set");
        operators[operator] = true;
    }

    function removeOperator(address operator) external onlyOwner {
        require(operators[operator], "Operator not set");
        operators[operator] = false;
    }

    function setTypeURI(uint256 _typeId, string calldata _typeURI) external override onlyOwner {
        _setTypeURI(_typeId, _typeURI);
    }

    function setBaseURI(string calldata _baseURI) external override onlyOwner {
        _setBaseURI(_baseURI);
    }

    function setImage(string calldata _image) external onlyOwner {
        image = _image;
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function mint(address _to, uint256 _tokenId) external override onlyOperator {
        _mintInternal(_to, _tokenId);
    }

    function mintBatch(address _to, uint256[] memory _tokenIds) external override onlyOperator {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _mintInternal(_to, _tokenIds[i]);
        }

        emit MintBatch(_to, _tokenIds);
    }

    function mintByTypeId(address _to, uint256 _typeId) external onlyOperator returns (uint256) {
        uint256 _tokenId = _typeId + mintCounter[_typeId];
        require(((_tokenId >> bitOffset) << bitOffset) == _typeId, "Invalid typeId");
        _mintInternalByTypeId(_to, _tokenId, _typeId);
        return _tokenId;
    }

    function mintBatchByTypeId(address _to, uint256 _typeId, uint256 _amount) external onlyOperator  returns (uint256[] memory) {
        uint256 _firstTokenId = _typeId + mintCounter[_typeId];
        uint256 _lastTokenId = _typeId + mintCounter[_typeId] + _amount - 1;
        require(((_firstTokenId >> bitOffset) << bitOffset) == _typeId && ((_lastTokenId >> bitOffset) << bitOffset) == _typeId, "Invalid typeId");
        uint256[] memory _tokenIds = new uint256[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            uint256 _tokenId = _typeId + mintCounter[_typeId] + i;
            _tokenIds[i] = _tokenId;
            _mintInternalByTypeId(_to, _tokenId, _typeId);
        }
        emit MintBatch(_to, _tokenIds);
        return _tokenIds;
    }

    function burn(address _from, uint256 _tokenId) external override onlyOperator {
        require(ownerOf(_tokenId) == _from, "Not owner of token");
        _burn(_tokenId);
    }

    ///////////////////////////////////////////////////////////////////////////////////////

    function _mintInternal(address _to, uint256 _tokenId) internal {
        uint256 typeId = (_tokenId >> bitOffset) << bitOffset;
        mintCounter[typeId] += 1;
        _mint(_to, _tokenId);
    }

    function _mintInternalByTypeId(address _to, uint256 _tokenId, uint256 _typeId) internal {
        mintCounter[_typeId] += 1;
        _mint(_to, _tokenId);
    }
}