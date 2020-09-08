// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMDataTypes } from "../../../libraries/utils/Lib_OVMDataTypes.sol";

interface iOVM_BaseChain {
    function getTotalElements() external view returns (uint256 _totalElements);
    function getTotalBatches() external view returns (uint256 _totalBatches);
    function verifyElement(
        bytes calldata _element,
        Lib_OVMDataTypes.OVMChainBatchHeader calldata _batchHeader,
        Lib_OVMDataTypes.OVMChainInclusionProof calldata _proof
    ) external view returns (bool _verified);
}