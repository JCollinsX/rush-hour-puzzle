// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./interface/IRushHourSolver.sol";
import "./libraries/Helper.sol";

contract RushHourSolver is IRushHourSolver {
    using Helper for uint256;
    // (01111110)b = 126

    struct SnapMap {
        uint256 map;
        uint256 stepNum;
    }

    // @dev store step path for best solution.
    struct StepPath {
        uint256 stepLength;
        uint256[100] steps;
        uint256 finalMap;
    }

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

    // In solidity, excessive recursive function calls cause stack overflow.
    // In this solution, we set the highest stack deep to 36.
    uint256 private constant MAX_STACK_DEEP = 36;
    uint256 private constant MAX_SNAP_MAP_LENGTH = 3000;

    function solve(
        uint8[6][6] memory board
    ) external view override returns (Step[] memory) {
        StepPath memory stepPath;

        // @dev global variable. will transfer the pointer of cars to functions.
        // when cars is changes in the children functions, this cars will be changed.
        uint256[] memory cars;

        // 1  ~ 64  bit : current map value
        // 65 ~ 128 bit : prev map value
        uint256 map;

        // 1 ~ 64 bit : carId
        // 65 ~ 128 bit : stepNum
        // 255 bit: pos (positive or negative) positive -> 0, negative -> 1
        uint256 params;

        (map, cars) = getMap(board);

        SnapMap[] memory snapMap;
        snapMap = new SnapMap[](2000);

        // snap the map at start time
        snapMap[0].map = map;
        snapMap[0].stepNum = 1;

        // set carId to max
        params = params.set_64Bit_4(type(uint64).max);

        // set pos to 0
        // params = params.set_1Bit_1(0);

        _move(map, cars, params, stepPath, snapMap);

        Step[] memory finalSteps = new Step[](stepPath.stepLength);

        for (uint256 i; i < stepPath.stepLength; ++i) {
            if (cars[stepPath.steps[i]._64Bit_4()]._1Bit_1() == 0) {
                finalSteps[i] = Step(
                    uint8(stepPath.steps[i]._64Bit_4()) + 1,
                    stepPath.steps[i]._1Bit_1() == 0 ? MovementDirection.Right : MovementDirection.Left
                );
            } else {
                finalSteps[i] = Step(
                    uint8(stepPath.steps[i]._64Bit_4()) + 1,
                    stepPath.steps[i]._1Bit_1() == 0 ? MovementDirection.Down : MovementDirection.Up
                );
            }
        }

        return finalSteps;
    }

    function getMap(
        uint8[6][6] memory cells
    ) private pure returns (uint256 map, uint256[] memory cars) {
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
                        } else {
                            cars[carId] = cars[carId].set_1Bit_1(1);
                        }
                    }
                    cars[carId] += point;
                    map += point;
                }
                ++j;
            }
            ++i;
        }

        // print current position
        for (uint256 i; i < cars.length; ++i) {
            _resetHistoryPosition(cars, i);
        }
    }

    function _calcPoint(
        uint256 i,
        uint256 j
    ) private pure returns (uint256 point) {
        // 8 * 8 - 8 * (i + 1) - (j + 2) = 54 - 8 * i - j
        point = 1 << (54 - 8 * i - j);
    }

    function _move(
        uint256 map,
        uint256[] memory cars,
        uint256 params,
        StepPath memory stepPath,
        SnapMap[] memory snapMap
    ) internal view returns (bool hasSolution) {
        if (
            stepPath.stepLength <= params._64Bit_3() && stepPath.stepLength > 0
        ) {
            return false;
        }

        for (uint256 i; i < cars.length; ++i) {
            // set carId to i
            params = params.set_64Bit_4(i);

            // check if it's possible to go back
            // If there is no other car sharing the past route, just move in one direction
            // This eliminates redundant operations in which the car moves back and forth between places.
            if (cars[i]._64Bit_3() != cars[i]._64Bit_4()) {
                // set pos to prevPos
                params = params.set_1Bit_1(cars[i]._1Bit_2());
                // if this path has a solution
                if (_moveCar(map, cars, params, stepPath, snapMap)) {
                    hasSolution = true;
                }
            } else {
                // set pos to 0
                params = params.set_1Bit_1(0);

                if (_moveCar(map, cars, params, stepPath, snapMap)) {
                    hasSolution = true;
                }

                // set pos to 1
                params = params.set_1Bit_1(1);
                if (_moveCar(map, cars, params, stepPath, snapMap)) {
                    hasSolution = true;
                }
            }
        }
        return hasSolution;
    }

    function _moveCar(
        uint256 map,
        uint256[] memory cars,
        uint256 params,
        StepPath memory stepPath,
        SnapMap[] memory snapMap
    ) internal view returns (bool) {
        // check that the current path is deeper than the best path
        if (
            params._64Bit_3() >= stepPath.stepLength && stepPath.stepLength > 0
        ) {
            return false;
        }
        // check max stack deep
        if (params._64Bit_3() > MAX_STACK_DEEP) {
            return false;
        }

        uint256 carId = params._64Bit_4();
        uint256 pos = params._1Bit_1();
        uint256 _currentPosition = cars[carId]._64Bit_4();

        if (cars[carId]._1Bit_1() == 0) {
            (map, _currentPosition) = _moveX(map, _currentPosition, pos);
        } else {
            (map, _currentPosition) = _moveY(map, _currentPosition, pos);
        }

        uint256 _map = map + _currentPosition;

        // temp cars
        uint256[] memory _cars = new uint256[](cars.length);
        for (uint256 i; i < cars.length; ++i) {
            _cars[i] = cars[i];
        }

        // check if the current car collides with another car or fence
        if (
            map & _currentPosition == 0 &&
            _currentPosition & FENCE_OF_PARK_MAP == 0
        ) {
            // check the shortest path for a given map
            if (_checkSnapMap(snapMap, _map, params._64Bit_3())) {
                // update map
                map = _map;
                uint256 _step = carId.set_1Bit_1(pos);
                // check if car 1 has arrived at its destination
                if (carId == 0 && _currentPosition == COMPLETED_CAR0_POSITION) {
                    // update shortest solution
                    stepPath.steps[params._64Bit_3()] = _step;
                    stepPath.stepLength = params._64Bit_3() + 1;
                    stepPath.finalMap = map;
                    return true;
                } else {
                    // update car position
                    cars[carId] = cars[carId].set_64Bit_4(_currentPosition);
                    // update the step number
                    params = params.set_64Bit_3(params._64Bit_3() + 1);
                    // update the prev pos of car
                    cars[carId] = cars[carId].set_1Bit_2(pos);
                    // update history positions
                    _updateCrossHistoryPosition(cars, carId);
                    if (_move(map, cars, params, stepPath, snapMap)) {
                        // if the path is the shortest path, store the path
                        stepPath.steps[params._64Bit_3() - 1] = _step;

                        // restore cars
                        for (uint256 i; i < cars.length; ++i) {
                            cars[i] = _cars[i];
                        }
                        return true;
                    }
                }
            }
        }

        // restore cars
        for (uint256 i; i < cars.length; ++i) {
            cars[i] = _cars[i];
        }
        return false;
    }

    function _checkSnapMap(
        SnapMap[] memory snapMap,
        uint256 map,
        uint256 stepNum
    ) internal pure returns (bool) {
        uint256 i;
        while (i < snapMap.length) {
            if (snapMap[i].map == map) {
                if (snapMap[i].stepNum > stepNum + 1) {
                    snapMap[i].stepNum = stepNum + 1;
                    return true;
                } else {
                    return false;
                }
            }

            if (snapMap[i].map == 0) {
                break;
            }
            ++i;
        }
        if (i < snapMap.length) {
            snapMap[i].map = map;
            snapMap[i].stepNum = stepNum + 1;
            return true;
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
        map = map - position;
        if (pos == 0) {
            position = position >> 1;
        } else {
            position = position << 1;
        }
        return (map, position);
    }

    function _moveY(
        uint256 map,
        uint256 position,
        uint256 pos
    ) internal pure returns (uint256, uint256) {
        map = map - position;
        if (pos == 0) {
            position = position >> 8;
        } else {
            position = position << 8;
        }
        return (map, position);
    }
}
