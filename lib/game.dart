import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

sealed class Game extends Equatable {
  Game._(
    this.board,
    this.players,
    this.currentPlayer,
  ) {
    assert(currentPlayer == players.$1 || currentPlayer == players.$2);
  }

  final Board board;
  final Players players;
  final Player currentPlayer;

  bool get isFinished => board.isEmpty;

  @override
  List<Object?> get props => [board, players, currentPlayer];
}

final class AllFaceDownGame extends Game {
  AllFaceDownGame._(
    Board board,
    Players players,
    Player currentPlayer,
  ) : super._(
          board,
          players,
          currentPlayer,
        ) {
    assert(board.upCards.isEmpty);
  }

  OneFaceUpGame next(CardIndex index) {
    final card = board.cards[index];
    if (card == null) {
      throw ArgumentError('There is no card at $index');
    }

    return OneFaceUpGame._(
        board.flipCardToFaceUp(index), players, currentPlayer);
  }

  factory AllFaceDownGame.random(Players players) {
    final board = Board.random();
    return AllFaceDownGame.fromBoard(board, players);
  }

  factory AllFaceDownGame.fromBoard(Board board, Players players) {
    return AllFaceDownGame._(board, players, players.$1);
  }
}

final class OneFaceUpGame extends Game {
  OneFaceUpGame._(
    Board board,
    Players players,
    Player currentPlayer,
  ) : super._(
          board,
          players,
          currentPlayer,
        ) {
    assert(board.upCards.length == 1);
  }

  TwoFaceUpGame next(CardIndex index) {
    final card = board.cards[index];
    if (card == null) {
      throw ArgumentError('There is no card at $index');
    } else if (card.mark != null) {
      throw ArgumentError('The card at $index is already up');
    }

    return TwoFaceUpGame._(
        board.flipCardToFaceUp(index), players, currentPlayer);
  }
}

final class TwoFaceUpGame extends Game {
  TwoFaceUpGame._(
    Board board,
    Players players,
    Player currentPlayer,
  ) : super._(
          board,
          players,
          currentPlayer,
        ) {
    assert(board.upCards.length == 2);
  }

  AllFaceDownGame next() {
    final upCards = board.upCards;
    assert(upCards.length == 2);

    if (upCards[0].mark == upCards[1].mark) {
      final mark = upCards[0].mark!;
      final newPlayers = (() {
        if (currentPlayer == players.$1) {
          return (players.$1.addMark(mark), players.$2);
        } else {
          return (players.$1, players.$2.addMark(mark));
        }
      })();

      return AllFaceDownGame._(
        board.removeCards(mark),
        newPlayers,
        currentPlayer == players.$1 ? newPlayers.$1 : newPlayers.$2,
      );
    } else {
      return AllFaceDownGame._(
        board.flipAllCardsToFaceDown(),
        players,
        currentPlayer == players.$1 ? players.$2 : players.$1,
      );
    }
  }
}

final class Board extends Equatable {
  Board._(this.cards) {
    assert(cards.length == 16);
  }

  final List<Card?> cards;

  bool get isEmpty {
    return cards.every((card) => card == null);
  }

  List<FaceUpCard> get upCards => cards
      .where((card) => card?.mark != null)
      .map((card) => card as FaceUpCard)
      .toList();

  Board flipCardToFaceUp(CardIndex index) {
    if (this.cards[index] == null) {
      throw ArgumentError('There is no card at $index');
    } else if (this.cards[index]?.mark != null) {
      throw ArgumentError('The card at $index is already up');
    }

    final cards = this.cards.asMap().entries.map((entry) {
      if (entry.key == index) {
        return entry.value!.flip();
      } else {
        return entry.value;
      }
    }).toList();

    return Board._(cards);
  }

  Board flipAllCardsToFaceDown() {
    final cards = this.cards.map((card) => card?.down()).toList();
    return Board._(cards);
  }

  Board removeCards(Mark mark) {
    assert(upCards.length == 2);

    return Board._(
      cards
          .map((card) => card == null || card.mark == mark ? null : card)
          .toList(),
    );
  }

  factory Board.random() {
    final cards = Mark.values
        .map((mark) => [mark, mark])
        .flattened
        .map((mark) => FaceDownCard(mark))
        .toList(growable: false);
    cards.shuffle();
    return Board.fromCards(cards);
  }

  factory Board.fromCards(List<FaceDownCard> cards) {
    return Board._(List.unmodifiable(cards.toList(growable: false)));
  }

  @override
  List<Object> get props => [cards];
}

typedef CardIndex = int;

sealed class Card extends Equatable {
  const Card(this._mark);

  Mark? get mark;

  Card flip();
  FaceDownCard down();

  @override
  List<Object> get props => [_mark];

  final Mark _mark;
}

final class FaceUpCard extends Card {
  const FaceUpCard(super.mark);

  @override
  Mark? get mark {
    return _mark;
  }

  @override
  Card flip() => FaceDownCard(_mark);

  @override
  FaceDownCard down() => FaceDownCard(_mark);
}

final class FaceDownCard extends Card {
  const FaceDownCard(super.mark);

  @override
  Mark? get mark {
    return null;
  }

  @override
  Card flip() => FaceUpCard(_mark);

  @override
  FaceDownCard down() => this;
}

enum Mark {
  a('A'),
  b('B'),
  c('C'),
  d('D'),
  e('E'),
  f('F'),
  g('G'),
  h('H');

  const Mark(this.name);

  final String name;
}

final class Player extends Equatable {
  const Player(this.name, this.marks);

  int get score {
    return marks.length;
  }

  Player addMark(Mark mark) {
    return Player(name, {...marks, mark});
  }

  factory Player.of(String name) {
    return Player(name, const {});
  }

  @override
  List<Object> get props => [name, marks];

  final String name;
  final Set<Mark> marks;
}

typedef Players = (Player, Player);
