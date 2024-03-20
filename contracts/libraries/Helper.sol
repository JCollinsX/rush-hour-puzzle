// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// @dev Excessive use of memory variables causes deep stack errors.
// This library helps save memory usage.
library Helper {
    //           64 bit           64 bit           64 bit           64 bit
    //                                             prevMap        currentMap         --> map
    //           nextId           prevId           stepNum            map            --> snapMap

    //      1 bit         63bit           64 bit           64 bit           64 bit
    //      pos          snapMapId         map            stepNum           carId           --> params

    //           64 bit           64 bit           64 bit           64 bit
    //      pos(first 1 bit)                                         carId      -->   step

    //      1bit      1bit        3 bit        3 bit       58bit       64 bit           64 bit           64 bit
    //      pos     prevPos     carLength   linePosition   weight                    historyPosition    position      --> car

    uint256 internal constant _64BIT_1 = MAX_64 << 192;
    uint256 internal constant _64BIT_2 = MAX_64 << 128;
    uint256 internal constant _64BIT_3 = MAX_64 << 64;
    uint256 internal constant _64BIT_4 = MAX_64;

    uint256 internal constant _1BIT_1 = 1 << 255; // pos is true
    uint256 internal constant _1BIT_2 = 1 << 254; // prevPos
    uint256 internal constant _3BIT_1 = 7 << 251; // carLength
    uint256 internal constant _3BIT_2 = 7 << 248; // linePosition
    uint256 internal constant _63BIT_1 = (MAX_64 << 193) >> 1;
    uint256 internal constant _58BIT_1 = (_64BIT_1 << 8) >> 8;

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
        a = a << 1;
        return a >> 255;
    }

    function set_1Bit_2(uint256 a, uint256 b) internal pure returns (uint256) {
        b = b << 254;
        a = (~_1BIT_2) & a;
        return a | b;
    }

    // carLength
    function _3Bit_1(uint256 a) internal pure returns (uint256) {
        a = a << 2;
        return a >> 253;
    }

    function set_3Bit_1(uint256 a, uint256 b) internal pure returns (uint256) {
        b = b << 251;
        a = (~_3BIT_1) & a;
        return a | b;
    }

    // linePosition
    function _3Bit_2(uint256 a) internal pure returns (uint256) {
        a = a << 5;
        return a >> 253;
    }

    function set_3Bit_2(uint256 a, uint256 b) internal pure returns (uint256) {
        b = b << 248;
        a = (~_3BIT_2) & a;
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

    // snapMapId in params
    function _63Bit_1(uint256 a) internal pure returns (uint256) {
        return a & _63BIT_1;
    }

    function set_63Bit_1(uint256 a, uint256 b) internal pure returns (uint256) {
        b = b << 192;
        a = (~_63BIT_1) & a;
        return a | b;
    }

    // weight
    function _58Bit_1(uint256 a) internal pure returns (uint256) {
        return (a & _58BIT_1) >> 192;
    }

    function set_58Bit_1(uint256 a, uint256 b) internal pure returns (uint256) {
        b = b << 192;
        a = (~_58BIT_1) & a;
        return a | b;
    }
}
