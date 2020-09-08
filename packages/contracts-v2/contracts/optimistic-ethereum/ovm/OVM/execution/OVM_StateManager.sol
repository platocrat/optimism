// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMDataTypes } from "../../../libraries/utils/Lib_OVMDataTypes.sol";

/* Interface Imports */
import { iOVM_StateManager } from "../../iOVM/execution/iOVM_StateManager.sol";

contract OVM_StateManager is iOVM_StateManager {
    mapping (address => Lib_OVMDataTypes.OVMAccount) public accounts;
    mapping (address => mapping (bytes32 => bytes32)) public database;

    function putAccount(
        address _address,
        Lib_OVMDataTypes.OVMAccount memory _account
    )
        override
        public
    {
        accounts[_address] = _account;
    }

    function getAccount(address _address)
        override
        public
        returns (
            Lib_OVMDataTypes.OVMAccount memory _account
        )
    {
        return accounts[_address];
    }

    function hasAccount(
        address _address
    )
        override
        public
        returns (
            bool _exists
        )
    {
        return getAccount(_address).codeHash != bytes32(0);
    }

    function putContractStorage(
        address _contract,
        bytes32 _key,
        bytes32 _value
    )
        override
        public
    {
        database[_contract][_key] = _value;
    }

    function getContractStorage(
        address _contract,
        bytes32 _key
    )
        override
        public
        returns (
            bytes32 _value
        )
    {
        return database[_contract][_key];
    }

    function getContractCode(
        address _contract
    )
        override
        public
        returns (
            bytes memory _code
        )
    {
        
    }

    function commitAccount(
        address _address
    )
        override
        public
    {

    }

    function isUncommittedAccount(
        address _address
    )
        override
        public
        returns (
            bool _uncommitted
        )
    {

    }

    function totalUncommittedAccounts()
        override
        public
        returns (
            uint256 _total
        )
    {

    }

    function commitStorage(
        address _contract,
        bytes32 _key,
        bytes32 _value
    )
        override
        public
    {
        
    }

    function isUncommittedStorage(
        address _contract,
        bytes32 _key,
        bytes32 _value
    )
        override
        public
        returns (
            bool _uncommitted
        )
    {

    }

    function totalUncommittedStorage()
        override
        public
        returns (
            uint256 _total
        )
    {

    }
}
