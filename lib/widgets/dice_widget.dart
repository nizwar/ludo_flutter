import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ludo_flutter/constants.dart';
import 'package:ludo_flutter/ludo_provider.dart';
import 'package:provider/provider.dart';
import 'package:simple_ripple_animation/simple_ripple_animation.dart';

///Widget for the dice
class DiceWidget extends StatelessWidget {
  const DiceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LudoProvider>(
      builder: (context, value, child) => RippleAnimation(
        color: value.gameState == LudoGameState.throwDice ? value.currentPlayer.color : Colors.white.withOpacity(0),
        ripplesCount: 3,
        minRadius: 30,
        repeat: true,
        child: CupertinoButton(
          onPressed: value.throwDice,
          padding: const EdgeInsets.only(),
          child: value.diceStarted ? Image.asset("assets/images/dice/draw.gif", fit: BoxFit.contain) : Image.asset("assets/images/dice/${value.diceResult}.png", fit: BoxFit.contain),
        ),
      ),
    );
  }
}
