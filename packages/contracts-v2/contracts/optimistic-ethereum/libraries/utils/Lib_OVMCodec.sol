// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMDataTypes } from "./Lib_OVMDataTypes.sol";

contract Lib_OVMCodec {
    function encode(
        Lib_OVMDataTypes.OVMTransactionData memory _transaction
    )
        public
        pure
        returns (
            bytes memory _encoded
        )
    {
        return abi.encodePacked(
            _transaction.timestamp,
            _transaction.queueOrigin,
            _transaction.entrypoint,
            _transaction.origin,
            _transaction.msgSender,
            _transaction.gasLimit,
            _transaction.data
        );
    }

    function hash(
        Lib_OVMDataTypes.OVMTransactionData memory _transaction
    )
        public
        pure
        returns (
            bytes32 _hash
        )
    {
        bytes memory encoded = encode(_transaction);
        return keccak256(encoded);
    }
}