import 'package:equatable/equatable.dart';
import '../../domain/entities/book.dart';

abstract class ReaderState extends Equatable {
  const ReaderState();

  @override
  List<Object?> get props => [];
}

class ReaderInitial extends ReaderState {}

class ReaderLoading extends ReaderState {}

class ReaderError extends ReaderState {
  final String message;

  const ReaderError(this.message);

  @override
  List<Object?> get props => [message];
}

class ReaderLoaded extends ReaderState {
  final Book book;
  final int currentPage;
  final int totalPages;
  final String currentPageContent;
  final double fontSize;
  final bool isSpeaking;
  final bool isPaused;
  final double speechRate;
  final double pitch;
  final String selectedVoice;
  final List<String> availableVoices;

  const ReaderLoaded({
    required this.book,
    required this.currentPage,
    required this.totalPages,
    required this.currentPageContent,
    required this.fontSize,
    required this.isSpeaking,
    required this.isPaused,
    required this.speechRate,
    required this.pitch,
    required this.selectedVoice,
    required this.availableVoices,
  });

  ReaderLoaded copyWith({
    Book? book,
    int? currentPage,
    int? totalPages,
    String? currentPageContent,
    double? fontSize,
    bool? isSpeaking,
    bool? isPaused,
    double? speechRate,
    double? pitch,
    String? selectedVoice,
    List<String>? availableVoices,
  }) {
    return ReaderLoaded(
      book: book ?? this.book,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      currentPageContent: currentPageContent ?? this.currentPageContent,
      fontSize: fontSize ?? this.fontSize,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isPaused: isPaused ?? this.isPaused,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      selectedVoice: selectedVoice ?? this.selectedVoice,
      availableVoices: availableVoices ?? this.availableVoices,
    );
  }

  @override
  List<Object?> get props => [
        book,
        currentPage,
        totalPages,
        currentPageContent,
        fontSize,
        isSpeaking,
        isPaused,
        speechRate,
        pitch,
        selectedVoice,
        availableVoices,
      ];
}
