import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game/game.dart';

class GameState extends ChangeNotifier {
  GameWrapper gameWrapper = initialGame;

  void next(CardIndex cardIndex) {
    if (_autoNextTimer != null) {
      return;
    }

    gameWrapper = gameWrapper.next(cardIndex);

    if (gameWrapper.autoNext) {
      _autoNextTimer = Timer(
        const Duration(milliseconds: autoNextDelay),
        () {
          _autoNextTimer = null;
          next(cardIndex);
        },
      );
    }

    notifyListeners();
  }

  void reset() {
    gameWrapper = initialGame;

    _autoNextTimer?.cancel();
    _autoNextTimer = null;

    notifyListeners();
  }

  Timer? _autoNextTimer;

  static final initialGame = AllFaceDownGameWrapper(AllFaceDownGame.random((
    Player.of('Player 1'),
    Player.of('Player 2'),
  )));

  static const autoNextDelay = 500;
}

sealed class GameWrapper {
  Game get game;
  GameWrapper next(CardIndex cardIndex);
  bool get autoNext => false;
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

  @override
  bool get autoNext => true;
}
