// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./interface/IRushHourSolver.sol";
import "./libraries/CarLib.sol";
import "hardhat/console.sol";

contract RushHourSolverHeuristics is IRushHourSolver {
    using CarLib for CarLib.Car;

    function solve(uint8[6][6] memory board) external view override returns (Step[] memory) {
        bytes32[] memory visited;
        Step[] memory steps;

        // Initialize board & cars
        (CarLib.Car[] memory cars, uint8[8][8] memory newBoard) = initialize(board);

        (bool success, Step[] memory newStep) = moveCars(visited, newBoard, cars, steps);
        if (success) {
            return newStep;
        }

        return steps;
    }

    function moveCars(bytes32[] memory _visited, uint8[8][8] memory _gameBoard, CarLib.Car[] memory _cars, Step[] memory _steps) internal view returns (bool, Step[] memory) {
        bytes32 hash = hashBoard(_gameBoard);

        if (isSolved(_gameBoard)) {
            return (true, _steps);
        }

        if (!isVisited(_visited, hash)) {
            _visited = appendVisited(_visited, hash);
        } else {
            return (false, _steps);
        }

        _cars = applyHeuristics(_gameBoard, _cars);

        for (uint8 i = 0; i < _cars.length; i++) {
            CarLib.Car memory _car = _cars[i];
            if (!_car.isVertical) {
                if (_car.isMainCar) { // Horizontal Car
                    // Red car Heuristic - Try moving right first
                    if (_gameBoard[_car.x][_car.y + _car.size] == 0) {
                        _gameBoard[_car.x][_car.y + _car.size] = _car.carId;
                        _gameBoard[_car.x][_car.y] = 0;
                        _car.y++;
                        _cars[i] = _car;

                        (bool success, Step[] memory newStep) = moveCars(_visited, _gameBoard, _cars, _steps);
                        if (success) {
                            return (true, append(newStep, Step(_car.carId, MovementDirection.Right)));
                        }

                        // Cancel the move
                        _car.y--;
                        _gameBoard[_car.x][_car.y + _car.size] = 0;
                        _gameBoard[_car.x][_car.y] = _car.carId;
                        _cars[i] = _car;
                    }
                    if (_gameBoard[_car.x][_car.y - 1] == 0) { // Red car Heuristic - Try moving left
                        _gameBoard[_car.x][_car.y - 1] = _car.carId;
                        _gameBoard[_car.x][_car.y + _car.size - 1] = 0;
                        _car.y--;
                        _cars[i] = _car;

                        (bool success, Step[] memory newStep) = moveCars(_visited, _gameBoard, _cars, _steps);
                        if (success) {
                            return (true, append(newStep, Step(_car.carId, MovementDirection.Left)));
                        }

                        // Cancel the move
                        _car.y++;
                        _gameBoard[_car.x][_car.y - 1] = 0;
                        _gameBoard[_car.x][_car.y + _car.size - 1] = _car.carId;
                        _cars[i] = _car;
                    }
                } else { // all other horizontal cars: try moving left first
                    if (_gameBoard[_car.x][_car.y - 1] == 0) {
                        _gameBoard[_car.x][_car.y - 1] = _car.carId;
                        _gameBoard[_car.x][_car.y + _car.size - 1] = 0;
                        _car.y--;
                        _cars[i] = _car;

                        (bool success, Step[] memory newStep) = moveCars(_visited, _gameBoard, _cars, _steps);
                        if (success) {
                            return (true, append(newStep, Step(_car.carId, MovementDirection.Left)));
                        }

                        // Cancel the move
                        _car.y++;
                        _gameBoard[_car.x][_car.y - 1] = 0;
                        _gameBoard[_car.x][_car.y + _car.size - 1] = _car.carId;
                        _cars[i] = _car;
                    }
                    if (_gameBoard[_car.x][_car.y + _car.size] == 0) {
                        _gameBoard[_car.x][_car.y + _car.size] = _car.carId;
                        _gameBoard[_car.x][_car.y] = 0;
                        _car.y++;
                        _cars[i] = _car;

                        (bool success, Step[] memory newStep) = moveCars(_visited, _gameBoard, _cars, _steps);
                        if (success) {
                            return (true, append(newStep, Step(_car.carId, MovementDirection.Right)));
                        }

                        // Cancel the move
                        _car.y--;
                        _gameBoard[_car.x][_car.y + _car.size] = 0;
                        _gameBoard[_car.x][_car.y] = _car.carId;
                        _cars[i] = _car;
                    }
                }
            } else { // Vertical Cars
                if (_car.size == 3) { // Trucks: move down first
                    if (_gameBoard[_car.x + _car.size][_car.y] == 0) {
                        _gameBoard[_car.x + _car.size][_car.y] = _car.carId;
                        _gameBoard[_car.x][_car.y] = 0;
                        _car.x++;
                        _cars[i] = _car;

                        (bool success, Step[] memory newStep) = moveCars(_visited, _gameBoard, _cars, _steps);
                        if (success) {
                            return (true, append(newStep, Step(_car.carId, MovementDirection.Down)));
                        }

                        // Cancel the move
                        _car.x--;
                        _gameBoard[_car.x + _car.size][_car.y] = 0;
                        _gameBoard[_car.x][_car.y] = _car.carId;
                        _cars[i] = _car;
                    }
                    if (_gameBoard[_car.x - 1][_car.y] == 0) {
                        _gameBoard[_car.x - 1][_car.y] = _car.carId;
                        _gameBoard[_car.x + _car.size - 1][_car.y] = 0;
                        _car.x--;
                        _cars[i] = _car;

                        (bool success, Step[] memory newStep) = moveCars(_visited, _gameBoard, _cars, _steps);
                        if (success) {
                            return (true, append(newStep, Step(_car.carId, MovementDirection.Up)));
                        }

                        // Cancel the move
                        _car.x++;
                        _gameBoard[_car.x - 1][_car.y] = 0;
                        _gameBoard[_car.x + _car.size - 1][_car.y] = _car.carId;
                        _cars[i] = _car;
                    }
                } else {
                    if (_gameBoard[_car.x - 1][_car.y] == 0) {
                        _gameBoard[_car.x - 1][_car.y] = _car.carId;
                        _gameBoard[_car.x + _car.size - 1][_car.y] = 0;
                        _car.x--;
                        _cars[i] = _car;

                        (bool success, Step[] memory newStep) = moveCars(_visited, _gameBoard, _cars, _steps);
                        if (success) {
                            return (true, append(newStep, Step(_car.carId, MovementDirection.Up)));
                        }

                        // Cancel the move
                        _car.x++;
                        _gameBoard[_car.x - 1][_car.y] = 0;
                        _gameBoard[_car.x + _car.size - 1][_car.y] = _car.carId;
                        _cars[i] = _car;
                    }
                    if (_gameBoard[_car.x + _car.size][_car.y] == 0) {
                        _gameBoard[_car.x + _car.size][_car.y] = _car.carId;
                        _gameBoard[_car.x][_car.y] = 0;
                        _car.x++;
                        _cars[i] = _car;

                        (bool success, Step[] memory newStep) = moveCars(_visited, _gameBoard, _cars, _steps);
                        if (success) {
                            return (true, append(newStep, Step(_car.carId, MovementDirection.Down)));
                        }

                        // Cancel the move
                        _car.x--;
                        _gameBoard[_car.x + _car.size][_car.y] = 0;
                        _gameBoard[_car.x][_car.y] = _car.carId;
                        _cars[i] = _car;
                    }
                }
            }

            if (isSolved(_gameBoard)) {
                return (true, _steps);
            }
        }
        return (false, _steps);
    }

    function initialize(uint8[6][6] memory _gameBoard) internal pure returns (CarLib.Car[] memory, uint8[8][8] memory) {
        uint8 count = countCars(_gameBoard);
        uint8[8][8] memory newBoard = changeBoard(_gameBoard);
        CarLib.Car[] memory cars = new CarLib.Car[](count);

        for (uint8 i = 0; i < 8; i++) {
            for (uint8 j = 0; j < 8; j++) {
                uint8 carId = newBoard[i][j];
                if (carId != 0 && carId != 99 && cars[carId - 1].carId == 0) {
                    CarLib.Car memory _car = CarLib.Car(carId, 1, i, j, i + 1 < 8 && newBoard[i + 1][j] == carId, carId == 1);
                    if (_car.isVertical) {
                        for (uint8 k = i + 1; k < 8; k++) {
                            if (newBoard[k][j] == carId) {
                                _car.size++;
                            } else {
                                break;
                            }
                        }
                    } else {
                        for (uint8 k = j + 1; k < 8; k++) {
                            if (newBoard[i][k] == carId) {
                                _car.size++;
                            } else {
                                break;
                            }
                        }
                    }
                    cars[carId - 1] = _car;
                }
            }
        }

        return (cars, newBoard);
    }

    function sendToFront(CarLib.Car[] memory _cars, uint8 _carId) internal pure returns (CarLib.Car[] memory) {
        CarLib.Car[] memory cars = new CarLib.Car[](_cars.length);
        uint8 index;
        for (uint8 i = 0; i < _cars.length; i++) {
            if (_cars[i].carId == _carId) {
                cars[0] = _cars[i];
            } else {
                index++;
                cars[index] = _cars[i];
            }
        }
        return cars;
    }

    function sendToBack(CarLib.Car[] memory _cars, uint8 _carId) internal pure returns (CarLib.Car[] memory) {
        CarLib.Car[] memory cars = new CarLib.Car[](_cars.length);
        uint8 index;
        for (uint8 i = 0; i < _cars.length; i++) {
            if (_cars[i].carId == _carId) {
                cars[_cars.length - 1] = _cars[i];
            } else {
                cars[index] = _cars[i];
                index++;
            }
        }
        return cars;
    }

    function applyHeuristics(uint8[8][8] memory _gameBoard, CarLib.Car[] memory _cars) internal pure returns (CarLib.Car[] memory) {
        for (uint8 i = 0; i < _cars.length; i++) {
            // Priority 3 (Low): Vertical Cars in the way...
            if (_cars[i].isVertical && _gameBoard[3][_cars[i].y] == _cars[i].carId) {
                _cars = sendToFront(_cars, _cars[i].carId);
            }
        }

        for (uint8 i = 0; i < _cars.length; i++) {
            // Priority 2 (Medium): Horizontal Cars that can move to the left
            if (_cars[i].isVertical == false && _cars[i].isMainCar == false)  {
                if (_gameBoard[_cars[i].x][_cars[i].y - 1] == 0) {
                    _cars = sendToFront(_cars, _cars[i].carId);
                } else {
                    _cars = sendToBack(_cars, _cars[i].carId);
                }
            }
        }

        // Priority 1 (High): Red car if it can move to the right
        if (
            (_gameBoard[3][2] == 1 && _gameBoard[3][3] == 0) ||
            (_gameBoard[3][3] == 1 && _gameBoard[3][4] == 0) ||
            (_gameBoard[3][4] == 1 && _gameBoard[3][5] == 0) ||
            (_gameBoard[3][5] == 1 && _gameBoard[3][6] == 0)
        ) {
            _cars = sendToFront(_cars, 1);
        } else {
            _cars = sendToBack(_cars, 1);
        }

        return _cars;
    }

    function countCars(uint8[6][6] memory _gameBoard) internal pure returns (uint8) {
        uint8 count = 0;
        uint8[16] memory carIds; // Array to store encountered vehicle IDs

        for (uint8 i = 0; i < 6; i++) {
            for (uint8 j = 0; j < 6; j++) {
                uint8 carId = _gameBoard[i][j];
                if (carId != 0 && carIds[carId] == 0) {
                    carIds[carId] = 1;
                    count++;
                }
            }
        }

        return count;
    }

    function hashBoard(uint8[8][8] memory _board) internal pure returns (bytes32) {
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

    function changeBoard(uint8[6][6] memory _board) internal pure returns (uint8[8][8] memory) {
        uint8[8][8] memory newBoard;
        for (uint8 i = 0; i < 8; i++) {
            for (uint8 j = 0; j < 8; j++) {
                if (i == 0 || j == 0 || i == 7 || j == 7) {
                    newBoard[i][j] = 99;
                } else {
                    newBoard[i][j] = _board[i - 1][j - 1];
                }
            }
        }
        return newBoard;
    }

    function append(Step[] memory _steps, Step memory _step) internal pure returns (Step[] memory) {
        Step[] memory newSteps = new Step[](_steps.length + 1);
        for (uint8 i = 0; i < _steps.length; i++) {
            newSteps[i] = _steps[i];
        }
        newSteps[_steps.length] = _step;
        return newSteps;
    }

    function pop(Step[] memory _steps) internal pure returns (Step[] memory) {
        Step[] memory newSteps = new Step[](_steps.length - 1);
        for (uint8 i = 0; i < _steps.length - 1; i++) {
            newSteps[i] = _steps[i];
        }
        return newSteps;
    }

    function appendVisited(bytes32[] memory _visited, bytes32 _hash) internal pure returns (bytes32[] memory) {
        bytes32[] memory newVisited = new bytes32[](_visited.length + 1);
        for (uint8 i = 0; i < _visited.length; i++) {
            newVisited[i] = _visited[i];
        }
        newVisited[_visited.length] = _hash;
        return newVisited;
    }

    function isVisited(bytes32[] memory _visited, bytes32 _hash) internal pure returns (bool) {
        for (uint8 i = 0; i < _visited.length; i++) {
            if (_visited[i] == _hash) {
                return true;
            }
        }

        return false;
    }
    
    function isSolved(uint8[8][8] memory _board) internal pure returns (bool) {
        return _board[3][6] == 1 && _board[3][5] == 1;
    }

    function logBoard(uint8[8][8] memory _board) internal pure {
        console.log("Board:");
        for (uint8 i = 0; i < 8; i++) {
            console.log(_board[i][0], _board[i][1], _board[i][2], _board[i][3]);
            console.log(_board[i][4], _board[i][5], _board[i][6], _board[i][7]);
        }
    }
}
