import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_flutter/dice.dart';

///Returns the given values from nextInt, one after another
class _FixedRandom implements Random {
  _FixedRandom(this.values);

  final List<int> values;
  int _index = 0;

  @override
  int nextInt(int max) => values[_index++];

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  double nextDouble() => throw UnimplementedError();
}

void main() {
  test('every number from 1 to 6 comes up about as often', () {
    final dice = Dice(Random(1));
    final counts = List.filled(7, 0);
    for (var i = 0; i < 60000; i++) {
      counts[dice.roll()]++;
    }
    expect(counts[0], 0);
    for (var face = 1; face <= 6; face++) {
      expect(counts[face], inInclusiveRange(9500, 10500), reason: 'face $face');
    }
  });

  test('the third six in a row forfeits the turn', () {
    final dice = Dice(_FixedRandom([5, 5, 5]));
    expect(dice.roll(), 6);
    expect(dice.forfeitsTurn, isFalse);
    expect(dice.roll(), 6);
    expect(dice.forfeitsTurn, isFalse);
    expect(dice.roll(), 6);
    expect(dice.forfeitsTurn, isTrue);
  });

  test('any other number breaks the streak', () {
    final dice = Dice(_FixedRandom([5, 5, 2, 5, 5]));
    expect([dice.roll(), dice.roll(), dice.roll()], [6, 6, 3]);
    expect(dice.forfeitsTurn, isFalse);
    expect([dice.roll(), dice.roll()], [6, 6]);
    expect(dice.forfeitsTurn, isFalse);
  });

  test('the next player starts a new streak', () {
    final dice = Dice(_FixedRandom([5, 5, 5]));
    dice.roll();
    dice.roll();
    dice.reset();
    dice.roll();
    expect(dice.forfeitsTurn, isFalse);
  });
}
