// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMDataTypes } from "../../../libraries/utils/Lib_OVMDataTypes.sol";

/* Interface Imports */
import { iOVM_CanonicalTransactionChain } from "../../iOVM/chain/iOVM_CanonicalTransactionChain.sol";
import { iOVM_BaseQueue } from "../../iOVM/queue/iOVM_BaseQueue.sol";

/* Contract Imports */
import { OVM_BaseChain } from "./OVM_BaseChain.sol";

contract OVM_CanonicalTransactionChain is iOVM_CanonicalTransactionChain, OVM_BaseChain {
    iOVM_BaseQueue public ovmL1ToL2TransactionQueue;
    iOVM_BaseQueue public ovmSafetyTransactionQueue;
    uint256 forceInclusionPeriodSeconds;
    uint256 lastOVMTimestamp;

    modifier onlySequencer() {
        require(
            msg.sender == resolve("Sequencer"),
            "Function can only be called by the sequencer."
        );
        _;
    }

    constructor(
        address _libContractProxyManager,
        uint256 _forceInclusionPeriodSeconds
    )
        OVM_BaseChain(_libContractProxyManager)
    {
        ovmL1ToL2TransactionQueue = iOVM_BaseQueue(resolve("OVM_L1ToL2TransactionQueue"));
        ovmSafetyTransactionQueue = iOVM_BaseQueue(resolve("OVM_SafetyTransactionQueue"));
        forceInclusionPeriodSeconds = _forceInclusionPeriodSeconds;
    }

    function appendQueueBatch()
        override
        public
    {
        require(
            _hasPendingQueue() == true,
            "No batches are currently queued to be appended."
        );

        iOVM_BaseQueue nextQueue = _getNextQueue();
        _appendQueueBatch(nextQueue.peek(), 1);
        nextQueue.dequeue();
    }

    function appendSequencerBatch(
        bytes[] memory _batch,
        uint256 _timestamp
    )
        override
        public
        onlySequencer
    {
        require(
            _timestamp >= lastOVMTimestamp,
            "Batch timestamp must be later than the last OVM timestamp."
        );

        if (_hasPendingQueue()) {
            iOVM_BaseQueue nextQueue = _getNextQueue();

            require(
                _timestamp <= nextQueue.peek().timestamp,
                "Older queue batches must be processed before a newer sequencer batch."
            );
        }

        Lib_OVMDataTypes.OVMQueueElement memory queueElement = Lib_OVMDataTypes.OVMQueueElement({
            timestamp: _timestamp,
            batchRoot: libMerkleUtils.getMerkleRoot(_batch),
            isL1ToL2Batch: false
        });
        _appendQueueBatch(queueElement, _batch.length);
    }

    function _hasPendingQueue()
        internal
        view
        returns (
            bool _pending
        )
    {
        return ovmL1ToL2TransactionQueue.size() > 0 || ovmSafetyTransactionQueue.size() > 0;
    }

    function _getNextQueue()
        internal
        view
        returns (
            iOVM_BaseQueue _queue
        )
    {
        if (ovmL1ToL2TransactionQueue.size() == 0) {
            _queue = ovmSafetyTransactionQueue;
        } else if (ovmSafetyTransactionQueue.size() == 0) {
            _queue = ovmL1ToL2TransactionQueue;
        } else {
            Lib_OVMDataTypes.OVMQueueElement memory nextL1ToL2QueueElement = ovmL1ToL2TransactionQueue.peek();
            Lib_OVMDataTypes.OVMQueueElement memory nextSafetyQueueElement = ovmSafetyTransactionQueue.peek();

            if (nextL1ToL2QueueElement.timestamp < nextSafetyQueueElement.timestamp) {
                _queue = ovmL1ToL2TransactionQueue;
            } else {
                _queue = ovmSafetyTransactionQueue;
            }
        }

        return _queue;
    }

    function _appendQueueBatch(
        Lib_OVMDataTypes.OVMQueueElement memory _queueElement,
        uint256 _batchSize
    )
        internal
    {
        require(
            _queueElement.timestamp + forceInclusionPeriodSeconds <= block.timestamp,
            "Cannot append queue batch because the current element has timed out."
        );

        Lib_OVMDataTypes.OVMChainBatchHeader memory batchHeader = Lib_OVMDataTypes.OVMChainBatchHeader({
            batchIndex: batches.length,
            batchRoot: _queueElement.batchRoot,
            batchSize: _batchSize,
            prevTotalElements: totalElements,
            extraData: abi.encodePacked(
                _queueElement.timestamp,
                _queueElement.isL1ToL2Batch
            )
        });

        _appendBatch(batchHeader);
        lastOVMTimestamp = _queueElement.timestamp;
    }
}