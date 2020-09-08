// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

interface Lib_ContractFactory {
    function create() external returns (address _created);
    function create(bytes memory _calldata) external returns (address _created);
}
