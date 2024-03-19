// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "hardhat/console.sol";

library VehicleLib {
    enum Orientation {
        HORIZONTAL,
        VERTICAL
    }

    struct Vehicle {
        uint8 carId;
        uint8 startX;
        uint8 startY;
        uint8 endX;
        uint8 endY;
        bool mainVehicle;
    }

    function setStartLocation(
        Vehicle memory _vehicle,
        uint8 _x,
        uint8 _y
    ) internal pure {
        _vehicle.startX = _x;
        _vehicle.startY = _y;
    }

    function setEndLocation(
        Vehicle memory _vehicle,
        uint8 _x,
        uint8 _y
    ) internal pure {
        _vehicle.endX = _x;
        _vehicle.endY = _y;
    }

    function getOccupiedLocations(
        Vehicle memory _vehicle
    ) internal pure returns (uint8[] memory, uint8[] memory) {
        uint8 deltaX = _vehicle.endX - _vehicle.startX;
        uint8 deltaY = _vehicle.endY - _vehicle.startY;

        uint8[] memory occupiedX = new uint8[](
            deltaX > deltaY ? deltaX + 1 : deltaY + 1
        );
        uint8[] memory occupiedY = new uint8[](
            deltaX > deltaY ? deltaX + 1 : deltaY + 1
        );

        if (getOrientation(_vehicle) == Orientation.HORIZONTAL) {
            for (uint8 i = _vehicle.startY; i <= _vehicle.endY; i++) {
                occupiedX[i - _vehicle.startY] = _vehicle.startX;
                occupiedY[i - _vehicle.startY] = i;
            }
        }

        if (getOrientation(_vehicle) == Orientation.VERTICAL) {
            for (uint8 j = _vehicle.startX; j <= _vehicle.endX; j++) {
                occupiedX[j - _vehicle.startX] = j;
                occupiedY[j - _vehicle.startX] = _vehicle.startY;
            }
        }

        return (occupiedX, occupiedY);
    }

    function getOrientation(
        Vehicle memory _vehicle
    ) internal pure returns (Orientation) {
        if (_vehicle.startX == _vehicle.endX) {
            return Orientation.HORIZONTAL;
        }

        return Orientation.VERTICAL;
    }

    function moveForward(
        Vehicle memory _vehicle
    ) internal pure returns (Vehicle memory) {
        if (getOrientation(_vehicle) == Orientation.VERTICAL) {
            _vehicle.startX++;
            _vehicle.endX++;
        }

        if (getOrientation(_vehicle) == Orientation.HORIZONTAL) {
            _vehicle.startY++;
            _vehicle.endY++;
        }

        return _vehicle;
    }

    function moveBackward(
        Vehicle memory _vehicle
    ) internal pure returns (Vehicle memory) {
        if (getOrientation(_vehicle) == Orientation.VERTICAL) {
            _vehicle.startX--;
            _vehicle.endX--;
        }

        if (getOrientation(_vehicle) == Orientation.HORIZONTAL) {
            _vehicle.startY--;
            _vehicle.endY--;
        }

        return _vehicle;
    }
}
