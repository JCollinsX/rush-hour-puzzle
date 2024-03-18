// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

library CarLib {
    struct Car {
        uint8 carId;
        uint8 size;
        uint8 x;
        uint8 y;
        bool isVertical;
        bool isMainCar;
    }
}
