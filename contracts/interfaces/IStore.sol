// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStore {
    event MintBatch(address indexed operator, uint256[] _tokenIds);

    function mintCounter(uint256 id) external view returns (uint256);

    function exists(uint256 _tokenId) external view returns (bool);

    function tokenOfOwnerByPage(
        address _owner,
        uint256 _page,
        uint256 _limit
    ) external view returns (uint256[] memory);

    function tokenOfOwnerAll(address _owner) external view returns (uint256[] memory);

    function setTypeURI(uint256 _typeId, string calldata _typeURI) external;

    function setBaseURI(string calldata _baseURI) external;

    function mint(address to, uint256 tokenId) external;

    function mintBatch(address _to, uint256[] memory _tokenIds) external;

    function mintByTypeId(address _to, uint256 _typeId) external returns (uint256);

    function mintBatchByTypeId(address _to, uint256 _typeId, uint256 _amount) external returns (uint256[] memory);

    function burn(address from, uint256 tokenId) external;
}