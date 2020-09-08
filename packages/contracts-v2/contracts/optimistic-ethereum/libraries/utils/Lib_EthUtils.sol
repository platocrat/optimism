// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_RLPWriter } from "../rlp/Lib_RLPWriter.sol";
import { Lib_ContractProxyResolver } from "../proxy/Lib_ContractProxyResolver.sol";

contract Lib_EthUtils is Lib_ContractProxyResolver {
    Lib_RLPWriter private libRLPWriter;

    constructor(
        address _libContractProxyManager
    )
        Lib_ContractProxyResolver(_libContractProxyManager)
    {
        libRLPWriter = Lib_RLPWriter(resolve("Lib_RLPWriter"));
    }

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
        bytes[] memory encoded = new bytes[](2);
        encoded[0] = libRLPWriter.encodeAddress(_creator);
        encoded[1] = libRLPWriter.encodeUint(_nonce);

        bytes memory encodedList = libRLPWriter.encodeList(encoded);

        return getAddressFromHash(keccak256(encodedList));
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
        bytes32 hashedData = keccak256(abi.encodePacked(
            byte(0xff),
            _creator,
            _salt,
            keccak256(_bytecode)
        ));

        return getAddressFromHash(hashedData);
    }

    /**
     * Determines an address from a 32 byte hash. Since addresses are only
     * 20 bytes, we need to retrieve the last 20 bytes from the original
     * hash. Converting to uint256 and then uint160 gives us these bytes.
     * @param _hash Hash to convert to an address.
     * @return Hash converted to an address.
     */
    function getAddressFromHash(
        bytes32 _hash
    )
        private
        pure
        returns (address)
    {
        return address(bytes20(uint160(uint256(_hash))));
    }
}
