pragma solidity ^0.5.0;

library Bithacks {
    uint256 constant INVERT_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 constant LO_BIT_MASK = 0x0101010101010101010101010101010101010101010101010101010101010101;
    uint256 constant HI_BIT_MASK = 0x8080808080808080808080808080808080808080808080808080808080808080;
    
    function haszero(
        uint256 _word
    ) internal pure returns (uint256) {
        return (
            (_word - LO_BIT_MASK) &
            ((_word ^ INVERT_MASK) & HI_BIT_MASK)
        );
    }

    function haszero(
        bytes32 _word
    ) internal pure returns (bytes32) {
        return bytes32(haszero(
            uint256(_word)
        ));
    }
    
    function hasvalue(
        uint256 _word,
        uint8 _value
    ) internal pure returns (uint256) {
        return haszero(
            (_word ^ (LO_BIT_MASK * _value))
        );
    }

    function hasvalue(
        bytes32 _word,
        bytes1 _value
    ) internal pure returns (bytes32) {
        return bytes32(hasvalue(
            uint256(_word),
            uint8(_value)
        ));
    }

    function hasbetween(
        uint256 _word,
        uint8 _min,
        uint8 _max
    ) internal pure returns (uint256) {
        return (
            (LO_BIT_MASK * (127 + (_max + 1))) -
            (_word & (LO_BIT_MASK * 127)) &
            (_word ^ INVERT_MASK) &
            (_word & (LO_BIT_MASK * 127)) +
            (LO_BIT_MASK * (127 - (_min - 1))) &
            (LO_BIT_MASK * 128)
        );
    }

    function hasbetween(
        bytes32 _word,
        bytes1 _min,
        bytes1 _max
    ) internal pure returns (bytes32) {
        return bytes32(hasbetween(
            uint256(_word),
            uint8(_min),
            uint8(_max)
        ));
    }
}
