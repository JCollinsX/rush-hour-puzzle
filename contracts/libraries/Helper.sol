// SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.13;

// @dev Excessive use of memory variables causes deep stack errors.
// This library helps save memory usage.
library Helper {

    //           64 bit           64 bit           64 bit           64 bit
    //                                             prevMap        currentMap         --> map
    //      pos(first 1 bit)                       stepNum           carId           --> params
    //      pos(first 1 bit)     prevPos        historyPosition carId, position      --> car, step

    uint256 internal constant _64BIT_1 = MAX_64 << 192;
    uint256 internal constant _64BIT_2 = MAX_64 << 128;
    uint256 internal constant _64BIT_3 = MAX_64 << 64;
    uint256 internal constant _64BIT_4 = MAX_64;

    uint256 internal constant _1BIT_1 = 1 << 255; // pos is true
    uint256 internal constant _1BIT_2 = 1 << 191; // pos is true

    uint256 internal constant MAX_64 = type(uint64).max;

    // pos
    function _1Bit_1(uint256 a) internal pure returns (uint256) {
        return a >> 255;
    }

    function set_1Bit_1(uint256 a, uint256 b) internal pure returns (uint256) {
        b = b << 255;
        a = (~_1BIT_1) & a;
        return a | b;
    }

    // prevPos
    function _1Bit_2(uint256 a) internal pure returns (uint256) {
        a = a << 64;
        return a >> 255;
    }

    function set_1Bit_2(uint256 a, uint256 b) internal pure returns (uint256) {
        b = b << 191;
        a = (~_1BIT_2) & a;
        return a | b;
    }

    function _64Bit_1(uint256 a) internal pure returns (uint256) {
        return (a & _64BIT_1) >> 192;
    }

    function set_64Bit_1(uint256 a, uint256 b) internal pure returns (uint256) {
        b = b << 192;
        a = (~_64BIT_1) & a;
        return a | b;
    }

    // minStepLength, snapMap
    function _64Bit_2(uint256 a) internal pure returns (uint256) {
        return (a & _64BIT_2) >> 128;
    }

    function set_64Bit_2(uint256 a, uint256 b) internal pure returns (uint256) {
        b = b << 128;
        a = (~_64BIT_2) & a;
        return a | b;
    }

    // stepNum, prevMap
    function _64Bit_3(uint256 a) internal pure returns (uint256) {
        return (a & _64BIT_3) >> 64;
    }

    function set_64Bit_3(uint256 a, uint256 b) internal pure returns (uint256) {
        b = b << 64;
        a = (~_64BIT_3) & a;
        return a | b;
    }

    // stepLength, position, currentMap, carId
    function _64Bit_4(uint256 a) internal pure returns (uint256) {
        return a & _64BIT_4;
    }

    function set_64Bit_4(uint256 a, uint256 b) internal pure returns (uint256) {
        a = (~_64BIT_4) & a;
        return a | b;
    }
}
