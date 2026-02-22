import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';


class GameScreen extends StatefulWidget {
  final bool isTimeMode;

  const GameScreen({super.key, required this.isTimeMode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Random _random = Random();

  int _num1 = 0;
  int _num2 = 0;
  int _gamesPlayed = 0;

  int _difficulty = 0;

  int _totalQuestions = 0;
  int _correctAnswers = 0;
  double _totalResponseTime = 0;

  DateTime? _questionStartTime;


  int _correctAnswer = 0;

  int _score = 0;
  int _questionCount = 0;
  int _streak = 0;
  int _level = 1;

  int _highScore = 0;

  int _timeLeft = 60;
  Timer? _timer;

  int? _selectedAnswer;
  bool _showFeedback = false;

  List<int> _options = [];

  @override
  void initState() {
    super.initState();
    _loadSavedData();

    _generateQuestion();

    if (widget.isTimeMode) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft <= 0) {
        timer.cancel();
        _handleSessionEnd();
      } else {
        setState(() {
          _timeLeft--;
        });
      }
    });
  }

  Future<void> _playSound(String fileName) async {
    final player = AudioPlayer();
    await player.play(AssetSource('sounds/$fileName'));
  }

  int _getMaxNumberForLevel() {
    if (_level == 1) return 10;
    if (_level == 2) return 20;
    return 50;
  }

  Future<void> _loadSavedData() async {
  final prefs = await SharedPreferences.getInstance();

  setState(() {
    _highScore = prefs.getInt('highScore') ?? 0;
    _level = prefs.getInt('level') ?? 1;
    _gamesPlayed = prefs.getInt('gamesPlayed') ?? 0;
  });
}


void _generateQuestion() {
  _questionStartTime = DateTime.now();

  switch (_difficulty) {
    case 0:
      _num1 = _random.nextInt(10);
      _num2 = _random.nextInt(10);
      break;

    case 1:
      _num1 = _random.nextInt(20);
      _num2 = _random.nextInt(20);
      break;

    case 2:
      _num1 = _random.nextInt(90) + 10; // 10–99
      _num2 = _random.nextInt(9);       // no carry simple
      break;

    case 3:
      _num1 = _random.nextInt(90) + 10;
      _num2 = _random.nextInt(90) + 10;
      break;
  }

  _correctAnswer = _num1 + _num2;
  _options = _generateOptions(_correctAnswer);

  _selectedAnswer = null;
  _showFeedback = false;

  setState(() {});
}


  List<int> _generateOptions(int correct) {
    Set<int> options = {correct};

    while (options.length < 4) {
      int wrong = correct + _random.nextInt(10) - 5;
      if (wrong >= 0) {
        options.add(wrong);
      }
    }

    return options.toList()..shuffle();
  }

  void _checkAnswer(int selected) async {
    if (_showFeedback) return;

    setState(() {
      _selectedAnswer = selected;
      _showFeedback = true;
    });

    if (selected == _correctAnswer) {
      _score += 10;
      _streak++;
      await _playSound('correct.wav');

      if (_streak >= 3) {
        _score += 5;
      }
    } else {
      _streak = 0;
      await _playSound('wrong.wav');
    }

    _questionCount++;

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!widget.isTimeMode && _questionCount >= 10) {
        _handleSessionEnd();
      } else {
        _generateQuestion();
      }
    });
  }

  Future<void> _handleSessionEnd() async
 {
    _timer?.cancel();

    if (_score > _highScore) {
      _highScore = _score;
    }

    _gamesPlayed++;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', _highScore);
    await prefs.setInt('level', _level);
    await prefs.setInt('gamesPlayed', _gamesPlayed);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Game Over 🎉"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Score: $_score"),
            Text("High Score: $_highScore"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _score = 0;
                _questionCount = 0;
                _streak = 0;
                _timeLeft = 60;
              });

              if (widget.isTimeMode) {
                _startTimer();
              }

              _generateQuestion();
            },
            child: const Text("Play Again"),
          )
        ],
      ),
    );
  }

  Color _getButtonColor(int value) {
    if (!_showFeedback) return Colors.blue;

    if (value == _correctAnswer) return Colors.green;

    if (value == _selectedAnswer && value != _correctAnswer) {
      return Colors.red;
    }

    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    double progress = _questionCount / 10;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTimeMode ? "⏱ Time Attack" : "Classic Mode"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (!widget.isTimeMode)
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
              ),

            if (widget.isTimeMode)
              Text(
                "Time Left: $_timeLeft s",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 30),

            Text(
              "$_num1 + $_num2 = ?",
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _options.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 2,
              ),
              itemBuilder: (context, index) {
                final value = _options[index];

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getButtonColor(value),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await _playSound('click.wav');
                    _checkAnswer(value);
                  },
                  child: Text(
                    value.toString(),
                    style: const TextStyle(fontSize: 24),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            Text(
              "Score: $_score",
              style: const TextStyle(fontSize: 20),
            ),

            const SizedBox(height: 10),

            Text(
              "🔥 Streak: $_streak",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
