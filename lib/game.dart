import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

sealed class Game extends Equatable {
  const Game._(
    this.board,
    this.players,
    this.currentPlayer,
  );

  final Board board;
  final Players players;
  final Player currentPlayer;

  bool get isFinished {
    return board.isEmpty;
  }

  Card? get transientCard;

  Game next(CardIndex index);

  factory Game.random(Players players) {
    final board = Board.random();
    return Game.fromBoard(board, players);
  }

  factory Game.fromBoard(Board board, Players players) {
    return _PerennialGame(board, players, players.$1);
  }

  @override
  List<Object?> get props => [board, players, currentPlayer, transientCard];
}

final class _PerennialGame extends Game {
  const _PerennialGame(
    Board board,
    Players players,
    Player currentPlayer,
  ) : super._(
          board,
          players,
          currentPlayer,
        );

  @override
  Card? get transientCard {
    return null;
  }

  @override
  Game next(CardIndex index) {
    final card = board.cards[index];
    if (card == null) {
      throw ArgumentError('There is no card at $index');
    }

    return _TransientGame(
      board,
      players,
      currentPlayer,
      card,
    );
  }
}

final class _TransientGame extends Game {
  const _TransientGame(
    Board board,
    Players players,
    Player currentPlayer,
    this.transientCard,
  ) : super._(
          board,
          players,
          currentPlayer,
        );

  @override
  Game next(CardIndex index) {
    final card = board.cards[index];
    if (card == null) {
      throw ArgumentError('There is no card at $index');
    }

    if (card.mark == transientCard.mark) {
      final newPlayers = (() {
        if (currentPlayer == players.$1) {
          return (players.$1.addMark(card.mark), players.$2);
        } else {
          return (players.$1, players.$2.addMark(card.mark));
        }
      })();

      return _PerennialGame(
        board.removeCards(card.mark),
        newPlayers,
        currentPlayer,
      );
    } else {
      return _PerennialGame(
        board,
        players,
        currentPlayer == players.$1 ? players.$2 : players.$1,
      );
    }
  }

  @override
  final Card transientCard;
}

final class Board extends Equatable {
  Board._(this.cards) {
    assert(cards.length == 16);
  }

  final List<Card?> cards;

  bool get isEmpty {
    return cards.every((card) => card == null);
  }

  Board removeCards(Mark mark) {
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
        .map((mark) => Card(mark))
        .toList(growable: false);
    cards.shuffle();
    return Board.fromCards(cards);
  }

  factory Board.fromCards(List<Card?> cards) {
    return Board._(List.unmodifiable(cards.toList(growable: false)));
  }

  @override
  List<Object> get props => [cards];
}

typedef CardIndex = int;

final class Card extends Equatable {
  const Card(this.mark);

  final Mark mark;

  @override
  List<Object> get props => [mark];
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
