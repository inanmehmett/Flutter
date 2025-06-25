import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/advanced_reader_bloc.dart';
import '../bloc/reader_event.dart';
import '../bloc/reader_state.dart';
import '../../data/models/book_model.dart';

class AdvancedReaderPage extends StatefulWidget {
  final BookModel book;

  const AdvancedReaderPage({
    Key? key,
    required this.book,
  }) : super(key: key);

  @override
  State<AdvancedReaderPage> createState() => _AdvancedReaderPageState();
}

class _AdvancedReaderPageState extends State<AdvancedReaderPage> {
  late final AdvancedReaderBloc _readerBloc;

  @override
  void initState() {
    super.initState();
    _readerBloc = context.read<AdvancedReaderBloc>();
    _loadBook();
  }

  void _loadBook() {
    _readerBloc.add(LoadBook(widget.book.id.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AdvancedReaderBloc, ReaderState>(
        builder: (context, state) {
          if (state is ReaderLoading) {
            return _buildLoadingView();
          } else if (state is ReaderError) {
            return _buildErrorView(state.message);
          } else if (state is ReaderLoaded) {
            return _buildReaderView(state);
          } else {
            return _buildInitialView();
          }
        },
      ),
    );
  }

  Widget _buildInitialView() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Kitap yükleniyor...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hata'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Hata: $message',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBook,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReaderView(ReaderLoaded state) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(state),
            _buildProgressBar(state),
            Expanded(
              child: _buildReadingArea(state),
            ),
            _buildControls(state),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ReaderLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.book.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Sayfa ${state.currentPage + 1} / ${state.totalPages}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(state),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ReaderLoaded state) {
    final progress = (state.currentPage + 1) / state.totalPages;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Theme.of(context).colorScheme.surface,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildReadingArea(ReaderLoaded state) {
    final pageController = PageController(initialPage: state.currentPage);
    return PageView.builder(
      controller: pageController,
      itemCount: state.totalPages,
      onPageChanged: (index) {
        if (index != state.currentPage) {
          _readerBloc.add(GoToPage(index));
        }
      },
      itemBuilder: (context, index) {
        return Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Text(
              state.currentPage == index ? state.currentPageContent : '',
              // Sadece aktif sayfanın içeriğini gösteriyoruz, diğerleri boş
              style: TextStyle(
                fontSize: state.fontSize,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.6,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls(ReaderLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress slider
          Slider(
            value: (state.currentPage + 1) / state.totalPages,
            onChanged: (value) {
              final targetPage = (value * state.totalPages).round() - 1;
              if (targetPage >= 0 && targetPage < state.totalPages) {
                _readerBloc.add(GoToPage(targetPage));
              }
            },
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          
          // Page info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sayfa ${state.currentPage + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '/ ${state.totalPages}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  '${(((state.currentPage + 1) / state.totalPages) * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous page
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: () => _readerBloc.add(PreviousPage()),
                iconSize: 32,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              
              // Play/Pause button
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: IconButton(
                  icon: Icon(
                    state.isSpeaking
                        ? (state.isPaused ? Icons.play_arrow : Icons.pause)
                        : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () => _readerBloc.add(TogglePlayPause()),
                  iconSize: 32,
                ),
              ),
              
              // Stop button
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: () => _readerBloc.add(StopSpeech()),
                iconSize: 32,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              
              // Next page
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: () => _readerBloc.add(NextPage()),
                iconSize: 32,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(ReaderLoaded state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Okuma Ayarları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Font size control
            ListTile(
              title: const Text('Yazı Boyutu'),
              subtitle: Slider(
                value: state.fontSize,
                min: 12.0,
                max: 32.0,
                divisions: 20,
                onChanged: (size) {
                  _readerBloc.add(UpdateFontSize(size));
                },
              ),
              trailing: Text('${state.fontSize.round()}'),
            ),
            
            // Speech rate control
            ListTile(
              title: const Text('Konuşma Hızı'),
              subtitle: Slider(
                value: state.speechRate,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                onChanged: (rate) {
                  _readerBloc.add(UpdateSpeechRate(rate));
                },
              ),
              trailing: Text('${state.speechRate.toStringAsFixed(1)}x'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
} 