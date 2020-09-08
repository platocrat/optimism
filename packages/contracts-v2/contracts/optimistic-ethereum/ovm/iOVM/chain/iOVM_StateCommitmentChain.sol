// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/* Interface Imports */
import { iOVM_BaseChain } from "./iOVM_BaseChain.sol";

/* Library Imports */
import { Lib_OVMDataTypes } from "../../../libraries/utils/Lib_OVMDataTypes.sol";

interface iOVM_StateCommitmentChain is iOVM_BaseChain {
    function appendStateBatch(bytes32[] calldata _batch) external;
    function deleteStateBatch(Lib_OVMDataTypes.OVMChainBatchHeader memory _batchHeader) external;
}