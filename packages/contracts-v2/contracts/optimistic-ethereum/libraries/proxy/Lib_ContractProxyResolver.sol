// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

/* Library Imports */
import { Lib_ContractProxyManager } from "./Lib_ContractProxyManager.sol";

contract Lib_ContractProxyResolver {
    Lib_ContractProxyManager internal libContractProxyManager;

    constructor(
        address _libContractProxyManager
    ) {
        libContractProxyManager = Lib_ContractProxyManager(_libContractProxyManager);
    }

    function resolve(
        string memory _name
    )
        public
        view
        returns (
            address _proxy
        )
    {
        return libContractProxyManager.getProxy(_name);
    }
}
