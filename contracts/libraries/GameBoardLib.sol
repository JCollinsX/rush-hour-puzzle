// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

library GameBoardLib {
    struct GameBoard {
        uint8[6][6] board;
    }

    function isSolved(GameBoard memory _gameBoard) internal pure returns (bool) {
        return _gameBoard.board[2][5] == 1;
    }

    function setBoard(GameBoard memory _gameBoard, uint8[6][6] memory _board) internal pure {
        _gameBoard.board = _board;
    }

    function getStates(GameBoard memory _gameBoard) internal pure returns (uint8[6][6] memory) {
        return _gameBoard.board;
    }
}
