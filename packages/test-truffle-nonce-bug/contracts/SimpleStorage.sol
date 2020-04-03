pragma solidity ^0.5.16;

contract SimpleStorage {
    bytes32 value;

    function set(bytes32 _value) public {
        value = _value;
    }

    function get() public view returns (bytes32) {
        return value;
    }
}
