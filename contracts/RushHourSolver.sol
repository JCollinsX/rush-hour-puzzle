// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./interface/IRushHourSolver.sol";
import "./libraries/VehicleLib.sol";

contract RushHourSolver is IRushHourSolver {
    using VehicleLib for VehicleLib.Vehicle;

    struct States {
        uint8 stateId;
        VehicleLib.Vehicle vehicle;
        Direction direction;
        uint8[6][6] board;
    }

    struct Queue {
        uint8 queueId;
        Step[] steps;
        uint8[6][6] board;
    }

    function solve(uint8[6][6] memory board) external pure override returns (Step[] memory) {
        bytes32[] memory visited = new bytes32[](50);
        Queue[] memory queue = new Queue[](50);
        uint8 visitedIndex = 0;
        uint8 queueIndex = 0;
        queue[queueIndex] = Queue({
            queueId: 1,
            steps: new Step[](0),
            board: board
        });

        uint8[17] memory vehicleIds; // Array to store encountered vehicle IDs
        uint8 count = 0;
        
        for (uint8 i = 0; i < 6; i++) {
            for (uint8 j = 0; j < 6; j++) {
                uint8 vehicleId = board[i][j];
                if (vehicleId != 0 && vehicleIds[vehicleId] == 0) {
                    vehicleIds[vehicleId] = 1;
                    count++;
                }
            }
        }

        for (uint8 depth = 1; depth <= 100; depth++) {
            Queue memory popedQueue = pop(queue);

            if (isSolved(popedQueue.board) || popedQueue.queueId == 0) {
                return popedQueue.steps;
            }

            VehicleLib.Vehicle[] memory vehicles = new VehicleLib.Vehicle[](count);
            for (uint8 i = 0; i < 6; i++) {
                for (uint8 j = 0; j < 6; j++) {
                    if (popedQueue.board[i][j] == 1) {
                        if (vehicles[0].carId == 0) {
                            vehicles[0] = VehicleLib.Vehicle(1, i, j, i, j, true);
                        } else {
                            vehicles[0].setEndLocation(i, j);
                        }
                    }
                    if (popedQueue.board[i][j] != 0) {
                        if (vehicles[popedQueue.board[i][j] - 1].carId == 0) {
                            vehicles[popedQueue.board[i][j] - 1] = VehicleLib.Vehicle(popedQueue.board[i][j], i, j, i, j, false);
                        } else {
                            vehicles[popedQueue.board[i][j] - 1].setEndLocation(i, j);
                        }
                    }
                }
            }

            States[] memory states = getStates(popedQueue.board, vehicles);

            for (uint8 i = 0; i < states.length; i++) {
                if (states[i].stateId > 0) {
                    bytes32 hash = hashBoard(states[i].board);

                    // console.log(states[i].board.board[0][0], states[i].board.board[0][1], states[i].board.board[0][2]);
                    // console.log(states[i].board.board[0][3], states[i].board.board[0][4], states[i].board.board[0][5]);
                    // console.log(states[i].board.board[1][0], states[i].board.board[1][1], states[i].board.board[1][2]);
                    // console.log(states[i].board.board[1][3], states[i].board.board[1][4], states[i].board.board[1][5]);
                    // console.log(states[i].board.board[2][0], states[i].board.board[2][1], states[i].board.board[2][2]);
                    // console.log(states[i].board.board[2][3], states[i].board.board[2][4], states[i].board.board[2][5]);
                    // console.log(states[i].board.board[3][0], states[i].board.board[3][1], states[i].board.board[3][2]);
                    // console.log(states[i].board.board[3][3], states[i].board.board[3][4], states[i].board.board[3][5]);
                    // console.log(states[i].board.board[4][0], states[i].board.board[4][1], states[i].board.board[4][2]);
                    // console.log(states[i].board.board[4][3], states[i].board.board[4][4], states[i].board.board[4][5]);
                    // console.log(states[i].board.board[5][0], states[i].board.board[5][1], states[i].board.board[5][2]);
                    // console.log(states[i].board.board[5][3], states[i].board.board[5][4], states[i].board.board[5][5]);

                    if (!isVisited(visited, hash)) {
                        Step[] memory newSteps = append(popedQueue.steps, Step(states[i].vehicle.carId, states[i].direction));

                        queue[queueIndex] = Queue({
                            queueId: queueIndex + 2,
                            steps: newSteps,
                            board: states[i].board
                        });
                        queueIndex++;

                        visited[visitedIndex] = hash;
                        visitedIndex++;
                    }
                }
            }
        }

        return new Step[](0);
    }

    function getStates(uint8[6][6] memory _gameBoard, VehicleLib.Vehicle[] memory _vehicles) internal pure returns (States[] memory) {
        States[] memory states = new States[](36);
        uint8 stateIndex = 0;

        for (uint8 row = 0; row < 6; row++) {
            for (uint8 column = 0; column < 6; column++) {
                uint8 vehicleId = _gameBoard[column][row];
                if (vehicleId != 0) {
                    VehicleLib.Vehicle memory vehicle = _vehicles[vehicleId - 1];

                    if (isMovable(vehicle, _gameBoard, Direction.FORWARD)) {
                        uint8[6][6] memory newGameBoard = deepCopy(_gameBoard);
                        VehicleLib.Vehicle memory newVehicle = VehicleLib.Vehicle(vehicle.carId, vehicle.startX, vehicle.startY, vehicle.endX, vehicle.endY, vehicle.mainVehicle);
                        newVehicle.moveForward();

                        (uint8[] memory vehicleX, uint8[] memory vehicleY) = vehicle.getOccupiedLocations();
                        (uint8[] memory newVehicleX, uint8[] memory newVehicleY) = newVehicle.getOccupiedLocations();
                        
                        for (uint8 i = 0; i < vehicleX.length; i++) {
                            newGameBoard[vehicleX[i]][vehicleY[i]] = 0;
                        }

                        for (uint8 i = 0; i < newVehicleX.length; i++) {
                            newGameBoard[newVehicleX[i]][newVehicleY[i]] = vehicle.carId;
                        }

                        States memory newState = States({
                            stateId: stateIndex + 1,
                            vehicle: vehicle,
                            direction: Direction.FORWARD,
                            board: newGameBoard
                        });
                        states[stateIndex] = newState;
                        stateIndex++;
                    }
                    if (isMovable(vehicle, _gameBoard, Direction.BACKWARD)) {
                        uint8[6][6] memory newGameBoard = deepCopy(_gameBoard);
                        VehicleLib.Vehicle memory newVehicle = VehicleLib.Vehicle(vehicle.carId, vehicle.startX, vehicle.startY, vehicle.endX, vehicle.endY, vehicle.mainVehicle);
                        newVehicle.moveBackward();

                        (uint8[] memory vehicleX, uint8[] memory vehicleY) = vehicle.getOccupiedLocations();
                        (uint8[] memory newVehicleX, uint8[] memory newVehicleY) = newVehicle.getOccupiedLocations();
                        
                        for (uint8 i = 0; i < vehicleX.length; i++) {
                            newGameBoard[vehicleX[i]][vehicleY[i]] = 0;
                        }

                        for (uint8 i = 0; i < newVehicleX.length; i++) {
                            newGameBoard[newVehicleX[i]][newVehicleY[i]] = vehicle.carId;
                        }

                        States memory newState = States({
                            stateId: stateIndex + 1,
                            vehicle: vehicle,
                            direction: Direction.BACKWARD,
                            board: newGameBoard
                        });
                        states[stateIndex] = newState;
                        stateIndex++;
                    }
                }
            }
        }

        return states;
    }

    function isMovable(
        VehicleLib.Vehicle memory _vehicle,
        uint8[6][6] memory _gameBoard,
        Direction _direction
    ) internal pure returns (bool) {
        if (_vehicle.getOrientation() == VehicleLib.Orientation.HORIZONTAL && _direction == Direction.FORWARD) {
            uint8 x = _vehicle.endX;
            uint8 y = _vehicle.endY + 1;

            if (y < 6) {
                uint8 boardVehicle = _gameBoard[x][y];
                if (boardVehicle != 0) {
                    return false;
                }
            } else {
                return false;
            }
        }

        if (_vehicle.getOrientation() == VehicleLib.Orientation.HORIZONTAL && _direction == Direction.BACKWARD) {
            if (_vehicle.startY == 0) {
                return false;
            }
            uint8 x = _vehicle.startX;
            uint8 y = _vehicle.startY - 1;

            if (y < 6 && y > 0) {
                uint8 boardVehicle = _gameBoard[x][y];
                if (boardVehicle != 0) {
                    return false;
                }
            } else {
                return false;
            }
        }

        if (_vehicle.getOrientation() == VehicleLib.Orientation.VERTICAL && _direction == Direction.FORWARD) {
            uint8 x = _vehicle.endX + 1;
            uint8 y = _vehicle.endY;

            if (x < 6 && x > 0) {
                uint8 boardVehicle = _gameBoard[x][y];
                if (boardVehicle != 0) {
                    return false;
                }
            } else {
                return false;
            }
        }

        if (_vehicle.getOrientation() == VehicleLib.Orientation.VERTICAL && _direction == Direction.BACKWARD) {
            if (_vehicle.startX == 0) {
                return false;
            }
            uint8 x = _vehicle.startX - 1;
            uint8 y = _vehicle.startY;

            if (x < 6 && x > 0) {
                uint8 boardVehicle = _gameBoard[x][y];
                if (boardVehicle != 0) {
                    return false;
                }
            } else {
                return false;
            }
        }

        return true;
    }

    function hashBoard(uint8[6][6] memory _board) internal pure returns (bytes32) {
        bytes32 row1 = keccak256(abi.encodePacked(
            _board[0][0], _board[0][1], _board[0][2], _board[0][3], _board[0][4], _board[0][5],
            _board[1][0], _board[1][1], _board[1][2], _board[1][3], _board[1][4], _board[1][5]
        ));
        bytes32 row2 = keccak256(abi.encodePacked(
            _board[2][0], _board[2][1], _board[2][2], _board[2][3], _board[2][4], _board[2][5],
            _board[3][0], _board[3][1], _board[3][2], _board[3][3], _board[3][4], _board[3][5]
        ));
        bytes32 row3 = keccak256(abi.encodePacked(
            _board[4][0], _board[4][1], _board[4][2], _board[4][3], _board[4][4], _board[4][5],
            _board[5][0], _board[5][1], _board[5][2], _board[5][3], _board[5][4], _board[5][5]
        ));
        return keccak256(abi.encodePacked(row1, row2, row3));
    }

    function deepCopy(uint8[6][6] memory _board) internal pure returns (uint8[6][6] memory) {
        uint8[6][6] memory newBoard;
        for (uint8 i = 0; i < 6; i++) {
            for (uint8 j = 0; j < 6; j++) {
                newBoard[i][j] = _board[i][j];
            }
        }
        return newBoard;
    }

    function pop(Queue[] memory _queue) internal pure returns (Queue memory) {
        Queue memory queue;
        for (uint8 i = 0; i < _queue.length - 1; i++) {
            if (_queue[i].queueId > 0) {
                queue = _queue[i];
                delete _queue[i];
                return queue;
            }
        }
        return queue;
    }

    function append(Step[] memory _steps, Step memory _step) internal pure returns (Step[] memory) {
        Step[] memory newSteps = new Step[](_steps.length + 1);
        for (uint8 i = 0; i < _steps.length; i++) {
            newSteps[i] = _steps[i];
        }
        newSteps[_steps.length] = _step;
        return newSteps;
    }

    function isVisited(bytes32[] memory _visited, bytes32 _hash) internal pure returns (bool) {
        for (uint8 i = 0; i < _visited.length; i++) {
            if (_visited[i] == _hash) {
                return true;
            }
        }

        return false;
    }
    
    function isSolved(uint8[6][6] memory _board) internal pure returns (bool) {
        return _board[2][5] == 1;
    }
}
