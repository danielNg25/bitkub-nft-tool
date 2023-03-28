// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../interfaces/token/IKAP721Receiver.sol";
import "../../interfaces/token/IKAP1155Receiver.sol";

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