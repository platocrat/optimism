// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_OVMDataTypes } from "../../../libraries/utils/Lib_OVMDataTypes.sol";
import { Lib_EthUtils } from "../../../libraries/utils/Lib_EthUtils.sol";
import { Lib_ContractProxyResolver } from "../../../libraries/proxy/Lib_ContractProxyResolver.sol";

/* Interface Imports */
import { iOVM_ExecutionManager } from "../../iOVM/execution/iOVM_ExecutionManager.sol";
import { iOVM_StateManager } from "../../iOVM/execution/iOVM_StateManager.sol";
import { iOVM_SafetyChecker } from "../../iOVM/execution/iOVM_SafetyChecker.sol";

contract OVM_ExecutionManager is iOVM_ExecutionManager, Lib_ContractProxyResolver {
    struct CallContext {
        address ovmCALLER;
        address ovmADDRESS;

        bool ovmSTATICCTX;
    }

    struct ExecutionContext {
        address ovmORIGIN;
        uint256 ovmTIMESTAMP;
        uint256 ovmGASLIMIT;

        uint256 ovmTXGASLIMIT;
        uint256 ovmQUEUEORIGIN;
        uint256 ovmCHAINID;

        CallContext callContext;
    }

    ExecutionContext internal context;
    Lib_EthUtils public libEthUtils;
    iOVM_StateManager public ovmStateManager;
    iOVM_SafetyChecker public ovmSafetyChecker;

    modifier notStatic() {
        require(
            context.callContext.ovmSTATICCTX == false,
            "Opcode modifies state and cannot be executed in a static context."
        );
        _;
    }

    constructor(
        address _libContractProxyManager
    )
        Lib_ContractProxyResolver(_libContractProxyManager)
    {
        libEthUtils = Lib_EthUtils(resolve("Lib_EthUtils"));
        ovmStateManager = iOVM_StateManager(resolve("OVM_StateManager"));
        ovmSafetyChecker = iOVM_SafetyChecker(resolve("OVM_SafetyChecker"));
    }

    function run(
        Lib_OVMDataTypes.OVMTransactionData memory _transaction
    )
        override
        public
    {
        
    }

    /**
     * Overrides for EVM transaction context opcodes.
     */
    function ovmCALLER()
        override
        public
        returns (
            address _caller
        )
    {
        return context.callContext.ovmCALLER;
    }

    function ovmADDRESS()
        override
        public
        returns (
            address _address
        )
    {
        return context.callContext.ovmADDRESS;
    }

    function ovmORIGIN()
        override
        public
        returns (
            address _origin
        )
    {
        return context.ovmORIGIN;
    }

    function ovmTIMESTAMP()
        override
        public
        returns (
            uint256 _timestamp
        )
    {
        return context.ovmTIMESTAMP;
    }

    function ovmGASLIMIT()
        override
        public
        returns (
            uint256 _gasLimit
        )
    {
        return context.ovmGASLIMIT;
    }

    /**
     * Custom EVM transaction context opcodes.
     */
    function ovmTXGASLIMIT()
        override
        public
        returns (
            uint256 _txGasLimit
        )
    {
        return context.ovmTXGASLIMIT;
    }

    function ovmQUEUEORIGIN()
        override
        public
        returns (
            uint256 _queueOrigin
        )
    {
        return context.ovmQUEUEORIGIN;
    }

    function ovmCHAINID()
        override
        public
        returns (
            uint256 _chainId
        )
    {
        return context.ovmCHAINID;
    }

    function ovmSTATICCTX()
        override
        public
        returns (
            bool _static
        )
    {
        return context.callContext.ovmSTATICCTX;
    }

    /**
     * Overrides for EVM contract creation opcodes.
     */
    function ovmCREATE(
        bytes memory _bytecode
    )
        override
        public
        notStatic
        returns (
            address _contract
        )
    {
        Lib_OVMDataTypes.OVMAccount memory creator = ovmStateManager.getAccount(context.callContext.ovmADDRESS);
        _contract = libEthUtils.getAddressForCREATE(context.callContext.ovmADDRESS, creator.nonce);
        _createContract(_contract, _bytecode);
        return _contract;
    }

    function ovmCREATE2(
        bytes memory _bytecode,
        bytes32 _salt
    )
        override
        public
        notStatic
        returns (
            address _contract
        )
    {
        _contract = libEthUtils.getAddressForCREATE2(context.callContext.ovmADDRESS, _bytecode, _salt);
        _createContract(_contract, _bytecode);
        return _contract;
    }

    /**
     * Overrides for EVM contract calling opcodes.
     */
    function ovmCALL(
        address _address,
        bytes memory _calldata
    )
        override
        public
        returns (
            bool _success,
            bytes memory _returndata
        )
    {
        CallContext memory prevCallContext = context.callContext;

        context.callContext = CallContext({
            ovmCALLER: _address,
            ovmADDRESS: _address,
            ovmSTATICCTX: context.callContext.ovmSTATICCTX
        });

        (
            _success,
            _returndata
        ) = _callContract(_address, _calldata);

        context.callContext = prevCallContext;

        return (
            _success,
            _returndata
        );
    }

    function ovmSTATICCALL(
        address _address,
        bytes memory _calldata
    )
        override
        public
        returns (
            bool _success,
            bytes memory _returndata
        )
    {
        bool wasStatic = context.callContext.ovmSTATICCTX;
        context.callContext.ovmSTATICCTX = true;

        (
            _success,
            _returndata
        ) = ovmCALL(_address, _calldata);

        context.callContext.ovmSTATICCTX = wasStatic;

        return (
            _success,
            _returndata
        );
    }

    function ovmDELEGATECALL(
        address _address,
        bytes memory _calldata
    )
        override
        public
        returns (
            bool _success,
            bytes memory _returndata
        )
    {
        return _callContract(_address, _calldata);
    }

    /**
     * Overrides for EVM contract storage opcodes.
     */
    function ovmSLOAD(
        bytes32 _key
    )
        override
        public
        returns (
            bytes32 _value
        )
    {
        return ovmStateManager.getContractStorage(context.callContext.ovmADDRESS, _key);
    }

    function ovmSSTORE(
        bytes32 _key,
        bytes32 _value
    )
        override
        public
        notStatic
    {
        ovmStateManager.putContractStorage(context.callContext.ovmADDRESS, _key, _value);
    }

    /**
     * Overrides for EVM code access opcodes.
     */
    function ovmEXTCODECOPY(
        address _contract
    )
        override
        public
        returns (
            bytes memory _code
        )
    {
        return ovmStateManager.getContractCode(_contract);
    }

    function ovmEXTCODESIZE(
        address _contract
    )
        override
        public
        returns (
            uint256 _size
        )
    {
        bytes memory code = ovmEXTCODECOPY(_contract);
        return code.length;
    }

    /**
     * Custom EVM code access opcodes.
     */
    function ovmEXTCODEHASH(
        address _contract
    )
        override
        public
        returns (
            bytes32 _hash
        )
    {
        bytes memory code = ovmEXTCODECOPY(_contract);
        return keccak256(code);
    }


    function _createContract(
        address _address,
        bytes memory _bytecode
    )
        internal
    {
        require(
            ovmSafetyChecker.isBytecodeSafe(_bytecode) == true,
            "Contract creation code is not safe."
        );

        address ethContractAddress;
        assembly {
            ethContractAddress := create(
                0,
                add(_bytecode, 0x20),
                mload(_bytecode)
            )
        }

        bytes memory deployedBytecode;
        assembly {
            let deployedBytecodeSize := extcodesize(ethContractAddress)
            deployedBytecode := mload(0x40)

            mstore(0x40, add(deployedBytecode, and(add(add(deployedBytecodeSize, 0x20), 0x1f), not(0x1f))))
            mstore(deployedBytecode, deployedBytecodeSize)

            extcodecopy(ethContractAddress, add(deployedBytecode, 0x20), 0, deployedBytecodeSize)
        }

        require(
            ovmSafetyChecker.isBytecodeSafe(deployedBytecode) == true,
            "Contract runtime code is not safe."
        );

        Lib_OVMDataTypes.OVMAccount memory account = Lib_OVMDataTypes.OVMAccount({
            nonce: 0,
            balance: 0,
            storageRoot: keccak256(hex'80'),
            codeHash: keccak256(deployedBytecode),
            ethAddress: ethContractAddress
        });

        ovmStateManager.putAccount(_address, account);
    }

    function _callContract(
        address _contract,
        bytes memory _calldata
    )
        internal
        returns (
            bool _success,
            bytes memory _returndata
        )
    {
        Lib_OVMDataTypes.OVMAccount memory target = ovmStateManager.getAccount(_contract);

        address ethContractAddress = target.ethAddress;
        uint256 calldataSize = _calldata.length;
        assembly {
            _success := call(
                gas(),
                ethContractAddress,
                0,
                add(_calldata, 0x20),
                calldataSize,
                0,
                0
            )

            _returndata := mload(0x40)
            returndatacopy(_returndata, 0, returndatasize())
            
            if iszero(_success) {
                revert(_returndata, returndatasize())
            }

            mstore(0x40, add(_returndata, returndatasize()))
        }

        return (
            _success,
            _returndata
        );
    }
}