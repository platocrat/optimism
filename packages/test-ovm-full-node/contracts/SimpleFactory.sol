pragma solidity ^0.5.0;

import { SimpleStorage } from "./SimpleStorage.sol";

contract SimpleFactory {

    function doDeploy() public returns(address) {
        SimpleStorage toReturn;
        toReturn = new SimpleStorage();
        return address(toReturn);
    }
}
