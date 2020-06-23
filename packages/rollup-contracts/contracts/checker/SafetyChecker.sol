pragma solidity ^0.5.0;

import "./Bithacks.sol";

contract SafetyChecker {
    bytes1 constant COPY_MASK_SECOND_NIBBLE = 0x0F;
    bytes1 constant NOOP_BYTE = 0xA0;
    bytes32 constant NOOP_MASK = 0xA0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0;
    bytes32 constant COPY_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    bytes32 constant COPY_MASK_EVERY_FIRST_NIBBLE = 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0;

    bytes1 constant PUSH_MIN = 0x60;
    bytes1 constant PUSH_MAX = 0x7F;
    bytes1 constant JUMP = 0x56;
    bytes1 constant JUMPDEST = 0x5B;
    bytes1 constant STOP = 0x00;
    bytes1 constant REVERT = 0xFD;
    bytes1 constant INVALID = 0xFE;
    bytes1 constant RETURN = 0xF3;

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
        if (_bytecode.length == 0) {
            return true;
        }

        (bytes memory sanitizedBytecode, uint256 currentByteIndex) = removeExtraBytecode(_bytecode);
        uint256 len = min(currentByteIndex, sanitizedBytecode.length);
        uint256 whitelistBitmap = opcodeWhitelistBitmap;

        for (uint256 i = 0; i < len; i++) {
            if (getBit(whitelistBitmap, uint8(sanitizedBytecode[i])) == 0) {
                return false;
            }
        }

        return true;
    }

    function removeExtraBytecode(
        bytes memory _bytecode
    ) internal pure returns (bytes memory, uint256) {
        uint256 currentWordIndex = 0;
        uint256 currentByteIndex = 0;
        bytes32 currentWord;
        bytes32 nextWord;

        uint256 totalWords = _bytecode.length / 32;

        bool hasJump = false;

        while (currentWordIndex <= totalWords) {
            currentByteIndex = (currentWordIndex + 1) * 32;

            assembly {
                currentWord := mload(add(_bytecode, currentByteIndex))
            }

            if (currentWordIndex < totalWords) {
                assembly {
                    nextWord := mload(add(_bytecode, add(currentByteIndex, 32)))
                }
            }

            (currentWord, nextWord) = handlePushOpcodes(currentWord, nextWord);

            assembly {
                mstore(add(_bytecode, currentByteIndex), currentWord)
            }

            if (currentWordIndex < totalWords) {
                assembly {
                    mstore(add(_bytecode, add(currentByteIndex, 32)), nextWord)
                }
            }

            (_bytecode, currentWordIndex, currentByteIndex, hasJump) = handleTerminatingOpcodes(
                _bytecode,
                currentWord,
                currentWordIndex,
                currentByteIndex,
                totalWords,
                hasJump
            );

            currentWordIndex += 1;
        }

        return (_bytecode, currentByteIndex);
    }

    function handlePushOpcodes(
        bytes32 _currentWord,
        bytes32 _nextWord
    ) internal pure returns (bytes32, bytes32) {
        bytes32 currentWord = _currentWord;
        bytes32 nextWord = _nextWord;

        bytes32 currentWordPushOpcodes = findPushOpcodes(currentWord);

        if (currentWordPushOpcodes != 0) {
            for (uint8 i = 0; i < 32; i++) {
                bytes1 opcode = currentWord[i];

                if (currentWordPushOpcodes[i] != 0 && opcode != NOOP_BYTE) {
                    uint8 pushSize = uint8(opcode) - 0x5f;
                    uint8 pushSizeCurrentWord = uint8(min(pushSize, 32 - i - 1));
                    uint8 pushSizeNextWord = pushSize - pushSizeCurrentWord;

                    currentWord = makeBytesNoop(currentWord, i, i + pushSizeCurrentWord + 1);

                    if (pushSizeNextWord > 0) {
                        nextWord = makeBytesNoop(nextWord, 0, pushSizeNextWord);
                    }
                }
            }
        }

        return (currentWord, nextWord);
    }

    function handleTerminatingOpcodes(
        bytes memory _bytecode,
        bytes32 _currentWord,
        uint256 _currentWordIndex,
        uint256 _currentByteIndex,
        uint256 _totalWords,
        bool _hasJump
    ) internal pure returns (bytes memory, uint256, uint256, bool) {

        bytes32 currentWordJumpOpcodes = findJumpOpcodes(_currentWord);
        bytes32 currentWordTerminatingOpcodes = findTerminatingOpcodes(_currentWord) | currentWordJumpOpcodes;

        if (currentWordTerminatingOpcodes != 0) {
            for (uint8 i = 0; i < 32; i++) {
                if (currentWordTerminatingOpcodes[i] != 0 && _currentWord[i] != NOOP_BYTE) {
                    if (currentWordJumpOpcodes[i] != 0) {
                        _hasJump = true;
                    }

                    if (!_hasJump) {
                        return (_bytecode, _totalWords, _currentByteIndex + i - 32, false);
                    }

                    (_bytecode, _currentWord, _currentWordIndex) = seekJumpdest(
                        _bytecode,
                        _currentWord,
                        _currentWordIndex,
                        _currentByteIndex,
                        _totalWords,
                        i
                    );
                    _currentByteIndex = _currentWordIndex * 32;
                }
            }
        }

        return (_bytecode, _currentWordIndex, _currentByteIndex, _hasJump);
    }

    function seekJumpdest(
        bytes memory _bytecode,
        bytes32 _currentWord,
        uint256 _currentWordIndex,
        uint256 _currentByteIndex,
        uint256 _totalWords,
        uint8 _searchStartIndex
    ) internal pure returns (
        bytes memory,
        bytes32,
        uint256
    ) {
        uint8 searchStartIndex = _searchStartIndex;
        uint8 searchEndIndex = 32;
        bool isUnreachableCode = true;

        while (isUnreachableCode) {
            bytes32 currentWordJumpdestOpcodes = findJumpdestOpcodes(_currentWord);

            if (currentWordJumpdestOpcodes != 0) {
                for (uint8 j = searchStartIndex; j < 32; j++) {
                    if (currentWordJumpdestOpcodes[j] != 0 && _currentWord[j] != NOOP_BYTE) {
                        searchEndIndex = j;
                        isUnreachableCode = false;
                        break;
                    }
                }
            }

            _currentWord = makeBytesNoop(_currentWord, searchStartIndex, searchEndIndex);
            assembly {
                mstore(add(_bytecode, _currentByteIndex), _currentWord)
            }

            if (!isUnreachableCode) {
                break;
            }

            if (_currentWordIndex == _totalWords) {
                break;
            }

            _currentWordIndex += 1;
            _currentByteIndex = _currentWordIndex * 32;
            assembly {
                _currentWord := mload(add(_bytecode, _currentByteIndex))
            }

            searchStartIndex = 0;
        }

        return (
            _bytecode,
            _currentWord,
            _currentWordIndex
        );
    }

    function findJumpdestOpcodes(
        bytes32 _word
    ) internal pure returns (bytes32) {
        return Bithacks.hasvalue(_word, JUMPDEST);
    }

    function findJumpOpcodes(
        bytes32 _word
    ) internal pure returns (bytes32) {
        return Bithacks.hasvalue(_word, JUMP);
    }

    function findPushOpcodes(
        bytes32 _word
    ) internal pure returns (bytes32) {
        return Bithacks.hasbetween(_word, PUSH_MIN, PUSH_MAX);
    }

    function findTerminatingOpcodes(
        bytes32 _word
    ) internal pure returns (bytes32) {
        bytes32 stopMatch = Bithacks.hasvalue(_word, STOP);
        bytes32 revertMatch = Bithacks.hasvalue(_word, REVERT);
        bytes32 invalidMatch = Bithacks.hasvalue(_word, INVALID);
        bytes32 returnMatch = Bithacks.hasvalue(_word, RETURN);
        return (stopMatch | revertMatch | invalidMatch | returnMatch);
    }

    function makeBytesNoop(
        bytes32 _word,
        uint8 _start,
        uint8 _end
    ) internal pure returns (bytes32) {
        bytes32 copyMask = (COPY_MASK >> 8 * _start) & (COPY_MASK << 8 * (32 - _end));
        bytes32 deleteMask = (COPY_MASK ^ copyMask);
        bytes32 noopMask = (NOOP_MASK & copyMask);
        return (_word & deleteMask) | noopMask;
    }

    function getBit(uint256 _uint, uint8 _index) internal pure returns (uint8) {
        return uint8(_uint >> _index & 1);
    }

    function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }
}
