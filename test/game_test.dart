import 'package:collection/collection.dart';
import 'package:game/game.dart';
import 'package:test/test.dart';

void main() {
  group('Game', () {
    late Players players;

    setUp(() {
      players = (Player.of('Player 1'), Player.of('Player 2'));
    });

    test('should create a random game', () {
      final game = AllFaceDownGame.random(players);

      expect(game.board.cards.length, 16);
      expect(game.players, players);
      expect(game.currentPlayer, players.$1);
      expect(game.isFinished, false);
    });

    group('next', () {
      late AllFaceDownGame game;

      setUp(() {
        final cards = Mark.values
            .map((mark) => [mark, mark])
            .flattened
            .map((mark) => FaceDownCard(mark))
            .toList();
        game = AllFaceDownGame.fromBoard(Board.fromCards(cards), players);
      });

      test('should return OneFaceUpGame', () {
        final nextGame = game.next(0);
        expect(nextGame.board.upCards.length, 1);
        expect(nextGame.currentPlayer.name, 'Player 1');
      });

      test('should return TwoFaceUpGame', () {
        final nextGame = game.next(0).next(1);
        expect(nextGame.board.upCards.length, 2);
        expect(nextGame.currentPlayer.name, 'Player 1');
      });

      test('should remove cards and update score', () {
        final nextGame = game.next(0).next(1).next();
        expect(nextGame.board.cards[0], null);
        expect(nextGame.board.cards[1], null);
        expect(nextGame.board.cards.nonNulls.length, 14);
        expect(nextGame.players.$1.name, 'Player 1');
        expect(nextGame.players.$1.score, 1);
        expect(nextGame.players.$2.name, 'Player 2');
        expect(nextGame.players.$2.score, 0);
        expect(nextGame.currentPlayer.name, 'Player 1');
      });

      test('should not remove cards and change current player', () {
        final nextGame = game.next(0).next(2).next();
        expect(nextGame.board.cards.nonNulls.length, 16);
        expect(nextGame.players.$1.name, 'Player 1');
        expect(nextGame.players.$1.score, 0);
        expect(nextGame.players.$2.name, 'Player 2');
        expect(nextGame.players.$2.score, 0);
        expect(nextGame.currentPlayer.name, 'Player 2');
      });

      test('should continue to finish', () {
        final lastGame = Iterable<CardIndex>.generate(8).fold(
          game,
          (previousGame, cardIndex) =>
              previousGame.next(cardIndex * 2).next(cardIndex * 2 + 1).next(),
        );
        expect(lastGame.isFinished, true);
      });
    });
  });

  group('Board', () {
    late List<FaceDownCard> cards;
    late Board board;

    setUp(() {
      cards = Mark.values
          .map((mark) => [mark, mark])
          .flattened
          .map((mark) => FaceDownCard(mark))
          .toList();
      board = Board.fromCards(cards);
    });

    test('should return if it is empty', () {
      expect(board.isEmpty, false);

      final emptyBoard = Mark.values.asMap().entries.fold(
        board,
        (previousBoard, entry) {
          final MapEntry(key: index, value: mark) = entry;
          return previousBoard
              .flipCardToFaceUp(index * 2)
              .flipCardToFaceUp(index * 2 + 1)
              .removeCards(mark);
        },
      );
      expect(emptyBoard.isEmpty, true);
    });

    test('should remove cards', () {
      expect(
        board.flipCardToFaceUp(0).flipCardToFaceUp(1).removeCards(Mark.a).cards,
        [
          null,
          null,
          ...cards.skip(2),
        ],
      );
    });

    test('should equal', () {
      expect(board, equals(Board.fromCards(cards)));
    });

    test('should not equal', () {
      expect(
          board,
          isNot(equals(board
              .flipCardToFaceUp(0)
              .flipCardToFaceUp(1)
              .removeCards(Mark.a))));
    });
  });

  group('Card', () {
    test('should equal', () {
      expect(const FaceUpCard(Mark.a), equals(const FaceUpCard(Mark.a)));
      expect(const FaceDownCard(Mark.a), equals(const FaceDownCard(Mark.a)));
    });

    test('should not equal', () {
      expect(const FaceUpCard(Mark.a), isNot(equals(const FaceUpCard(Mark.b))));
      expect(const FaceDownCard(Mark.a),
          isNot(equals(const FaceDownCard(Mark.b))));
    });
  });

  group('Player', () {
    test('should return score', () {
      expect(Player.of('Player 1').score, 0);
      expect(const Player('Player 1', {Mark.a, Mark.b}).score, 2);
    });

    test('should add a mark', () {
      expect(
        const Player('Player1', {Mark.a}).addMark(Mark.b).marks,
        {Mark.a, Mark.b},
      );
      expect(
        const Player('Player1', {Mark.a}).addMark(Mark.a).marks,
        {Mark.a},
      );
    });

    test('should equal', () {
      expect(Player.of('Player 1'), equals(Player.of('Player 1')));
    });

    test('should not equal', () {
      expect(Player.of('Player 1'), isNot(equals(Player.of('Player 2'))));
    });
  });
}
