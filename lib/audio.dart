import 'package:just_audio/just_audio.dart';

class Audio {
  static AudioPlayer audioPlayer = AudioPlayer();

  static void playMove() {
    audioPlayer.setAsset('assets/sounds/move.wav');
    audioPlayer.play();
  }

  static void playKill() {
    audioPlayer.setAsset('assets/sounds/laugh.mp3');
    audioPlayer.play();
  }

  static void rollDice() {
    audioPlayer.setAsset('assets/sounds/roll_the_dice.mp3');
    audioPlayer.play();
  }
}
