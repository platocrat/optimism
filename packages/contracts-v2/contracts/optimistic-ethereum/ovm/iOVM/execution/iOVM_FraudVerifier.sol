// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMDataTypes } from "../../../libraries/utils/Lib_OVMDataTypes.sol";

interface iOVM_FraudVerifier {
    function initializeFraudVerification(
        bytes32 _preStateRoot,
        Lib_OVMDataTypes.OVMChainBatchHeader calldata _preStateRootBatchHeader,
        Lib_OVMDataTypes.OVMChainInclusionProof calldata _preStateRootProof,
        Lib_OVMDataTypes.OVMTransactionData calldata _transaction,
        Lib_OVMDataTypes.OVMChainBatchHeader calldata _transactionBatchHeader,
        Lib_OVMDataTypes.OVMChainInclusionProof calldata _transactionProof
    ) external;

    function finalizeFraudVerification(
        bytes32 _preStateRoot,
        Lib_OVMDataTypes.OVMChainBatchHeader calldata _preStateRootBatchHeader,
        Lib_OVMDataTypes.OVMChainInclusionProof calldata _preStateRootProof,
        bytes32 _postStateRoot,
        Lib_OVMDataTypes.OVMChainBatchHeader calldata _postStateRootBatchHeader,
        Lib_OVMDataTypes.OVMChainInclusionProof calldata _postStateRootProof
    ) external;
}