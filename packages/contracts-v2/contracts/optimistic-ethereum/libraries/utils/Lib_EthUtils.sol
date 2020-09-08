// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

contract Lib_EthUtils {
    function getCodeHash(
        address _address
    )
        public
        view
        returns (
            bytes32 _codeHash
        )
    {
        assembly {
            _codeHash := extcodehash(_address)
        }

        return _codeHash;
    }

    function getAddressForCREATE(
        address _creator,
        uint256 _nonce
    )
        public
        view
        returns (
            address _address
        )
    {

    }

    function getAddressForCREATE2(
        address _creator,
        bytes memory _bytecode,
        bytes32 _salt
    )
        public
        view
        returns (address _address)
    {

    }
}