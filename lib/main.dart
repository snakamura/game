import 'package:flutter/material.dart' hide Card;
import 'package:provider/provider.dart';

import 'game.dart';
import 'state.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => GameState(),
        child: const MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 20),
                  GameWidget(),
                ],
              ),
            ),
          ),
        ));
  }
}

class GameWidget extends StatelessWidget {
  const GameWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final gameState = context.watch<GameState>();
    final game = gameState.gameWrapper.game;

    final result = game.players.$1.score > game.players.$2.score
        ? '${game.players.$1.name} won!'
        : game.players.$1.score < game.players.$2.score
            ? '${game.players.$2.name} won!'
            : 'Draw!';

    return Column(children: [
      Stack(children: [
        Visibility(
          visible: !game.isFinished,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: BoardWidget(
            board: game.board,
            onTapCard: (cardIndex) => gameState.next(cardIndex),
          ),
        ),
        Visibility(
          visible: game.isFinished,
          child: Positioned.fill(
            child: Center(
              child: Text(
                result,
                style: theme.textTheme.displaySmall!.copyWith(),
              ),
            ),
          ),
        ),
      ]),
      Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PlayerWidget(
              player: game.players.$1,
              isCurrentPlayer: game.currentPlayer == game.players.$1,
            ),
            const SizedBox(width: 15),
            PlayerWidget(
              player: game.players.$2,
              isCurrentPlayer: game.currentPlayer == game.players.$2,
            ),
          ],
        ),
      ),
      ElevatedButton(
        onPressed: () {
          gameState.reset();
        },
        child: const Text('Reset'),
      )
    ]);
  }
}

class BoardWidget extends StatelessWidget {
  const BoardWidget({
    super.key,
    required this.board,
    required this.onTapCard,
  });

  final Board board;
  final void Function(CardIndex index) onTapCard;

  @override
  Widget build(BuildContext context) {
    return Column(
        children: Iterable<CardIndex>.generate(4)
            .map((column) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: Iterable<CardIndex>.generate(4).map(
                  (row) {
                    final index = column * 4 + row;
                    return CardWidget(
                      card: board.cards[index],
                      onTap: (card) {
                        if (card.mark == null) {
                          onTapCard(index);
                        }
                      },
                    );
                  },
                ).toList()))
            .toList());
  }
}

class CardWidget extends StatelessWidget {
  const CardWidget({
    super.key,
    required this.card,
    required this.onTap,
  });

  final Card? card;
  final void Function(Card card) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final mark = card?.mark;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        child: Container(
          width: 75,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            color: card != null
                ? mark != null
                    ? Colors.deepOrange
                    : Colors.grey
                : Colors.transparent,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Text(mark?.name ?? '',
                  style: theme.textTheme.displayLarge!.copyWith(
                      color: mark != null ? Colors.white : Colors.transparent)),
            ),
          ),
        ),
        onTap: () {
          final card = this.card;
          if (card != null) {
            onTap(card);
          }
        },
      ),
    );
  }
}

class PlayerWidget extends StatelessWidget {
  const PlayerWidget({
    super.key,
    required this.player,
    required this.isCurrentPlayer,
  });

  final Player player;
  final bool isCurrentPlayer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: isCurrentPlayer
          ? theme.colorScheme.primary
          : theme.colorScheme.secondary,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 40,
          vertical: 10,
        ),
        child: Column(
          children: [
            Text(
              player.name,
              style: theme.textTheme.labelLarge!.copyWith(
                  color: isCurrentPlayer
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSecondary),
            ),
            Text(
              player.score.toString(),
              style: theme.textTheme.displaySmall!.copyWith(
                  color: isCurrentPlayer
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSecondary),
            )
          ],
        ),
      ),
    );
  }
}
