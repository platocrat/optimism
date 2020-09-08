// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/* Interface Imports */
import { iOVM_BaseChain } from "../../iOVM/chain/iOVM_BaseChain.sol";

/* Library Imports */
import { Lib_OVMDataTypes } from "../../../libraries/utils/Lib_OVMDataTypes.sol";
import { Lib_MerkleUtils } from "../../../libraries/utils/Lib_MerkleUtils.sol";
import { Lib_ContractProxyResolver } from "../../../libraries/proxy/Lib_ContractProxyResolver.sol";

contract OVM_BaseChain is iOVM_BaseChain, Lib_ContractProxyResolver {
    bytes32[] public batches;
    uint256 public totalBatches;
    uint256 public totalElements;
    Lib_MerkleUtils public libMerkleUtils;

    constructor(
        address _libContractProxyManager
    )
        Lib_ContractProxyResolver(_libContractProxyManager)
    {
        libMerkleUtils = Lib_MerkleUtils(resolve("Lib_MerkleUtils"));
    }

    function getTotalElements()
        override
        public
        view
        returns (
            uint256 _totalElements
        )
    {
        return totalElements;
    }

    function getTotalBatches()
        override
        public
        view
        returns (
            uint256 _totalBatches
        )
    {
        return totalBatches;
    }

    function verifyElement(
        bytes calldata _element,
        Lib_OVMDataTypes.OVMChainBatchHeader memory _batchHeader,
        Lib_OVMDataTypes.OVMChainInclusionProof memory _proof
    )
        override
        public
        view
        returns (
            bool _verified
        )
    {
        require(
            _hashBatchHeader(_batchHeader) == batches[_batchHeader.batchIndex],
            "Invalid batch header."
        );

        require(
            libMerkleUtils.verify(
                _batchHeader.batchRoot,
                _element,
                _proof.index,
                _proof.siblings
            ),
            "Invalid inclusion proof."
        );

        return true;
    }

    function _hashBatchHeader(
        Lib_OVMDataTypes.OVMChainBatchHeader memory _batchHeader
    )
        internal
        pure
        returns (
            bytes32 _hash
        )
    {
        return keccak256(abi.encodePacked(
            _batchHeader.batchRoot,
            _batchHeader.batchSize,
            _batchHeader.prevTotalElements,
            _batchHeader.extraData
        ));
    }

    function _appendBatch(
        Lib_OVMDataTypes.OVMChainBatchHeader memory _batchHeader
    )
        internal
    {
        bytes32 batchHeaderHash = _hashBatchHeader(_batchHeader);
        batches.push(batchHeaderHash);
        totalBatches += 1;
        totalElements += _batchHeader.batchSize;
    }

    function _appendBatch(
        bytes[] memory _elements,
        bytes memory _extraData
    )
        internal
    {
        Lib_OVMDataTypes.OVMChainBatchHeader memory batchHeader = Lib_OVMDataTypes.OVMChainBatchHeader({
            batchIndex: batches.length,
            batchRoot: libMerkleUtils.getMerkleRoot(_elements),
            batchSize: _elements.length,
            prevTotalElements: totalElements,
            extraData: _extraData
        });

        _appendBatch(batchHeader);
    }

    function _appendBatch(
        bytes[] memory _elements
    )
        internal
    {
        _appendBatch(
            _elements,
            bytes('')
        );
    }

    function _deleteBatch(
        Lib_OVMDataTypes.OVMChainBatchHeader memory _batchHeader
    )
        internal
    {
        require(
            _batchHeader.batchIndex < batches.length,
            "Invalid batch index."
        );

        require(
            _hashBatchHeader(_batchHeader) == batches[_batchHeader.batchIndex],
            "Invalid batch header."
        );

        totalBatches = _batchHeader.batchIndex;
        totalElements = _batchHeader.prevTotalElements;
    }
}