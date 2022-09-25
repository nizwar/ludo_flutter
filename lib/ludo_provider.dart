import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ludo_flutter/ludo_player.dart';

import 'audio.dart';
import 'constants.dart';

class LudoProvider extends ChangeNotifier {
  ///Flags to check if pawn is moving
  bool _isMoving = false;

  ///Flags to stop pawn once disposed
  bool _stopMoving = false;

  LudoGameState _gameState = LudoGameState.throwDice;

  ///Game state to check if the game is in throw dice state or pick pawn state
  LudoGameState get gameState => _gameState;

  LudoPlayerType _currentTurn = LudoPlayerType.green;

  int _diceResult = 0;

  ///Dice result to check the dice result of the current turn
  int get diceResult {
    if (_diceResult < 1) {
      return 1;
    } else {
      if (_diceResult > 6) {
        return 6;
      } else {
        return _diceResult;
      }
    }
  }

  bool _diceStarted = false;
  bool get diceStarted => _diceStarted;

  LudoPlayer get currentPlayer => players.firstWhere((element) => element.type == _currentTurn);

  ///Fill all players
  final List<LudoPlayer> players = [
    LudoPlayer(LudoPlayerType.green),
    LudoPlayer(LudoPlayerType.yellow),
    LudoPlayer(LudoPlayerType.blue),
    LudoPlayer(LudoPlayerType.red),
  ];

  ///Player win, we use `LudoPlayerType` to make it easier to check
  final List<LudoPlayerType> winners = [];

  LudoPlayer player(LudoPlayerType type) => players.firstWhere((element) => element.type == type);

  ///This is the function that will be called to throw the dice
  void throwDice() async {
    if (_gameState != LudoGameState.throwDice) return;
    _diceStarted = true;
    notifyListeners();
    Audio.rollDice();

    //Check if already win skip
    if (winners.contains(currentPlayer.type)) {
      nextTurn();
      return;
    }

    //Turn off highlight for all pawns
    currentPlayer.highlightAllPawns(false);

    Future.delayed(const Duration(seconds: 1)).then((value) {
      _diceStarted = false;
      var random = Random();
      _diceResult = random.nextBool() ? 6 : random.nextInt(6) + 1; //Random between 1 - 6
      notifyListeners();

      if (diceResult == 6) {
        currentPlayer.highlightAllPawns();
        _gameState = LudoGameState.pickPawn;
        notifyListeners();
      } else {
        /// all pawns are inside home
        if (currentPlayer.pawnInsideCount == 4) {
          return nextTurn();
        } else {
          ///Hightlight all pawn outside
          currentPlayer.highlightOutside();
          _gameState = LudoGameState.pickPawn;
          notifyListeners();
        }
      }

      ///Check and disable if any pawn already in the finish box
      for (var i = 0; i < currentPlayer.pawns.length; i++) {
        var pawn = currentPlayer.pawns[i];
        if ((pawn.step + diceResult) > currentPlayer.path.length - 1) {
          currentPlayer.highlightPawn(i, false);
        }
      }

      ///Automatically move random pawn if all pawn are in same step
      var moveablePawn = currentPlayer.pawns.where((e) => e.highlight).toList();
      if (moveablePawn.length > 1) {
        var biggestStep = moveablePawn.map((e) => e.step).reduce(max);
        if (moveablePawn.every((element) => element.step == biggestStep)) {
          var random = 1 + Random().nextInt(moveablePawn.length - 1);
          if (moveablePawn[random].step == -1) {
            var thePawn = moveablePawn[random];
            move(thePawn.type, thePawn.index, (thePawn.step + 1) + 1);
            return;
          } else {
            var thePawn = moveablePawn[random];
            move(thePawn.type, thePawn.index, (thePawn.step + 1) + diceResult);
            return;
          }
        }
      }

      ///If User have 6 dice, but it inside finish line, it will make him to throw again, else it will turn to next player
      if (currentPlayer.pawns.every((element) => !element.highlight)) {
        if (diceResult == 6) {
          _gameState = LudoGameState.throwDice;
        } else {
          nextTurn();
          return;
        }
      }

      if (currentPlayer.pawns.where((element) => element.highlight).length == 1) {
        var index = currentPlayer.pawns.indexWhere((element) => element.highlight);
        move(currentPlayer.type, index, (currentPlayer.pawns[index].step + 1) + diceResult);
      }
    });
  }

