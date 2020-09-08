// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMDataTypes } from "../../../libraries/utils/Lib_OVMDataTypes.sol";

interface iOVM_ExecutionManager {
    function run(Lib_OVMDataTypes.OVMTransactionData calldata _transaction) external;

    /**
     * Overrides for EVM transaction context opcodes.
     */
    function ovmCALLER() external returns (address _caller);
    function ovmADDRESS() external returns (address _address);
    function ovmORIGIN() external returns (address _origin);
    function ovmTIMESTAMP() external returns (uint256 _timestamp);
    function ovmGASLIMIT() external returns (uint256 _gasLimit);

    /**
     * Custom EVM transaction context opcodes.
     */
    function ovmTXGASLIMIT() external returns (uint256 _txGasLimit);
    function ovmQUEUEORIGIN() external returns (uint256 _queueOrigin);
    function ovmCHAINID() external returns (uint256 _chainId);
    function ovmSTATICCTX() external returns (bool _static);

    /**
     * Overrides for EVM contract creation opcodes.
     */
    function ovmCREATE(bytes memory _bytecode) external returns (address _contract);
    function ovmCREATE2(bytes memory _bytecode, bytes32 _salt) external returns (address _contract);

    /**
     * Overrides for EVM contract calling opcodes.
     */
    function ovmCALL(address _address, bytes memory _calldata) external returns (bool _success, bytes memory _returndata);
    function ovmSTATICCALL(address _address, bytes memory _calldata) external returns (bool _success, bytes memory _returndata);
    function ovmDELEGATECALL(address _address, bytes memory _calldata) external returns (bool _success, bytes memory _returndata);

    /**
     * Overrides for EVM contract storage opcodes.
     */
    function ovmSLOAD(bytes32 _key) external returns (bytes32 _value);
    function ovmSSTORE(bytes32 _key, bytes32 _value) external;

    /**
     * Overrides for EVM code access opcodes.
     */
    function ovmEXTCODECOPY(address _contract) external returns (bytes memory _code);
    function ovmEXTCODESIZE(address _contract) external returns (uint256 _size);

    /**
     * Custom EVM code access opcodes.
     */
    function ovmEXTCODEHASH(address _contract) external returns (bytes32 _hash);
}