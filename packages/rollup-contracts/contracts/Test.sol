pragma solidity ^0.5.0;

contract Test {
    bytes32 constant COPY_MASK_EVERY_FIRST_NIBBLE = 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0;
    bytes32 constant PUSH_MASK = 0x6060606060606060606060606060606060606060606060606060606060606060;
    bytes1 constant PUSH_BYTE = 0x60;
    bytes32 constant PUSH_BYTE_COPY = 0x6000000000000000000000000000000000000000000000000000000000000000;
    
    function test(bytes32 _bytecode) public pure returns (bytes32) {
        return test3(_bytecode);
    }
    
    function test3(bytes32 _bytecode) internal pure returns (bytes32) {
        bytes32 temp0 = _bytecode & COPY_MASK_EVERY_FIRST_NIBBLE;
        bytes32 temp1 = temp0 ^ PUSH_MASK;
        bytes32 temp2 = temp1 | temp1 >> 1 | temp1 >> 2 | temp1 >> 3 | temp1 >> 4 | temp1 << 1 | temp1 << 2 | temp1 << 3 | temp1 << 4;
        bytes32 temp3 = temp2 & COPY_MASK_EVERY_FIRST_NIBBLE;
        return temp3 ^ COPY_MASK_EVERY_FIRST_NIBBLE;
    }
    
    function test2(bytes32 _bytecode) public pure returns (bytes32) {
        bytes32 temp0;
        for (uint256 i = 0; i < 32; i++) {
            bytes1 b = _bytecode[i];
            if (b >= 0x60 && b <= 0x7f) {
                temp0 = temp0 | (PUSH_BYTE_COPY >> i * 8);
            }
        }
        return temp0;
    }
    
    function test4(bytes memory _bytecode) public pure returns (bool) {
        bytes32 word;
        uint256 wordIndex = 0;
        
        while (wordIndex < _bytecode.length / 32 + 1) {
            assembly {
                word := mload(add(_bytecode, add(mul(wordIndex, 32), 32)))
            }
            wordIndex += 1;

            for (uint256 i = 0; i < 32; i++) {
                if (word[i] == 0x21) {
                    continue;
                }
            }

        }

        return true;
    }

    function test5(bytes memory _bytecode) public pure returns (bool) {
        for (uint256 i = 0; i < _bytecode.length; i++) {
            if (_bytecode[i] == 0x21) {
                continue;
            }
        }
        
        return true;
    }

    function test6(bytes memory _bytecode) public pure returns (bool) {
        bytes32 word;
        uint256 wordIndex = 0;
        
        while (wordIndex < _bytecode.length / 32 + 1) {
            assembly {
                word := mload(add(_bytecode, add(mul(wordIndex, 32), 32)))
            }
            wordIndex += 1;

            if (
                word[0] == 0x21 ||
                word[1] == 0x21 ||
                word[2] == 0x21 ||
                word[3] == 0x21 ||
                word[4] == 0x21 ||
                word[5] == 0x21 ||
                word[6] == 0x21 ||
                word[7] == 0x21 ||
                word[8] == 0x21 ||
                word[9] == 0x21 ||
                word[10] == 0x21 ||
                word[11] == 0x21 ||
                word[12] == 0x21 ||
                word[13] == 0x21 ||
                word[14] == 0x21 ||
                word[15] == 0x21 ||
                word[16] == 0x21 ||
                word[17] == 0x21 ||
                word[18] == 0x21 ||
                word[19] == 0x21 ||
                word[20] == 0x21 ||
                word[21] == 0x21 ||
                word[22] == 0x21 ||
                word[23] == 0x21 ||
                word[24] == 0x21 ||
                word[25] == 0x21 ||
                word[26] == 0x21 ||
                word[27] == 0x21 ||
                word[28] == 0x21 ||
                word[29] == 0x21 ||
                word[30] == 0x21 ||
                word[31] == 0x21
            ) {
                continue;
            }

        }
        
        return true;
    }
}