  ///Move pawn to next step and check if it can kill other pawn
  void move(LudoPlayerType type, int index, int step) async {
    if (_isMoving) return;
    _isMoving = true;
    _gameState = LudoGameState.moving;

    currentPlayer.highlightAllPawns(false);

    // int delay = 500;
    var selectedPlayer = player(type);
    for (int i = selectedPlayer.pawns[index].step; i < step; i++) {
      if (_stopMoving) break;
      if (selectedPlayer.pawns[index].step == i) continue;
      selectedPlayer.movePawn(index, i);
      await Audio.playMove();
      notifyListeners();
      if (_stopMoving) break;
    }
    if (checkToKill(type, index, step, selectedPlayer.path)) {
      _gameState = LudoGameState.throwDice;
      _isMoving = false;
      Audio.playKill();
      notifyListeners();
      return;
    }

    validateWin(type);

    if (diceResult == 6) {
      _gameState = LudoGameState.throwDice;
      notifyListeners();
    } else {
      nextTurn();
      notifyListeners();
    }
    _isMoving = false;
  }

  ///Next turn will be called when the player finish the turn
  void nextTurn() {
    switch (_currentTurn) {
      case LudoPlayerType.green:
        _currentTurn = LudoPlayerType.yellow;
        break;
      case LudoPlayerType.yellow:
        _currentTurn = LudoPlayerType.blue;
        break;
      case LudoPlayerType.blue:
        _currentTurn = LudoPlayerType.red;
        break;
      case LudoPlayerType.red:
        _currentTurn = LudoPlayerType.green;
        break;
    }

    if (winners.contains(_currentTurn)) return nextTurn();
    _gameState = LudoGameState.throwDice;
    notifyListeners();
  }

  ///This method will check if the pawn can kill another pawn or not by checking the step of the pawn
  bool checkToKill(LudoPlayerType type, int index, int step, List<List<double>> path) {
    bool killSomeone = false;
    for (int i = 0; i < 4; i++) {
      var greenElement = player(LudoPlayerType.green).pawns[i];
      var blueElement = player(LudoPlayerType.blue).pawns[i];
      var redElement = player(LudoPlayerType.red).pawns[i];
      var yellowElement = player(LudoPlayerType.yellow).pawns[i];

      if ((greenElement.step > -1 && !LudoPath.safeArea.map((e) => e.toString()).contains(player(LudoPlayerType.green).path[greenElement.step].toString())) && type != LudoPlayerType.green) {
        if (player(LudoPlayerType.green).path[greenElement.step].toString() == path[step - 1].toString()) {
          killSomeone = true;
          player(LudoPlayerType.green).movePawn(i, -1);
          notifyListeners();
        }
      }
      if ((yellowElement.step > -1 && !LudoPath.safeArea.map((e) => e.toString()).contains(player(LudoPlayerType.yellow).path[yellowElement.step].toString())) && type != LudoPlayerType.yellow) {
        if (player(LudoPlayerType.yellow).path[yellowElement.step].toString() == path[step - 1].toString()) {
          killSomeone = true;
          player(LudoPlayerType.yellow).movePawn(i, -1);
          notifyListeners();
        }
      }
      if ((blueElement.step > -1 && !LudoPath.safeArea.map((e) => e.toString()).contains(player(LudoPlayerType.blue).path[blueElement.step].toString())) && type != LudoPlayerType.blue) {
        if (player(LudoPlayerType.blue).path[blueElement.step].toString() == path[step - 1].toString()) {
          killSomeone = true;
          player(LudoPlayerType.blue).movePawn(i, -1);
          notifyListeners();
        }
      }
      if ((redElement.step > -1 && !LudoPath.safeArea.map((e) => e.toString()).contains(player(LudoPlayerType.red).path[redElement.step].toString())) && type != LudoPlayerType.red) {
        if (player(LudoPlayerType.red).path[redElement.step].toString() == path[step - 1].toString()) {
          killSomeone = true;
          player(LudoPlayerType.red).movePawn(i, -1);
          notifyListeners();
        }
      }
    }
    return killSomeone;
  }

  ///This function will check if the pawn finish the game or not
  void validateWin(LudoPlayerType color) {
    if (winners.map((e) => e.name).contains(color.name)) return;
    if (player(color).pawns.map((e) => e.step).every((element) => element == player(color).path.length - 1)) {
      winners.add(color);
      notifyListeners();
    }

    if (winners.length == 3) {
      _gameState = LudoGameState.finish;
    }
  }

  @override
  void dispose() {
    _stopMoving = true;
    super.dispose();
  }
}
