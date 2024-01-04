import 'package:flutter/material.dart';
import 'package:game/game.dart';

class GameState extends ChangeNotifier {
  GameWrapper gameWrapper = GameState.initialGame;

  void next(CardIndex cardIndex) {
    gameWrapper = gameWrapper.next(cardIndex);
    notifyListeners();
  }

  void reset() {
    gameWrapper = GameState.initialGame;
  }

  static final initialGame = AllFaceDownGameWrapper(AllFaceDownGame.random((
    Player.of('Player 1'),
    Player.of('Player 2'),
  )));
}

sealed class GameWrapper {
  Game get game;
  GameWrapper next(CardIndex cardIndex);
}

final class AllFaceDownGameWrapper extends GameWrapper {
  AllFaceDownGameWrapper(this.game);

  @override
  AllFaceDownGame game;

  @override
  GameWrapper next(CardIndex cardIndex) =>
      OneFaceUpGameWrapper(game.next(cardIndex));
}

final class OneFaceUpGameWrapper extends GameWrapper {
  OneFaceUpGameWrapper(this.game);

  @override
  OneFaceUpGame game;

  @override
  GameWrapper next(CardIndex cardIndex) =>
      TwoFaceUpGameWrapper(game.next(cardIndex));
}

final class TwoFaceUpGameWrapper extends GameWrapper {
  TwoFaceUpGameWrapper(this.game);

  @override
  TwoFaceUpGame game;

  @override
  GameWrapper next(CardIndex cardIndex) => AllFaceDownGameWrapper(game.next());
}
