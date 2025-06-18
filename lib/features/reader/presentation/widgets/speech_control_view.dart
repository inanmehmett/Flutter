import 'package:flutter/material.dart';

class SpeechControlView extends StatefulWidget {
  final bool isSpeaking;
  final bool isPaused;
  final double progress;
  final int currentPage;
  final int totalPages;
  final double speechRate;
  final double pitch;
  final String selectedVoice;
  final List<String> availableVoices;
  final VoidCallback onPlayPause;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final ValueChanged<double> onSpeechRateChanged;
  final ValueChanged<double> onPitchChanged;
  final ValueChanged<String> onVoiceChanged;
  final ValueChanged<int> onPageChanged;

  const SpeechControlView({
    super.key,
    required this.isSpeaking,
    required this.isPaused,
    required this.progress,
    required this.currentPage,
    required this.totalPages,
    required this.speechRate,
    required this.pitch,
    required this.selectedVoice,
    required this.availableVoices,
    required this.onPlayPause,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onSpeechRateChanged,
    required this.onPitchChanged,
    required this.onVoiceChanged,
    required this.onPageChanged,
  });

  @override
  State<SpeechControlView> createState() => _SpeechControlViewState();
}

class _SpeechControlViewState extends State<SpeechControlView> {
  bool _showVoicePicker = false;
  bool _showSpeedControl = false;
  bool _showPitchControl = false;

  @override
  Widget build(BuildContext context) {
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
          _buildProgressBar(),
          const SizedBox(height: 16),
          _buildControlButtons(),
          const SizedBox(height: 16),
          _buildAdditionalControls(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Slider(
          value: widget.progress,
          onChanged: (value) {
            final targetPage = (value * widget.totalPages).round();
            widget.onPageChanged(targetPage);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.currentPage + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '/ ${widget.totalPages}',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous),
          onPressed: widget.onPreviousPage,
          iconSize: 32,
        ),
        const SizedBox(width: 24),
        IconButton(
          icon: Icon(
            widget.isSpeaking
                ? (widget.isPaused ? Icons.play_circle : Icons.pause_circle)
                : Icons.play_circle,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: widget.onPlayPause,
          iconSize: 48,
        ),
        const SizedBox(width: 24),
        IconButton(
          icon: const Icon(Icons.skip_next),
          onPressed: widget.onNextPage,
          iconSize: 32,
        ),
      ],
    );
  }

  Widget _buildAdditionalControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildVoiceButton(),
        _buildSpeedButton(),
        _buildPitchButton(),
      ],
    );
  }

  Widget _buildVoiceButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.record_voice_over),
          onPressed: () {
            setState(() {
              _showVoicePicker = !_showVoicePicker;
              _showSpeedControl = false;
              _showPitchControl = false;
            });
          },
        ),
        if (_showVoicePicker)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.availableVoices.map((voice) {
                return ListTile(
                  title: Text(voice),
                  selected: voice == widget.selectedVoice,
                  onTap: () {
                    widget.onVoiceChanged(voice);
                    setState(() {
                      _showVoicePicker = false;
                    });
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSpeedButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.speed),
          onPressed: () {
            setState(() {
              _showSpeedControl = !_showSpeedControl;
              _showVoicePicker = false;
              _showPitchControl = false;
            });
          },
        ),
        if (_showSpeedControl)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: widget.speechRate,
                  min: 0.5,
                  max: 2.0,
                  divisions: 3,
                  label: '${widget.speechRate.toStringAsFixed(1)}x',
                  onChanged: widget.onSpeechRateChanged,
                ),
                const Text('Speed'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPitchButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: () {
            setState(() {
              _showPitchControl = !_showPitchControl;
              _showVoicePicker = false;
              _showSpeedControl = false;
            });
          },
        ),
        if (_showPitchControl)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: widget.pitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 3,
                  label: '${widget.pitch.toStringAsFixed(1)}x',
                  onChanged: widget.onPitchChanged,
                ),
                const Text('Pitch'),
              ],
            ),
          ),
      ],
    );
  }
}
