import 'package:equatable/equatable.dart';

class RevealState extends Equatable {
  const RevealState({
    this.currentIndex = 0,
    this.isRevealed = false,
    this.isFinished = false,
  });

  final int currentIndex;
  final bool isRevealed;
  final bool isFinished;

  @override
  List<Object> get props => [currentIndex, isRevealed, isFinished];
}
