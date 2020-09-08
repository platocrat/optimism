// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

/* Library Imports */
import { Lib_ContractFactory } from "../../../libraries/factory/Lib_ContractFactory.sol";

/* Contract Imports */
import { OVM_StateTransitioner } from "./OVM_StateTransitioner.sol";

contract OVM_StateTransitionerFactory is Lib_ContractFactory {
    function create(
        bytes memory _calldata
    )
        override
        public
        returns (
            address _created
        )
    {
        (
            address libContractProxyManager,
            uint256 stateTransitionIndex,
            bytes32 preStateRoot,
            bytes32 transactionHash
        ) = abi.decode(_calldata, (address, uint256, bytes32, bytes32));

        return address(
            new OVM_StateTransitioner(
                libContractProxyManager,
                stateTransitionIndex,
                preStateRoot,
                transactionHash
            )
        );
    }

    function create()
        override
        public
        returns (
            address _created
        )
    {
        revert("OVM_StateTransitionerFactory requires constructor parameters");
    }
}
