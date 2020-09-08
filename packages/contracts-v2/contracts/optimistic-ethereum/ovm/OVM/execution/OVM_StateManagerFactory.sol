// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

/* Library Imports */
import { Lib_ContractFactory } from "../../../libraries/factory/Lib_ContractFactory.sol";

/* Contract Imports */
import { OVM_StateManager } from "./OVM_StateManager.sol";

contract OVM_StateManagerFactory is Lib_ContractFactory {
    function create(
        bytes memory _calldata
    )
        override
        public
        returns (
            address _created
        )
    {
        revert("OVM_StateManagerFactory does not take any constructor parameters");
    }

    function create()
        override
        public
        returns (
            address _created
        )
    {
        return address(
            new OVM_StateManager()
        );
    }
}
