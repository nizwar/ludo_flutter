import 'dart:math';

///Rolls the dice and keeps track of the sixes rolled in a row
class Dice {
  Dice([Random? random]) : _random = random ?? Random();

  final Random _random;
  int _sixesInARow = 0;

  ///Rolls a number from 1 to 6, all equally likely
  int roll() {
    final result = _random.nextInt(6) + 1;
    _sixesInARow = result == 6 ? _sixesInARow + 1 : 0;
    return result;
  }

  ///Three sixes in a row forfeit the turn
  bool get forfeitsTurn => _sixesInARow >= 3;

  ///Call when the turn passes to the next player
  void reset() => _sixesInARow = 0;
}
