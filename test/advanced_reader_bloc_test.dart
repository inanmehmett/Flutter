import 'package:bloc_test/bloc_test.dart';
import 'package:daily_english/features/reader/presentation/bloc/advanced_reader_bloc.dart';
import 'package:daily_english/features/reader/presentation/bloc/reader_event.dart';
import 'package:daily_english/features/reader/presentation/bloc/reader_state.dart';
import 'package:daily_english/features/reader/data/models/book_model.dart';
import 'package:daily_english/features/reader/domain/repositories/book_repository.dart';
import 'package:daily_english/core/di/injection.dart';
import 'package:daily_english/features/reader/data/services/translation_service.dart';
import 'package:daily_english/core/analytics/event_service.dart';
import 'package:daily_english/core/storage/last_read_manager.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBookRepository extends Mock implements BookRepository {}

class FakeUrlSource extends Fake implements UrlSource {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockFlutterTts extends Mock implements FlutterTts {}

class MockTranslationService extends Mock implements TranslationService {}

class MockEventService extends Mock implements EventService {}

class MockLastReadManager extends Mock implements LastReadManager {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUrlSource());
  });

  group('AdvancedReaderBloc media behavior', () {
    late MockBookRepository bookRepository;
    late MockFlutterTts flutterTts;
    late MockAudioPlayer audioPlayer;
    late MockTranslationService translationService;
    late MockEventService eventService;
    late MockLastReadManager lastReadManager;

    final book = BookModel(
      id: '1',
      title: 't',
      author: 'a',
      content: 'Hello world. This is a test.',
      textLanguage: 'en',
      translationLanguage: 'tr',
      estimatedReadingTimeInMinutes: 1,
      isActive: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    setUp(() {
      // Reset and register DI used indirectly in the bloc
      getIt.reset();
      translationService = MockTranslationService();
      eventService = MockEventService();
      lastReadManager = MockLastReadManager();
      getIt.registerLazySingleton<TranslationService>(() => translationService);
      getIt.registerLazySingleton<EventService>(() => eventService);
      getIt.registerLazySingleton<LastReadManager>(() => lastReadManager);

      bookRepository = MockBookRepository();
      flutterTts = MockFlutterTts();
      audioPlayer = MockAudioPlayer();

      when(() => flutterTts.setLanguage(any())).thenAnswer((_) async => 1);
      when(() => flutterTts.setSpeechRate(any())).thenAnswer((_) async => 1);
      when(() => flutterTts.setVolume(any())).thenAnswer((_) async => 1);
      when(() => flutterTts.stop()).thenAnswer((_) async => 1);
      when(() => flutterTts.speak(any())).thenAnswer((_) async => 1);

      when(() => audioPlayer.stop()).thenAnswer((_) async {});
      when(() => audioPlayer.pause()).thenAnswer((_) async {});
      when(() => audioPlayer.resume()).thenAnswer((_) async {});
      when(() => audioPlayer.setPlaybackRate(any())).thenAnswer((_) async {});
      when(() => audioPlayer.play(any())).thenAnswer((_) async {});
      when(() => audioPlayer.onPlayerComplete).thenAnswer((_) => Stream<void>.fromIterable([null]));
      when(() => audioPlayer.onPlayerStateChanged).thenAnswer((_) => const Stream<PlayerState>.empty());

      when(() => bookRepository.getBook(any())).thenAnswer((_) async => Right(book));
      when(() => translationService.getAudioManifest(any(), voiceId: any(named: 'voiceId'), sourceLang: any(named: 'sourceLang'), targetLang: any(named: 'targetLang')))
          .thenAnswer((_) async => [
                {
                  'index': 0,
                  'audioUrl': 'http://example.com/a.mp3',
                },
              ]);
      when(() => eventService.readingStarted(any())).thenAnswer((_) async {});
      when(() => eventService.readingActive(any(), any())).thenAnswer((_) async {});
      when(() => eventService.sentenceListened(any(), any(), any())).thenAnswer((_) async {});
      when(() => eventService.readingCompleted(any(), totalMs: any(named: 'totalMs'))).thenAnswer((_) async {});
      when(() => lastReadManager.saveLastRead(bookId: any(named: 'bookId'), pageIndex: any(named: 'pageIndex'))).thenAnswer((_) async {});
      when(() => lastReadManager.getLastRead()).thenAnswer((_) async => null);
    });

    blocTest<AdvancedReaderBloc, ReaderState>(
      'loads book and starts sequential playback on TogglePlayPause',
      build: () => AdvancedReaderBloc(
        bookRepository: bookRepository,
        flutterTts: flutterTts,
        audioPlayer: audioPlayer,
      ),
      act: (bloc) async {
        bloc.add(LoadBook('1'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(TogglePlayPause());
      },
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => audioPlayer.play(any())).called(1);
      },
    );

    test('mutual exclusion between TTS and audio', () async {
      final bloc = AdvancedReaderBloc(
        bookRepository: bookRepository,
        flutterTts: flutterTts,
        audioPlayer: audioPlayer,
      );
      bloc.emit(ReaderLoaded(
        book: book,
        currentPage: 0,
        totalPages: 1,
        currentPageContent: 'Hello world.',
        fontSize: 24,
        isSpeaking: false,
        isPaused: false,
        speechRate: 0.4,
      ));

      await bloc.speakSentenceWithIndex('Hello world.', 0);
      verify(() => audioPlayer.stop()).called(greaterThanOrEqualTo(1));

      await bloc.playSentenceFromUrl('http://example.com/audio.mp3');
      verify(() => flutterTts.stop()).called(greaterThanOrEqualTo(1));
    });
  });
}


