import 'package:flutter/material.dart';
import 'dart:async';

/// Timer widget for quiz mode with countdown and visual feedback
class QuizTimer extends StatefulWidget {
  final Duration duration;
  final VoidCallback onTimeout;
  final VoidCallback? onTick;

  const QuizTimer({
    super.key,
    required this.duration,
    required this.onTimeout,
    this.onTick,
  });

  @override
  State<QuizTimer> createState() => QuizTimerState();
}

class QuizTimerState extends State<QuizTimer> with SingleTickerProviderStateMixin {
  Timer? _timer;
  late int _remainingSeconds;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.duration.inSeconds;
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Start the timer
  void start() {
    if (_isRunning) return;
    
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _remainingSeconds--;
      });
      
      widget.onTick?.call();
      
      // Pulse animation when low on time
      if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
        _pulseController.forward().then((_) => _pulseController.reverse());
      }
      
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _isRunning = false;
        widget.onTimeout();
      }
    });
  }

  /// Stop the timer
  void stop() {
    _timer?.cancel();
    _isRunning = false;
  }

  /// Reset the timer to initial duration
  void reset() {
    stop();
    setState(() {
      _remainingSeconds = widget.duration.inSeconds;
    });
  }

  /// Get remaining seconds
  int get remainingSeconds => _remainingSeconds;

  /// Check if timer is running
  bool get isRunning => _isRunning;

  @override
  Widget build(BuildContext context) {
    final isLowTime = _remainingSeconds <= 3;
    final isCritical = _remainingSeconds <= 1;
    
    final color = isCritical
        ? Colors.red
        : isLowTime
            ? Colors.orange
            : Colors.blue;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isLowTime ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: isLowTime
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _remainingSeconds.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

