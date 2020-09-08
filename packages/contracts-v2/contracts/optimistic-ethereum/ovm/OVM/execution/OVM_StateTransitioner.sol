// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMDataTypes } from "../../../libraries/utils/Lib_OVMDataTypes.sol";
import { Lib_OVMCodec } from "../../../libraries/utils/Lib_OVMCodec.sol";
import { Lib_EthUtils } from "../../../libraries/utils/Lib_EthUtils.sol";
import { Lib_EthMerkleTrie } from "../../../libraries/trie/Lib_EthMerkleTrie.sol";
import { Lib_ContractProxyResolver } from "../../../libraries/proxy/Lib_ContractProxyResolver.sol";
import { Lib_ContractFactory } from "../../../libraries/factory/Lib_ContractFactory.sol";

/* Interface Imports */
import { iOVM_ExecutionManager } from "../../iOVM/execution/iOVM_ExecutionManager.sol";
import { iOVM_StateManager } from "../../iOVM/execution/iOVM_StateManager.sol";
import { iOVM_StateTransitioner } from "../../iOVM/execution/iOVM_StateTransitioner.sol";

contract OVM_StateTransitioner is iOVM_StateTransitioner, Lib_ContractProxyResolver {
    enum TransitionPhase {
        PRE_EXECUTION,
        POST_EXECUTION,
        COMPLETE
    }

    bytes32 override public preStateRoot;
    bytes32 override public postStateRoot;
    TransitionPhase public phase;
    uint256 public stateTransitionIndex;
    bytes32 public transactionHash;
    Lib_EthMerkleTrie public libEthMerkleTrie;
    Lib_EthUtils public libEthUtils;
    Lib_OVMCodec public libOVMCodec;
    iOVM_ExecutionManager public ovmExecutionManager;
    iOVM_StateManager public ovmStateManager;

    modifier onlyDuringPhase(
        TransitionPhase _phase
    ) {
        require(
            phase == _phase,
            "Function must be called during the correct phase."
        );
        _;
    }


    constructor(
        address _libContractProxyManager,
        uint256 _stateTransitionIndex,
        bytes32 _preStateRoot,
        bytes32 _transactionHash
    ) Lib_ContractProxyResolver(_libContractProxyManager) {
        stateTransitionIndex = _stateTransitionIndex;
        preStateRoot = _preStateRoot;
        postStateRoot = _preStateRoot;
        transactionHash = _transactionHash;

        libEthMerkleTrie = Lib_EthMerkleTrie(resolve("Lib_EthMerkleTrie"));
        libEthUtils = Lib_EthUtils(resolve("Lib_EthUtils"));
        libOVMCodec = Lib_OVMCodec(resolve("Lib_OVMCodec"));
        ovmExecutionManager = iOVM_ExecutionManager(resolve("OVM_ExecutionManager"));
        ovmStateManager = iOVM_StateManager(
            Lib_ContractFactory(resolve("OVM_StateManagerFactory")).create()
        );
    }

    function proveEOAState(
        address _address,
        Lib_OVMDataTypes.OVMAccount calldata _account,
        bytes calldata _stateTrieWitness
    )
        override
        public
        onlyDuringPhase(TransitionPhase.PRE_EXECUTION)
    {
        require(
            _address == _account.ethAddress,
            "Invalid account address provided."
        );

        _proveAccountState(
            _address,
            _account,
            _stateTrieWitness
        );
    }

    function proveContractState(
        address _ovmContractAddress,
        Lib_OVMDataTypes.OVMAccount calldata _account,
        bytes calldata _stateTrieWitness
    )
        override
        public
        onlyDuringPhase(TransitionPhase.PRE_EXECUTION)
    {
        require(
            _account.codeHash == libEthUtils.getCodeHash(_account.ethAddress),
            "Invalid code hash provided."
        );

        _proveAccountState(
            _ovmContractAddress,
            _account,
            _stateTrieWitness
        );
    }

    function proveStorageSlot(
        address _ovmContractAddress,
        bytes32 _key,
        bytes32 _value,
        bytes calldata _stateTrieWitness,
        bytes calldata _storageTrieWitness
    )
        override
        public
        onlyDuringPhase(TransitionPhase.PRE_EXECUTION)
    {
        require(
            ovmStateManager.hasAccount(_ovmContractAddress) == true,
            "Contract must be verified before proving a storage slot."
        );

        require(
            libEthMerkleTrie.proveAccountStorageSlotValue(
                _ovmContractAddress,
                _key,
                _value,
                _stateTrieWitness,
                _storageTrieWitness,
                preStateRoot
            ),
            "Invalid account state provided."
        );

        ovmStateManager.putContractStorage(
            _ovmContractAddress,
            _key,
            _value
        );
    }

    function applyTransaction(
        Lib_OVMDataTypes.OVMTransactionData calldata _transaction
    )
        override
        public
    {
        require(
            libOVMCodec.hash(_transaction) == transactionHash,
            "Invalid transaction provided."
        );

        // TODO: Set state manager for EM here.

        ovmExecutionManager.run(_transaction);

        phase = TransitionPhase.POST_EXECUTION;
    }


    function commitAccountState(
        address _address,
        Lib_OVMDataTypes.OVMAccount calldata _account,
        bytes calldata _stateTrieWitness
    )
        override
        public
        onlyDuringPhase(TransitionPhase.POST_EXECUTION)
    {
        require(
            ovmStateManager.isUncommittedAccount(_address) == true,
            "Provided account is not uncommitted."
        );

        postStateRoot = libEthMerkleTrie.updateAccountState(
            _address,
            _account,
            _stateTrieWitness,
            postStateRoot
        );

        ovmStateManager.commitAccount(_address);
    }


    function commitStorageSlot(
        address _ovmContractAddress,
        bytes32 _key,
        bytes32 _value,
        bytes calldata _stateTrieWitness,
        bytes calldata _storageTrieWitness
    )
        override
        public
        onlyDuringPhase(TransitionPhase.POST_EXECUTION)
    {
        require(
            ovmStateManager.isUncommittedStorage(_ovmContractAddress, _key, _value) == true,
            "Provided storage slot is not uncommitted."
        );

        postStateRoot = libEthMerkleTrie.updateAccountStorageSlotValue(
            _ovmContractAddress,
            _key,
            _value,
            _stateTrieWitness,
            _storageTrieWitness,
            postStateRoot
        );

        ovmStateManager.commitStorage(_ovmContractAddress, _key, _value);
    }


    function completeTransition()
        override
        public
        onlyDuringPhase(TransitionPhase.POST_EXECUTION)
    {
        require(
            ovmStateManager.totalUncommittedAccounts() == 0,
            "All accounts must be committed before completing a transition."
        );

        require(
            ovmStateManager.totalUncommittedStorage() == 0,
            "All storage must be committed before completing a transition."
        );

        phase = TransitionPhase.COMPLETE;
    }


    function isComplete()
        override
        public
        view
        returns (
            bool _complete
        )
    {
        return phase == TransitionPhase.COMPLETE;
    }

    function _proveAccountState(
        address _address,
        Lib_OVMDataTypes.OVMAccount calldata _account,
        bytes calldata _stateTrieWitness
    )
        internal
    {
        require(
            libEthMerkleTrie.proveAccountState(
                _address,
                _account,
                _stateTrieWitness,
                preStateRoot
            ),
            "Invalid account state provided."
        );

        ovmStateManager.putAccount(
            _address,
            _account
        );
    }
}