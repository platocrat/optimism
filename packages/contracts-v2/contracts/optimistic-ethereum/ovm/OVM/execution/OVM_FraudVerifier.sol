// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMDataTypes } from "../../../libraries/utils/Lib_OVMDataTypes.sol";
import { Lib_OVMCodec } from "../../../libraries/utils/Lib_OVMCodec.sol";
import { Lib_ContractProxyResolver } from "../../../libraries/proxy/Lib_ContractProxyResolver.sol";
import { Lib_ContractFactory } from "../../../libraries/factory/Lib_ContractFactory.sol";

/* Interface Imports */
import { iOVM_FraudVerifier } from "../../iOVM/execution/iOVM_FraudVerifier.sol";
import { iOVM_StateTransitioner } from "../../iOVM/execution/iOVM_StateTransitioner.sol";
import { iOVM_StateCommitmentChain } from "../../iOVM/chain/iOVM_StateCommitmentChain.sol";
import { iOVM_CanonicalTransactionChain } from "../../iOVM/chain/iOVM_CanonicalTransactionChain.sol";

contract OVM_FraudVerifier is iOVM_FraudVerifier, Lib_ContractProxyResolver {
    mapping (bytes32 => iOVM_StateTransitioner) public transitioners;
    Lib_OVMCodec public libOVMCodec;
    iOVM_StateCommitmentChain public ovmStateCommitmentChain;
    iOVM_CanonicalTransactionChain public ovmCanonicalTransactionChain;

    constructor(
        address _libContractProxyManager
    )
        Lib_ContractProxyResolver(_libContractProxyManager)
    {
        libOVMCodec = Lib_OVMCodec(resolve("Lib_OVMCodec"));
        ovmStateCommitmentChain = iOVM_StateCommitmentChain(resolve("OVM_StateCommitmentChain"));
        ovmCanonicalTransactionChain = iOVM_CanonicalTransactionChain(resolve("OVM_CanonicalTransactionChain"));
    }

    function initializeFraudVerification(
        bytes32 _preStateRoot,
        Lib_OVMDataTypes.OVMChainBatchHeader memory _preStateRootBatchHeader,
        Lib_OVMDataTypes.OVMChainInclusionProof memory _preStateRootProof,
        Lib_OVMDataTypes.OVMTransactionData memory _transaction,
        Lib_OVMDataTypes.OVMChainBatchHeader memory _transactionBatchHeader,
        Lib_OVMDataTypes.OVMChainInclusionProof memory _transactionProof
    )
        override
        public
    {
        if (_hasStateTransitioner(_preStateRoot)) {
            return;
        }

        require(
            _verifyStateRoot(
                _preStateRoot,
                _preStateRootBatchHeader,
                _preStateRootProof
            ),
            "Invalid pre-state root inclusion proof."
        );

        require(
            _verifyTransaction(
                _transaction,
                _transactionBatchHeader,
                _transactionProof
            ),
            "Invalid transaction inclusion proof."
        );

        transitioners[_preStateRoot] = iOVM_StateTransitioner(
            Lib_ContractFactory(resolve("OVM_StateTransitionerFactory")).create(
                abi.encode(
                    address(libContractProxyManager),
                    _preStateRootProof.index,
                    _preStateRoot,
                    libOVMCodec.hash(_transaction)
                )
            )
        );
    }

    function finalizeFraudVerification(
        bytes32 _preStateRoot,
        Lib_OVMDataTypes.OVMChainBatchHeader memory _preStateRootBatchHeader,
        Lib_OVMDataTypes.OVMChainInclusionProof memory _preStateRootProof,
        bytes32 _postStateRoot,
        Lib_OVMDataTypes.OVMChainBatchHeader memory _postStateRootBatchHeader,
        Lib_OVMDataTypes.OVMChainInclusionProof memory _postStateRootProof
    )
        override
        public
    {
        iOVM_StateTransitioner transitioner = transitioners[_preStateRoot];

        require(
            transitioner.isComplete() == true,
            "State transition process must be completed prior to finalization."
        );

        require(
            _postStateRootProof.index == _preStateRootProof.index + 1,
            "Invalid post-state root index."
        );

        require(
            _verifyStateRoot(
                _preStateRoot,
                _preStateRootBatchHeader,
                _preStateRootProof
            ),
            "Invalid pre-state root inclusion proof"
        );

        require(
            _verifyStateRoot(
                _postStateRoot,
                _postStateRootBatchHeader,
                _postStateRootProof
            ),
            "Invalid post-state root inclusion proof"
        );

        require(
            _postStateRoot != transitioner.postStateRoot(),
            "State transition has not been proven fraudulent."
        );

        ovmStateCommitmentChain.deleteStateBatch(
            _postStateRootBatchHeader
        );
    }

    function _hasStateTransitioner(
        bytes32 _preStateRoot
    )
        internal
        view
        returns (
            bool _exists
        )
    {
        return address(transitioners[_preStateRoot]) != address(0);
    }

    function _verifyStateRoot(
        bytes32 _stateRoot,
        Lib_OVMDataTypes.OVMChainBatchHeader memory _stateRootBatchHeader,
        Lib_OVMDataTypes.OVMChainInclusionProof memory _stateRootProof
    )
        internal
        view
        returns (
            bool _verified
        )
    {
        return ovmStateCommitmentChain.verifyElement(
            abi.encodePacked(_stateRoot),
            _stateRootBatchHeader,
            _stateRootProof
        );
    }

    function _verifyTransaction(
        Lib_OVMDataTypes.OVMTransactionData memory _transaction,
        Lib_OVMDataTypes.OVMChainBatchHeader memory _transactionBatchHeader,
        Lib_OVMDataTypes.OVMChainInclusionProof memory _transactionProof
    )
        internal
        view
        returns (
            bool _verified
        )
    {
        return ovmCanonicalTransactionChain.verifyElement(
            libOVMCodec.encode(_transaction),
            _transactionBatchHeader,
            _transactionProof
        );
    }
}