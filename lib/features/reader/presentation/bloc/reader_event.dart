import 'package:equatable/equatable.dart';

abstract class ReaderEvent extends Equatable {
  const ReaderEvent();

  @override
  List<Object?> get props => [];
}

class LoadBook extends ReaderEvent {
  final String bookId;

  const LoadBook(this.bookId);

  @override
  List<Object?> get props => [bookId];
}

class NextPage extends ReaderEvent {}

class PreviousPage extends ReaderEvent {}

class GoToPage extends ReaderEvent {
  final int page;

  const GoToPage(this.page);

  @override
  List<Object?> get props => [page];
}

class TogglePlayPause extends ReaderEvent {}

class StopSpeech extends ReaderEvent {}

class UpdateSpeechRate extends ReaderEvent {
  final double rate;

  const UpdateSpeechRate(this.rate);

  @override
  List<Object?> get props => [rate];
}

class UpdateFontSize extends ReaderEvent {
  final double size;

  const UpdateFontSize(this.size);

  @override
  List<Object?> get props => [size];
} 