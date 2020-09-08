// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_ContractProxyResolver } from "../../../libraries/proxy/Lib_ContractProxyResolver.sol";

/* Interface Imports */
import { iOVM_CanonicalTransactionChain } from "../../iOVM/chain/iOVM_CanonicalTransactionChain.sol";

/* Contract Imports */
import { OVM_BaseQueue } from "./OVM_BaseQueue.sol";

contract OVM_L1ToL2TransactionQueue is OVM_BaseQueue, Lib_ContractProxyResolver {
    iOVM_CanonicalTransactionChain public ovmCanonicalTransactionChain;

    constructor(
        address _libContractProxyManager
    )
        Lib_ContractProxyResolver(_libContractProxyManager)
    {
        ovmCanonicalTransactionChain = iOVM_CanonicalTransactionChain(resolve("OVM_CanonicalTransactionChain"));
    }

    function canDequeue(
        address _sender
    )
        override
        public
        view
        returns (
            bool _authenticated
        )
    {
        return _sender == address(ovmCanonicalTransactionChain);
    }
}