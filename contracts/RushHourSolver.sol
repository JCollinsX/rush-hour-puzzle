// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./interface/IRushHourSolver.sol";
import "./libraries/Helper.sol";

contract RushHourSolver is IRushHourSolver {
    using Helper for uint256;
    // (01111110)b = 126

    // Full park map
    //
    // 0 0 0 0 0 0 0 0
    // 0 1 1 1 1 1 1 0
    // 0 1 1 1 1 1 1 0
    // 0 1 1 1 1 1 1 0
    // 0 1 1 1 1 1 1 0
    // 0 1 1 1 1 1 1 0
    // 0 1 1 1 1 1 1 0
    // 0 0 0 0 0 0 0 0
    //
    // 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 0 0 1 1 1 1 1 1 0 0 1 1 1 1 1 1 0 0 1 1 1 1 1 1 0 0 1 1 1 1 1 1 0 0 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0
    // (126 + 126 * 256 + 126 * 256 ^ 2 + 126 * 256 ^ 3 + 126 * 256 ^ 4 +126 * 256 ^ 5) * 256 = 35,604,928,818,740,736
    uint256 private constant FULL_PARK_MAP = 35604928818740736;

    // Fence of park
    // 1 1 1 1 1 1 1 1
    // 1 0 0 0 0 0 0 1
    // 1 0 0 0 0 0 0 1
    // 1 0 0 0 0 0 0 1
    // 1 0 0 0 0 0 0 1
    // 1 0 0 0 0 0 0 1
    // 1 0 0 0 0 0 0 1
    // 1 1 1 1 1 1 1 1
    //
    // 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 1 1 0 0 0 0 0 0 1 1 0 0 0 0 0 0 1 1 0 0 0 0 0 0 1 1 0 0 0 0 0 0 1 1 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1
    uint256 private constant FENCE_OF_PARK_MAP =
        type(uint64).max - FULL_PARK_MAP;
    // 2 ^ 64 - 1 = FULL_PARK_MAP + FENCE_OF_PARK_MAP

    // (0000000000000000000000000000011000000000000000000000000000000000)b = 2 ^ 33 + 2 ^ 34 = 25,769,803,776
    uint256 private constant COMPLETED_CAR0_POSITION = 25769803776;

    uint256 private minFinalStepNum;

    // In solidity, excessive recursive function calls cause stack overflow.
    // In this solution, set the highest stack deep to 36.
    uint256 private constant MAX_STACK_DEEP = 36;

    uint256 private constant START_MEMORY_ADDRESS = 10000;

    // @dev store step path for best solution.
    struct StepPath {
        uint256 stepLength;
        uint256[100] steps;
        uint256 finalMap;
    }

    function solve(
        uint8[6][6] memory board
    ) public view returns (Step[] memory) {
        StepPath memory stepPath;

        // @dev global variable. will transfer the pointer of cars to functions.
        // when cars is changes in the children functions, this cars will be changed.
        uint256[] memory cars;

        // 1  ~ 64  bit : current map value
        // 65 ~ 128 bit : prev map value
        uint256 map;

        (map, cars) = getMap(board);

        _initSnapMap(cars);

        _move(map, 0, cars, stepPath);

        Step[] memory finalSteps = new Step[](stepPath.stepLength);

        for (uint256 i; i < stepPath.stepLength; ++i) {
            if (cars[stepPath.steps[i]._64Bit_4()]._1Bit_1() == 0) {
                finalSteps[i] = Step(
                    uint8(stepPath.steps[i]._64Bit_4()) + 1,
                    stepPath.steps[i]._1Bit_1() == 0
                        ? MovementDirection.Right
                        : MovementDirection.Left
                );
            } else {
                finalSteps[i] = Step(
                    uint8(stepPath.steps[i]._64Bit_4()) + 1,
                    stepPath.steps[i]._1Bit_1() == 0
                        ? MovementDirection.Down
                        : MovementDirection.Up
                );
            }
        }

        return finalSteps;
    }

    function getMap(
        uint8[6][6] memory cells
    ) internal pure returns (uint256 map, uint256[] memory cars) {
        uint256 carId;
        uint256 point;

        uint256 numOfCars;
        for (uint256 i; i < 6; ++i) {
            for (uint256 j; j < 6; ++j) {
                if (cells[i][j] > numOfCars) {
                    numOfCars = cells[i][j];
                }
            }
        }
        cars = new uint256[](numOfCars);
        for (uint256 i; i < 6; ) {
            for (uint256 j; j < 6; ) {
                carId = cells[i][j];
                if (carId != 0) {
                    --carId;
                    point = _calcPoint(i, j);
                    if (cars[carId]._64Bit_4() > 0) {
                        if (
                            cars[carId]._64Bit_4() / point == 2 ||
                            cars[carId]._64Bit_4() / point == 6
                        ) {
                            cars[carId] = cars[carId].set_1Bit_1(0);
                            cars[carId] = cars[carId].set_3Bit_2(5 - j);
                        } else {
                            cars[carId] = cars[carId].set_1Bit_1(1);
                            cars[carId] = cars[carId].set_3Bit_2(5 - i);
                        }
                    }
                    cars[carId] += point;
                    cars[carId] = cars[carId].set_3Bit_1(
                        cars[carId]._3Bit_1() + 1
                    );
                    map += point;
                }
                ++j;
            }
            ++i;
        }

        // print current position
        for (uint256 i; i < cars.length; ++i) {
            cars[i] = cars[i].set_58Bit_1(5 ** i);
            _resetHistoryPosition(cars, i);
        }
        for (uint256 i; i < cars.length; ++i) {
            if (cars[i]._3Bit_1() == 3) {
                cars[i] = cars[i].set_58Bit_1(5 ** (cars.length - 1));
                cars[cars.length - 1] = cars[cars.length - 1].set_58Bit_1(
                    5 ** i
                );
                _createSnapMapMemorySpace(cars.length, true);
                return (map, cars);
            }
        }
        _createSnapMapMemorySpace(cars.length, false);
    }

    function _calcPoint(
        uint256 i,
        uint256 j
    ) internal pure returns (uint256 point) {
        // 8 * 8 - 8 * (i + 1) - (j + 2) = 54 - 8 * i - j
        point = 1 << (54 - 8 * i - j);
    }

    function _move(
        uint256 map,
        uint256 stepNum,
        uint256[] memory cars,
        StepPath memory stepPath
    ) internal view returns (bool hasSolution) {
        if (stepPath.stepLength <= stepNum && stepPath.stepLength > 0) {
            return false;
        }

        for (uint256 i; i < cars.length; ++i) {
            // check if it's possible to go back
            // If there is no other car sharing the past route, just move in one direction
            // This eliminates redundant operations in which the car moves back and forth between places.
            if (cars[i]._64Bit_3() != cars[i]._64Bit_4()) {
                // if this path has a solution
                if (
                    _moveCar(map, i, stepNum, cars, cars[i]._1Bit_2(), stepPath)
                ) {
                    hasSolution = true;
                }
            } else {
                if (_moveCar(map, i, stepNum, cars, 0, stepPath)) {
                    hasSolution = true;
                }

                if (_moveCar(map, i, stepNum, cars, 1, stepPath)) {
                    hasSolution = true;
                }
            }
        }
        return hasSolution;
    }

    function _moveCar(
        uint256 map,
        uint256 carId,
        uint256 stepNum,
        uint256[] memory cars,
        uint256 pos,
        StepPath memory stepPath
    ) internal view returns (bool) {
        // check that the current path is deeper than the best path
        if (stepNum >= stepPath.stepLength && stepPath.stepLength > 0) {
            return false;
        }
        // check max stack deep
        if (stepNum > MAX_STACK_DEEP) {
            return false;
        }

        uint256 _currentPosition = cars[carId]._64Bit_4();

        if (cars[carId]._1Bit_1() == 0) {
            (map, _currentPosition) = _moveX(map, _currentPosition, pos);
        } else {
            (map, _currentPosition) = _moveY(map, _currentPosition, pos);
        }

        // check if the current car collides with another car or fence
        if (
            map & _currentPosition == 0 &&
            _currentPosition & FENCE_OF_PARK_MAP == 0
        ) {
            // update linePosition of car
            uint256 prevLinePosition = cars[carId]._3Bit_2();
            if (pos == 0) {
                cars[carId] = cars[carId].set_3Bit_2(prevLinePosition - 1);
            } else {
                cars[carId] = cars[carId].set_3Bit_2(prevLinePosition + 1);
            }
            // check the shortest path for a given map
            if (_checkSnapMap(cars, stepNum)) {
                // update the step number
                ++stepNum;
                map = map + _currentPosition;
                // temp cars
                uint256[] memory _cars = new uint256[](cars.length);
                for (uint256 i; i < cars.length; ++i) {
                    _cars[i] = cars[i];
                }
                cars[carId] = cars[carId].set_3Bit_2(prevLinePosition);

                uint256 _step = carId.set_1Bit_1(pos);
                // check if car 1 has arrived at its destination
                if (carId == 0 && _currentPosition == COMPLETED_CAR0_POSITION) {
                    // update shortest solution
                    stepPath.steps[stepNum - 1] = _step;
                    stepPath.stepLength = stepNum;
                    stepPath.finalMap = map;
                    return true;
                } else {
                    // update car position
                    _cars[carId] = _cars[carId].set_64Bit_4(_currentPosition);

                    // update the prev pos of car
                    _cars[carId] = _cars[carId].set_1Bit_2(pos);

                    // update history positions
                    _updateCrossHistoryPosition(_cars, carId);
                    if (_move(map, stepNum, _cars, stepPath)) {
                        // if the path is the shortest path, store the path
                        stepPath.steps[stepNum - 1] = _step;

                        return true;
                    }
                }
            }
            cars[carId] = cars[carId].set_3Bit_2(prevLinePosition);
        }
        return false;
    }

    // update the history position of the current car
    function _printHistoryPosition(
        uint256[] memory cars,
        uint256 carId
    ) internal pure returns (bool) {
        uint256 historyPosition = cars[carId]._64Bit_3() |
            cars[carId]._64Bit_4();
        cars[carId] = cars[carId].set_64Bit_3(historyPosition);
        return true;
    }

    // reset the history position of crossing car
    function _resetHistoryPosition(
        uint256[] memory cars,
        uint256 carId
    ) internal pure returns (bool) {
        cars[carId] = cars[carId].set_64Bit_3(cars[carId]._64Bit_4());
        return true;
    }

    // update the current car's history position and reset the history position of another car that shares the path.
    function _updateCrossHistoryPosition(
        uint256[] memory cars,
        uint256 movedCarId
    ) internal pure returns (bool) {
        for (uint256 i; i < cars.length; ++i) {
            if (i == movedCarId) {
                _printHistoryPosition(cars, movedCarId);
            } else {
                if (cars[movedCarId]._64Bit_4() & cars[i]._64Bit_3() != 0) {
                    _resetHistoryPosition(cars, i);
                }
            }
        }
        return true;
    }

    function _moveX(
        uint256 map,
        uint256 position,
        uint256 pos
    ) internal pure returns (uint256, uint256) {
        assembly {
            map := sub(map, position)

            switch pos
            case 0 {
                position := shr(1, position)
            }
            default {
                position := shl(1, position)
            }
        }
        return (map, position);
    }

    function _moveY(
        uint256 map,
        uint256 position,
        uint256 pos
    ) internal pure returns (uint256, uint256) {
        assembly {
            map := sub(map, position)

            switch pos
            case 0 {
                position := shr(8, position)
            }
            default {
                position := shl(8, position)
            }
        }
        return (map, position);
    }

    function _createSnapMapMemorySpace(
        uint256 numOfCar,
        bool is3Len
    ) internal pure returns (bool) {
        if (numOfCar > 10) {
            return false;
        }
        uint m = 5 ** (numOfCar - 1);
        assembly {
            let endSnapMapMemoryAddress
            switch is3Len
            case 1 {
                endSnapMapMemoryAddress := add(START_MEMORY_ADDRESS, shl(5, m))
            }
            default {
                endSnapMapMemoryAddress := add(
                    START_MEMORY_ADDRESS,
                    shl(5, mul(m, 5))
                )
            }
            mstore(0x40, endSnapMapMemoryAddress)
        }
        return true;
    }

    function _initSnapMap(uint256[] memory cars) internal pure returns (bool) {
        uint256 mAddress = (_getTotalLinePosition(cars) << 3) +
            START_MEMORY_ADDRESS;
        assembly {
            mstore8(mAddress, 1)
        }
        return true;
    }

    function _checkSnapMap(
        uint256[] memory cars,
        uint256 stepNum
    ) internal pure returns (bool) {
        uint256 mAddress = (_getTotalLinePosition(cars) << 3) +
            START_MEMORY_ADDRESS;
        uint256 storedStepNum;

        assembly {
            storedStepNum := mload(mAddress)
            storedStepNum := shr(248, storedStepNum)
        }

        if (storedStepNum == 0) {
            assembly {
                mstore8(mAddress, stepNum)
            }
            return true;
        } else if (storedStepNum > stepNum) {
            assembly {
                mstore8(mAddress, stepNum)
            }
            return true;
        }

        return false;
    }

    function _getTotalLinePosition(
        uint256[] memory cars
    ) internal pure returns (uint256) {
        uint256 sum;
        for (uint256 i; i < cars.length; ++i) {
            sum += cars[i]._58Bit_1() * cars[i]._3Bit_2();
        }
        return sum;
    }
}
