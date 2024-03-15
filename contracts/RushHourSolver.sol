// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./interface/IRushHourSolver.sol";
import "./libraries/GameBoardLib.sol";
import "./libraries/VehicleLib.sol";
import "hardhat/console.sol";

contract RushHourSolver is IRushHourSolver {
    using VehicleLib for VehicleLib.Vehicle;
    using GameBoardLib for GameBoardLib.GameBoard;

    struct States {
        uint8 stateId;
        VehicleLib.Vehicle vehicle;
        Direction direction;
        GameBoardLib.GameBoard board;
    }

    struct Queue {
        Step[] steps;
        GameBoardLib.GameBoard board;
    }

    uint8 public constant BOARD_HEIGHT = 6;
    uint8 public constant BOARD_WIDTH = 6;

    function solve(uint8[6][6] memory board) external view override returns (Step[] memory) {
        Step[] memory steps = new Step[](100);
        GameBoardLib.GameBoard memory gameBoard;
        gameBoard.setBoard(board);

        VehicleLib.Vehicle[] memory vehicles = new VehicleLib.Vehicle[](16);
        for (uint8 i = 0; i < 6; i++) {
            for (uint8 j = 0; j < 6; j++) {
                if (board[i][j] == 1) {
                    if (vehicles[0].carId == 0) {
                        vehicles[0] = VehicleLib.Vehicle(1, i, j, i, j, true);
                    } else {
                        vehicles[0].setEndLocation(i, j);
                    }
                }
                if (board[i][j] != 0) {
                    if (vehicles[board[i][j] - 1].carId == 0) {
                        vehicles[board[i][j] - 1] = VehicleLib.Vehicle(board[i][j] - 1, i, j, i, j, false);
                    } else {
                        vehicles[board[i][j] - 1].setEndLocation(i, j);
                    }
                }
            }
        }

        bytes32[] memory visited = new bytes32[](100);
        Queue[] memory queue = new Queue[](100);
        uint8 visitedIndex = 0;
        uint8 queueIndex = 0;
        queue[queueIndex] = Queue({
            steps: new Step[](0),
            board: gameBoard
        });

        for (uint8 depth = 1; depth <= 50; depth++) {
            Queue memory popedQueue = pop(queue);

            for (uint8 i = 0; i < popedQueue.steps.length; i++) {
                console.log(depth);
                console.log(popedQueue.steps[i].carId, popedQueue.steps[i].direction == Direction.FORWARD ? "FORWARD" : "BACKWARD");
            }

            console.log(popedQueue.board.board[0][0], popedQueue.board.board[0][1], popedQueue.board.board[0][2]);
            console.log(popedQueue.board.board[0][3], popedQueue.board.board[0][4], popedQueue.board.board[0][5]);
            console.log(popedQueue.board.board[1][0], popedQueue.board.board[1][1], popedQueue.board.board[1][2]);
            console.log(popedQueue.board.board[1][3], popedQueue.board.board[1][4], popedQueue.board.board[1][5]);
            console.log(popedQueue.board.board[2][0], popedQueue.board.board[2][1], popedQueue.board.board[2][2]);
            console.log(popedQueue.board.board[2][3], popedQueue.board.board[2][4], popedQueue.board.board[2][5]);
            console.log(popedQueue.board.board[3][0], popedQueue.board.board[3][1], popedQueue.board.board[3][2]);
            console.log(popedQueue.board.board[3][3], popedQueue.board.board[3][4], popedQueue.board.board[3][5]);
            console.log(popedQueue.board.board[4][0], popedQueue.board.board[4][1], popedQueue.board.board[4][2]);
            console.log(popedQueue.board.board[4][3], popedQueue.board.board[4][4], popedQueue.board.board[4][5]);
            console.log(popedQueue.board.board[5][0], popedQueue.board.board[5][1], popedQueue.board.board[5][2]);
            console.log(popedQueue.board.board[5][3], popedQueue.board.board[5][4], popedQueue.board.board[5][5]);

            console.log(GameBoardLib.isSolved(popedQueue.board));
            if (GameBoardLib.isSolved(popedQueue.board)) {
                return popedQueue.steps;
            }

            States[] memory states = getStates(popedQueue.board, vehicles);

            for (uint8 i = 0; i < states.length; i++) {
                if (states[i].stateId > 0) {
                    bytes32 hash = hashBoard(states[i].board.board);

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
                        // console.log(states[i].vehicle.carId, states[i].direction == Direction.FORWARD ? "FORWARD" : "BACKWARD");
                        // steps[stepIndex] = Step(states[i].vehicle.carId, states[i].direction);
                        // stepIndex++;

                        Step[] memory newSteps = append(popedQueue.steps, Step(states[i].vehicle.carId, states[i].direction));

                        queue[queueIndex] = Queue({
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

        return steps;
    }

    function getStates(GameBoardLib.GameBoard memory _gameBoard, VehicleLib.Vehicle[] memory _vehicles) internal pure returns (States[] memory) {
        States[] memory states = new States[](36);
        uint8 stateIndex = 0;

        for (uint8 row = 0; row < BOARD_HEIGHT; row++) {
            for (uint8 column = 0; column < BOARD_WIDTH; column++) {
                uint8 vehicleId = _gameBoard.board[column][row];
                if (vehicleId != 0) {
                    VehicleLib.Vehicle memory vehicle = _vehicles[vehicleId - 1];

                    if (isMovable(vehicle, _gameBoard, Direction.FORWARD)) {
                        GameBoardLib.GameBoard memory newGameBoard;
                        newGameBoard.setBoard(deepCopy(_gameBoard.board));
                        VehicleLib.Vehicle memory newVehicle = VehicleLib.Vehicle(vehicle.carId, vehicle.startX, vehicle.startY, vehicle.endX, vehicle.endY, vehicle.mainVehicle);
                        newVehicle.moveForward();

                        (uint8[] memory vehicleX, uint8[] memory vehicleY) = vehicle.getOccupiedLocations();
                        (uint8[] memory newVehicleX, uint8[] memory newVehicleY) = newVehicle.getOccupiedLocations();
                        
                        for (uint8 i = 0; i < vehicleX.length; i++) {
                            newGameBoard.board[vehicleX[i]][vehicleY[i]] = 0;
                        }

                        for (uint8 i = 0; i < newVehicleX.length; i++) {
                            newGameBoard.board[newVehicleX[i]][newVehicleY[i]] = vehicle.carId;
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
                        GameBoardLib.GameBoard memory newGameBoard;
                        newGameBoard.setBoard(deepCopy(_gameBoard.board));
                        VehicleLib.Vehicle memory newVehicle = VehicleLib.Vehicle(vehicle.carId, vehicle.startX, vehicle.startY, vehicle.endX, vehicle.endY, vehicle.mainVehicle);
                        newVehicle.moveBackward();

                        (uint8[] memory vehicleX, uint8[] memory vehicleY) = vehicle.getOccupiedLocations();
                        (uint8[] memory newVehicleX, uint8[] memory newVehicleY) = newVehicle.getOccupiedLocations();
                        
                        for (uint8 i = 0; i < vehicleX.length; i++) {
                            newGameBoard.board[vehicleX[i]][vehicleY[i]] = 0;
                        }

                        for (uint8 i = 0; i < newVehicleX.length; i++) {
                            newGameBoard.board[newVehicleX[i]][newVehicleY[i]] = vehicle.carId;
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
        GameBoardLib.GameBoard memory _gameBoard,
        Direction _direction
    ) internal pure returns (bool) {
        if (_vehicle.getOrientation() == VehicleLib.Orientation.HORIZONTAL && _direction == Direction.FORWARD) {
            uint8 x = _vehicle.endX;
            uint8 y = _vehicle.endY + 1;

            if (y < BOARD_HEIGHT) {
                uint8 boardVehicle = _gameBoard.board[x][y];
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

            if (y < BOARD_HEIGHT && y > 0) {
                uint8 boardVehicle = _gameBoard.board[x][y];
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

            if (x < BOARD_HEIGHT && x > 0) {
                uint8 boardVehicle = _gameBoard.board[x][y];
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

            if (x < BOARD_HEIGHT && x > 0) {
                uint8 boardVehicle = _gameBoard.board[x][y];
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
        Queue memory queue = _queue[0];
        for (uint8 i = 0; i < _queue.length - 1; i++) {
            _queue[i] = _queue[i + 1];
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
    
    // function dfs(uint8 row, uint8 col, uint8 depth, uint8[6][6] memory board, Step[] memory currentSolution) internal view returns (Step[] memory solution) {
        
    //     console.log(board[0][0], board[0][1], board[0][2]);
    //     console.log(board[0][3], board[0][4], board[0][5]);
    //     console.log(board[1][0], board[1][1], board[1][2]);
    //     console.log(board[1][3], board[1][4], board[1][5]);
    //     console.log(board[2][0], board[2][1], board[2][2]);
    //     console.log(board[2][3], board[2][4], board[2][5]);
    //     console.log(board[3][0], board[3][1], board[3][2]);
    //     console.log(board[3][3], board[3][4], board[3][5]);
    //     console.log(board[4][0], board[4][1], board[4][2]);
    //     console.log(board[4][3], board[4][4], board[4][5]);
    //     console.log(board[5][0], board[5][1], board[5][2]);
    //     console.log(board[5][3], board[5][4], board[5][5]);

    //     console.log("row: ", row);

    //     if (depth == 0) {
    //         return new Step[](0);
    //     }
        
    //     Step[] memory solutionCopy = new Step[](currentSolution.length);
    //     for (uint8 i = 0; i < currentSolution.length; i++) {
    //         solutionCopy[i] = currentSolution[i];
    //     }
        
    //     for (uint8 i = 0; i < 6; i++) {
    //         for (uint8 j = 0; j < 6; j++) {
    //             if (i == row && j == col) {
    //                 continue; // Skip the red car
    //             }
                
    //             if (board[i][j] != 0) {
    //                 continue; // Skip non-empty cells
    //             }
                
    //             // Move the vehicle to the empty cell
    //             uint8[6][6] memory newBoard = board;
    //             newBoard[i][j] = board[row][col];
    //             newBoard[row][col] = 0;
                
    //             Step[] memory newSolution = new Step[](currentSolution.length + 1);
    //             for (uint8 k = 0; k < currentSolution.length; k++) {
    //                 newSolution[k] = currentSolution[k];
    //             }
                
    //             if (i == row) {
    //                 // Move horizontally
    //                 if (j < col) {
    //                     newSolution[currentSolution.length] = Step(board[i][j], MovementDirection.Left);
    //                 } else {
    //                     newSolution[currentSolution.length] = Step(board[i][j], MovementDirection.Right);
    //                 }
    //             } else {
    //                 // Move vertically
    //                 if (i < row) {
    //                     newSolution[currentSolution.length] = Step(board[i][j], MovementDirection.Up);
    //                 } else {
    //                     newSolution[currentSolution.length] = Step(board[i][j], MovementDirection.Down);
    //                 }
    //             }
                
    //             // Check if the puzzle is solved
    //             if (newBoard[2][5] == 1) {
    //                 currentSolution = newSolution;
    //                 return newSolution;
    //             }
                
    //             // Recursively search with reduced depth
    //             Step[] memory reducedDepthSolution = dfs(i, j, depth - 1, newBoard, newSolution);
    //             if (reducedDepthSolution.length > 0) {
    //                 return reducedDepthSolution;
    //             }

    //             // Undo the move
    //             if (i == row) {
    //                 // Undo horizontal movement
    //                 if (j < col) {
    //                     delete newSolution[currentSolution.length];
    //                     newBoard[row][col] = board[i][j];
    //                     newBoard[i][j] = 0;
    //                 } else {
    //                     delete newSolution[currentSolution.length];
    //                     newBoard[row][col] = board[i][j];
    //                     newBoard[i][j] = 0;
    //                 }
    //             } else {
    //                 // Undo vertical movement
    //                 if (i < row) {
    //                     delete newSolution[currentSolution.length];
    //                     newBoard[row][col] = board[i][j];
    //                     newBoard[i][j] = 0;
    //                 } else {
    //                     delete newSolution[currentSolution.length];
    //                     newBoard[row][col] = board[i][j];
    //                     newBoard[i][j] = 0;
    //                 }
    //             }
    //         }
    //     }
        
    //     return new Step[](0);
    // }
}
