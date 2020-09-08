// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_MerkleTrie } from "./Lib_MerkleTrie.sol";

/**
* @title SecureMerkleTrie
 * Wrapper around MerkleTrie that hashes keys before they're passed to
 * underlying functions. Necessary for compatibility with Ethereum.
 */
contract Lib_SecureMerkleTrie is Lib_MerkleTrie {
    constructor(
        address _libContractProxyManager
    ) Lib_MerkleTrie(_libContractProxyManager) {}

    /*
     * Public Functions
     */

    function verifyInclusionProof(
        bytes memory _key,
        bytes memory _value,
        bytes memory _proof,
        bytes32 _root
    )
        public
        view
        returns (bool)
    {
        bytes memory key = _getSecureKey(_key);
        return _verifyInclusionProof(key, _value, _proof, _root);
    }

    function verifyExclusionProof(
        bytes memory _key,
        bytes memory _value,
        bytes memory _proof,
        bytes32 _root
    )
        public
        view
        returns (bool)
    {
        bytes memory key = _getSecureKey(_key);
        return _verifyExclusionProof(key, _value, _proof, _root);
    }

    function update(
        bytes memory _key,
        bytes memory _value,
        bytes memory _proof,
        bytes32 _root
    )
        public
        view
        returns (bytes32)
    {
        bytes memory key = _getSecureKey(_key);
        return _update(key, _value, _proof, _root);
    }

    function get(
        bytes memory _key,
        bytes memory _proof,
        bytes32 _root
    )
        public
        view
        returns (bool, bytes memory)
    {
        bytes memory key = _getSecureKey(_key);
        return _get(key, _proof, _root);
    }

    function getSingleNodeRootHash(
        bytes memory _key,
        bytes memory _value
    )
        public
        view
        returns (bytes32)
    {
        bytes memory key = _getSecureKey(_key);
        return _getSingleNodeRootHash(key, _value);
    }


    /*
     * Private Functions
     */

    function _getSecureKey(
        bytes memory _key
    ) private pure returns (bytes memory) {
        return abi.encodePacked(keccak256(_key));
    }
}