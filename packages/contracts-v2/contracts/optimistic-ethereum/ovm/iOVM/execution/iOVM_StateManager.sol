// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { Lib_OVMDataTypes } from "../../../libraries/utils/Lib_OVMDataTypes.sol";

interface iOVM_StateManager {
    function putAccount(address _address, Lib_OVMDataTypes.OVMAccount memory _account) external;
    function getAccount(address _address) external returns (Lib_OVMDataTypes.OVMAccount memory _account);
    function hasAccount(address _address) external returns (bool _exists);

    function putContractStorage(address _contract, bytes32 _key, bytes32 _value) external;
    function getContractStorage(address _contract, bytes32 _key) external returns (bytes32 _value);
    
    function getContractCode(address _contract) external returns (bytes memory _code);

    function commitAccount(address _address) external;
    function isUncommittedAccount(address _address) external returns (bool _uncommitted);
    function totalUncommittedAccounts() external returns (uint256 _total);

    function commitStorage(address _contract, bytes32 _key, bytes32 _value) external;
    function isUncommittedStorage(address _contract, bytes32 _key, bytes32 _value) external returns (bool _uncommitted);
    function totalUncommittedStorage() external returns (uint256 _total);
}