// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRushHourSolver {
    enum MovementDirection {
        Up,
        Right,
        Down,
        Left
    }
    
    enum Direction { FORWARD, BACKWARD }

    struct Step {
        uint8 carId;
        Direction direction;
    }
    
    /**
    * @notice Get solution for a rush hour puzzle.
    * @dev Should return empty array if the board has no solution.
    * @param board The six-by-six Rush Hour board with 0s indicating empty
    * spaces, and other numbers indicating cars. The manner in which
    * numbers are aligned equals the alignment of the cars.
    * @return An array with step-by-step instructions on how to get the
    * red car (denoted by 1s) out.
    */
    function solve(uint8[6][6] memory board) external view returns (Step[] memory);
}
