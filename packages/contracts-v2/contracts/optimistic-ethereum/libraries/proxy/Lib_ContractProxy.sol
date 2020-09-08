// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

/* Library Imports */
import { Lib_ContractProxyManager } from "./Lib_ContractProxyManager.sol";

contract Lib_ContractProxy {
    Lib_ContractProxyManager contractProxyManager;

    constructor(
        address _libContractProxyManager
    ) {
        contractProxyManager = Lib_ContractProxyManager(_libContractProxyManager);
    }

    fallback()
        external
    {
        address target = contractProxyManager.getTarget(address(this));
        bytes memory data = msg.data;

        require(
            target != address(0),
            "Proxy does not have a target."
        );

        assembly {
            let success := call(
                gas(),
                target,
                0,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            let size := returndatasize()
            let returndata := mload(0x40)
            mstore(0x40, add(returndata, add(size, 0x20)))
            returndatacopy(add(returndata, 0x20), 0, size)
            
            if iszero(success) {
                revert(add(returndata, 0x20), size)
            }

            return(add(returndata, 0x20), size)
        }
    }
}
