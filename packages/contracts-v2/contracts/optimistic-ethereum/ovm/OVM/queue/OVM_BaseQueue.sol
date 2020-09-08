// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMDataTypes } from "../../../libraries/utils/Lib_OVMDataTypes.sol";

/* Interface Imports */
import { iOVM_BaseQueue } from "../../iOVM/queue/iOVM_BaseQueue.sol";

contract OVM_BaseQueue is iOVM_BaseQueue {
    Lib_OVMDataTypes.OVMQueueElement[] internal queue;
    uint256 internal front;

    modifier notEmpty() {
        require(
            size() > 0,
            "Queue is empty."
        );
        _;
    }

    function size()
        override
        public
        view
        returns (
            uint256 _size
        )
    {
        return front >= queue.length ? 0 : queue.length - front;
    }

    function peek()
        override
        public
        view
        notEmpty
        returns (
            Lib_OVMDataTypes.OVMQueueElement memory _element
        )
    {
        return queue[front];
    }

    function enqueue(
        Lib_OVMDataTypes.OVMQueueElement memory _element
    )
        override
        public
    {
        require(
            canEnqueue(msg.sender) == true,
            "Sender is not allowed to enqueue."
        );

        queue.push(_element);
    }

    function dequeue()
        override
        public
        notEmpty
        returns (
            Lib_OVMDataTypes.OVMQueueElement memory _element
        )
    {
        require(
            canDequeue(msg.sender) == true,
            "Sender is not allowed to dequeue."
        );

        _element = queue[front];
        delete queue[front];
        front += 1;
        return _element;
    }

    function canEnqueue(
        address _sender
    )
        override
        virtual
        public
        view
        returns (
            bool _authenticated
        )
    {
        return true;
    }

    function canDequeue(
        address _sender
    )
        override
        virtual
        public
        view
        returns (
            bool _authenticated
        )
    {
        return true;
    }
}