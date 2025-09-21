import 'package:flutter/material.dart';
import 'dart:async';

class VocabularyQuizTimer extends StatefulWidget {
  final int initialTime;
  final Function(int) onTimeUpdate;
  final Function() onTimeUp;
  final bool isActive;
  final String? questionId; // Her yeni soru için timer'ı reset etmek için

  const VocabularyQuizTimer({
    super.key,
    required this.initialTime,
    required this.onTimeUpdate,
    required this.onTimeUp,
    this.isActive = true,
    this.questionId,
  });

  @override
  State<VocabularyQuizTimer> createState() => _VocabularyQuizTimerState();
}

class _VocabularyQuizTimerState extends State<VocabularyQuizTimer>
    with TickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _timeRemaining = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
  }

  @override
  void didUpdateWidget(VocabularyQuizTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Eğer soru değiştiyse timer'ı reset et
    if (widget.questionId != oldWidget.questionId) {
      _resetTimer();
    }
    
    if (widget.isActive && !_isRunning) {
      _startTimer();
    } else if (!widget.isActive && _isRunning) {
      _stopTimer();
    }
  }

  void _initializeTimer() {
    _timeRemaining = widget.initialTime;
    
    _animationController = AnimationController(
      duration: Duration(seconds: widget.initialTime),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    if (widget.isActive) {
      _startTimer();
    }
  }

  void _resetTimer() {
    _stopTimer();
    _timeRemaining = widget.initialTime;
    
    _animationController.reset();
    _animationController.duration = Duration(seconds: widget.initialTime);
    
    if (widget.isActive) {
      _startTimer();
    }
  }

  void _startTimer() {
    if (_isRunning) return;
    
    _isRunning = true;
    _animationController.forward();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
        widget.onTimeUpdate(_timeRemaining);
      } else {
        _stopTimer();
        widget.onTimeUp();
      }
    });
  }

  void _stopTimer() {
    if (!_isRunning) return;
    
    _isRunning = false;
    _timer.cancel();
    _animationController.stop();
  }

  @override
  void dispose() {
    _stopTimer();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = _timeRemaining <= 10;
    final color = isUrgent ? Colors.red : Colors.blue;
    
    return Container(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          // Circular progress indicator
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CircularProgressIndicator(
                value: _animation.value,
                strokeWidth: 6,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              );
            },
          ),
          
          // Time text
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$_timeRemaining',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'saniye',
                    style: TextStyle(
                      fontSize: 10,
                      color: color.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
