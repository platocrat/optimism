// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

contract Lib_ContractProxyManager {
    mapping (bytes32 => address) proxyByName;
    mapping (bytes32 => address) targetByName;
    mapping (address => bytes32) nameByProxy;
    mapping (address => bytes32) nameByTarget;


    function setProxy(
        string memory _name,
        address _proxy
    )
        public
    {
        proxyByName[_getNameHash(_name)] = _proxy;
        nameByProxy[_proxy] = _getNameHash(_name);
    }

    function getProxy(
        string memory _name
    )
        public
        view
        returns (
            address _proxy
        )
    {
        return proxyByName[_getNameHash(_name)];
    }

    function getProxy(
        address _target
    )
        public
        view
        returns (
            address _proxy
        )
    {
        return proxyByName[nameByTarget[_target]];
    }

    function setTarget(
        string memory _name,
        address _target
    )
        public
    {
        targetByName[_getNameHash(_name)] = _target;
        nameByTarget[_target] = _getNameHash(_name);
    }

    function getTarget(
        string memory _name
    )
        public
        view
        returns (
            address _target
        )
    {
        return targetByName[_getNameHash(_name)];
    }

    function getTarget(
        address _proxy
    )
        public
        view
        returns (
            address _target
        )
    {
        return targetByName[nameByProxy[_proxy]];
    }


    function _getNameHash(
        string memory _name
    )
        internal
        pure
        returns (
            bytes32 _hash
        )
    {
        return keccak256(abi.encodePacked(_name));
    }
}