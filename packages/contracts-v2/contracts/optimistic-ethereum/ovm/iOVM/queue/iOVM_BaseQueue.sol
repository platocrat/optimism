// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMDataTypes } from "../../../libraries/utils/Lib_OVMDataTypes.sol";

interface iOVM_BaseQueue {
    function size() external view returns (uint256 _size);
    function peek() external view returns (Lib_OVMDataTypes.OVMQueueElement memory _element);
    function enqueue(Lib_OVMDataTypes.OVMQueueElement memory _element) external;
    function dequeue() external returns (Lib_OVMDataTypes.OVMQueueElement memory _element);
    function canEnqueue(address _sender) external view returns (bool _authenticated);
    function canDequeue(address _sender) external view returns (bool _authenticated);
}