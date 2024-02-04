import 'dart:math';

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
    final previousGame = gameState.previousGameWrapper?.game;

    final result = game.players.$1.score > game.players.$2.score
        ? '${game.players.$1.name} won!'
        : game.players.$1.score < game.players.$2.score
            ? '${game.players.$2.name} won!'
            : 'Draw!';

    return Column(children: [
      Stack(
        alignment: Alignment.center,
        children: [
          Visibility(
            visible: !game.isFinished,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: BoardWidget(
              board: game.board,
              previousBoard: previousGame?.board,
              onTapCard: (cardIndex) => gameState.next(cardIndex),
            ),
          ),
          Visibility(
            visible: game.isFinished,
            child: Text(
              result,
              style: theme.textTheme.displaySmall!.copyWith(),
            ),
          ),
        ],
      ),
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
    required this.previousBoard,
    required this.onTapCard,
  });

  final Board board;
  final Board? previousBoard;
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
                      previousCard: previousBoard?.cards[index],
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

enum CardWidgetState {
  front,
  back,
  hidden;

  factory CardWidgetState.fromCard(Card? card) {
    if (card != null) {
      return card.mark != null ? CardWidgetState.front : CardWidgetState.back;
    } else {
      return CardWidgetState.hidden;
    }
  }
}

class CardWidget extends StatelessWidget {
  const CardWidget({
    super.key,
    required this.card,
    required this.previousCard,
    required this.onTap,
  });

  final Card? card;
  final Card? previousCard;
  final void Function(Card card) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cardWidgetState = CardWidgetState.fromCard(card);
    final previousCardWidgetState = CardWidgetState.fromCard(previousCard);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        child: cardWidgetState == CardWidgetState.hidden ||
                previousCardWidgetState == CardWidgetState.hidden
            ? _buildFadeAnimation(theme, card)
            : _buildFlipAnimation(theme, card),
        onTap: () {
          final card = this.card;
          if (card != null) {
            onTap(card);
          }
        },
      ),
    );
  }

  static Widget _buildFadeAnimation(ThemeData theme, Card? card) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      child: _buildCard(theme, card),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
        /*
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, widget) {
            return Opacity(
              opacity: animation.value,
              child: child,
            );
          },
        );
        */
      },
    );
  }

  static Widget _buildFlipAnimation(ThemeData theme, Card? card) {
    final key = ValueKey(CardWidgetState.fromCard(card));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      //switchInCurve: Curves.easeInBack,
      //switchOutCurve: Curves.easeInBack.flipped,
      child: _buildCard(theme, card),
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(children: [currentChild!, ...previousChildren]);
      },
      transitionBuilder: (child, animation) {
        final rotationAnimation = Tween(
          begin: pi,
          end: 0.0,
        ).animate(animation);
        return AnimatedBuilder(
          animation: rotationAnimation,
          child: child,
          builder: (context, widget) {
            final back = key != widget?.key;
            final value = min(rotationAnimation.value, pi / 2);
            final tilt = (((animation.value - 0.5).abs() - 0.5) * 0.01) *
                (back ? -1 : 1);
            return Transform(
              transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
              alignment: Alignment.center,
              child: widget,
            );
          },
        );
      },
    );
  }

  static Widget _buildCard(ThemeData theme, Card? card) {
    final mark = card?.mark;
    final key = ValueKey(CardWidgetState.fromCard(card));

    return Container(
      key: key,
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
