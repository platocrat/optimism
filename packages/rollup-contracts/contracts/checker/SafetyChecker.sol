pragma solidity ^0.5.0;

contract SafetyChecker {
    bytes1 constant COPY_MASK_SECOND_NIBBLE = 0x0F;
    bytes32 constant COPY_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    bytes32 constant COPY_MASK_EVERY_FIRST_NIBBLE = 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0;

    bytes32 constant PUSH_MASK_60 = 0x6060606060606060606060606060606060606060606060606060606060606060;
    bytes32 constant PUSH_MASK_70 = 0x7070707070707070707070707070707070707070707070707070707070707070;
    bytes32 constant JUMP_MASK = 0x5656565656565656565656565656565656565656565656565656565656565656;
    bytes32 constant JUMPDEST_MASK = 0x5B5B5B5B5B5B5B5B5B5B5B5B5B5B5B5B5B5B5B5B5B5B5B5B5B5B5B5B5B5B5B5B;
    bytes32 constant STOP_MASK = 0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 constant REVERT_MASK = 0xFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFDFD;
    bytes32 constant INVALID_MASK = 0xFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFEFE;
    bytes32 constant RETURN_MASK = 0xF3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3F3;

    uint256 opcodeWhitelistBitmap;
    address public executionManagerAddress;

    constructor(
        uint256 _opcodeWhitelistBitmap,
        address _executionManagerAddress
    ) public {
        opcodeWhitelistBitmap = _opcodeWhitelistBitmap;
        executionManagerAddress = _executionManagerAddress;
    }

    function isBytecodeSafe(
        bytes memory _bytecode
    ) public view returns (bool) {
        bytes memory sanitizedBytecode = removeExtraBytecode(_bytecode);
        uint256 whitelistBitmap = opcodeWhitelistBitmap;

        for (uint256 i = 0; i < sanitizedBytecode.length; i++) {
            if (getBit(whitelistBitmap, uint8(sanitizedBytecode[i])) == 0) {
                return false;
            }
        }

        return true;
    }

    function removeExtraBytecode(
        bytes memory _bytecode
    ) internal pure returns (bytes memory) {
        uint256 currentWordIndex = 0;
        uint256 currentByteIndex = 0;
        bytes32 currentWord;
        bytes32 nextWord;

        uint256 totalWords = _bytecode.length > 0 ? _bytecode.length / 32 + 1 : 0;

        while (currentWordIndex < totalWords) {
            currentByteIndex = currentWordIndex * 32;
            assembly {
                currentWord := mload(add(_bytecode, currentByteIndex))
            }
            
            if (currentWordIndex < totalWords - 1) {
                assembly {
                    nextWord := mload(add(_bytecode, add(currentByteIndex, 32)))
                }
            }

            bytes32 currentWordPushOpcodes = findPushOpcodes(currentWord);
            if (currentWordPushOpcodes != 0) {
                for (uint8 i = 0; i < 32; i++) {
                    bytes1 opcode = currentWord[i];

                    if (opcode != 0) {
                        uint8 pushSize = uint8(opcode) - 0x5f;
                        uint8 pushSizeCurrentWord = 32 - i - pushSize;
                        uint8 pushSizeNextWord = pushSize - pushSizeCurrentWord;

                        currentWord = currentWord & (COPY_MASK << 8 * pushSizeCurrentWord);
                        
                        if (currentWordIndex < totalWords - 1) {
                            nextWord = nextWord & (COPY_MASK >> 8 * pushSizeNextWord);
                        }
                    }
                }
            }

            assembly {
                mstore(add(_bytecode, currentByteIndex), currentWord)
            }
            
            if (currentWordIndex < totalWords - 1) {
                assembly {
                    mstore(add(_bytecode, add(currentByteIndex, 32)), nextWord)
                }
            }

            bytes32 currentWordTerminatingOpcodes = findTerminatingOpcodes(currentWord);
            if (currentWordTerminatingOpcodes != 0) {
                for (uint8 i = 0; i < 32; i++) {
                    if (currentWord[i] != 0) {
                        uint8 searchStartIndex = i;
                        uint8 searchEndIndex = 32;
                        bool isUnreachableCode = true;

                        while (isUnreachableCode) {
                            bytes32 currentWordJumpdestOpcodes = findJumpdestOpcodes(currentWord);
                            if (currentWordJumpdestOpcodes != 0) {
                                for (uint8 j = searchStartIndex; j < 32; i++) {
                                    if (currentWord[j] != 0) {
                                        searchEndIndex = j;
                                        isUnreachableCode = false;
                                        break;
                                    }
                                }
                            }

                            currentWord = currentWord & ((COPY_MASK << 8 * searchStartIndex) | (COPY_MASK >> 8 * searchEndIndex));
                            assembly {
                                mstore(add(_bytecode, currentByteIndex), currentWord)
                            }

                            if (!isUnreachableCode) {
                                break;
                            }

                            currentWordIndex += 1;
                            currentByteIndex = currentWordIndex * 32;
                            assembly {
                                currentWord := mload(add(_bytecode, currentByteIndex))
                            }

                            searchStartIndex = 0;
                        }
                    }
                }
            }

            currentWordIndex += 1;
        }
    }

    function findMatchingOpcodes(
        bytes32 _word,
        bytes32 _mask
    ) internal pure returns (bytes32) {
        bytes32 temp1 = _word ^ _mask;
        bytes32 temp2 = temp1 >> 1 | temp1 >> 2 | temp1 >> 3 | temp1 >> 4 | temp1 << 1 | temp1 << 2 | temp1 << 3 | temp1 << 4;
        return (temp1 | temp2) ^ COPY_MASK;
    }

    function findJumpdestOpcodes(
        bytes32 _word
    ) internal pure returns (bytes32) {
        return findMatchingOpcodes(_word, JUMPDEST_MASK);
    }

    function findPushOpcodes(
        bytes32 _word
    ) internal pure returns (bytes32) {
        bytes32 nibbles = _word ^ COPY_MASK_EVERY_FIRST_NIBBLE;
        bytes32 pushMatch60 = findMatchingOpcodes(nibbles, PUSH_MASK_60);
        bytes32 pushMatch70 = findMatchingOpcodes(nibbles, PUSH_MASK_70);
        bytes32 pushMatch = (pushMatch60 | pushMatch70) & COPY_MASK_EVERY_FIRST_NIBBLE;
        return _word & (pushMatch | (pushMatch >> 8));
    }

    function findTerminatingOpcodes(
        bytes32 _word
    ) internal pure returns (bytes32) {
        bytes32 jumpMatch = findMatchingOpcodes(_word, JUMP_MASK);
        bytes32 stopMatch = findMatchingOpcodes(_word, STOP_MASK);
        bytes32 revertMatch = findMatchingOpcodes(_word, REVERT_MASK);
        bytes32 invalidMatch = findMatchingOpcodes(_word, INVALID_MASK);
        bytes32 returnMatch = findMatchingOpcodes(_word, RETURN_MASK);
        return (jumpMatch | stopMatch | revertMatch | invalidMatch | returnMatch);
    }

    function getBit(uint256 _uint, uint8 _index) internal pure returns (uint8) {
        return uint8(_uint >> _index & 1); 
    }
}