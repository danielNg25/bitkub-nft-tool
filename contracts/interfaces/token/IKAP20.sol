// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
