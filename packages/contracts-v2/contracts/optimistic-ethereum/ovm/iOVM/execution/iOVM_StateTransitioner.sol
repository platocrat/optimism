// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { Lib_OVMDataTypes } from "../../../libraries/utils/Lib_OVMDataTypes.sol";

interface iOVM_StateTransitioner {
    function preStateRoot() external view returns (bytes32 _preStateRoot);
    function postStateRoot() external view returns (bytes32 _postStateRoot);

    function proveEOAState(
        address _address,
        Lib_OVMDataTypes.OVMAccount calldata _account,
        bytes calldata _stateTrieWitness
    ) external;

    function proveContractState(
        address _ovmContractAddress,
        Lib_OVMDataTypes.OVMAccount calldata _account,
        bytes calldata _stateTrieWitness
    ) external;

    function proveStorageSlot(
        address _ovmContractAddress,
        bytes32 _key,
        bytes32 _value,
        bytes calldata _stateTrieWitness,
        bytes calldata _storageTrieWitness
    ) external;

    function applyTransaction(
        Lib_OVMDataTypes.OVMTransactionData calldata _transaction
    ) external;

    function commitAccountState(
        address _address,
        Lib_OVMDataTypes.OVMAccount calldata _account,
        bytes calldata _stateTrieWitness
    ) external;

    function commitStorageSlot(
        address _ovmContractAddress,
        bytes32 _key,
        bytes32 _value,
        bytes calldata _stateTrieWitness,
        bytes calldata _storageTrieWitness
    ) external;

    function completeTransition() external;

    function isComplete() external view returns (bool _complete);
}