import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

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

class UpdateSpeechRate extends ReaderEvent {
  final double rate;

  const UpdateSpeechRate(this.rate);

  @override
  List<Object?> get props => [rate];
}

class UpdatePitch extends ReaderEvent {
  final double pitch;

  const UpdatePitch(this.pitch);

  @override
  List<Object?> get props => [pitch];
}

class UpdateVoice extends ReaderEvent {
  final String voice;

  const UpdateVoice(this.voice);

  @override
  List<Object?> get props => [voice];
}

class UpdateFontSize extends ReaderEvent {
  final double size;

  const UpdateFontSize(this.size);

  @override
  List<Object?> get props => [size];
}

class UpdateTheme extends ReaderEvent {
  final ThemeMode theme;

  const UpdateTheme(this.theme);

  @override
  List<Object?> get props => [theme];
}

class AddToFavorites extends ReaderEvent {
  final String word;

  const AddToFavorites(this.word);

  @override
  List<Object?> get props => [word];
}
