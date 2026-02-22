import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';

enum OperationType { addition, subtraction, multiplication }

class DailyRitualScreen extends StatefulWidget {
  const DailyRitualScreen({super.key});

  @override
  State<DailyRitualScreen> createState() => _DailyRitualScreenState();
}

class _DailyRitualScreenState extends State<DailyRitualScreen> {
  final Random _random = Random();
  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 2));

  OperationType _operation = OperationType.addition;
  int _difficulty = 0;
  int _targetQuestions = 25;


  int _num1 = 0;
  int _num2 = 0;
  int _correctAnswer = 0;

  int _score = 0;
  int _streak = 0;

  int _totalQuestions = 0;
  int _correctAnswers = 0;
  double _totalResponseTime = 0;

  DateTime? _questionStartTime;

  int _timeLeft = 300;
  Timer? _timer;

  int? _selectedAnswer;
  bool _showFeedback = false;

  List<int> _options = [];

  @override
  void initState() {
    super.initState();
    _startTimer();
    _generateQuestion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  // ---------------- TIMER ----------------

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

  // ---------------- SOUND ----------------

  Future<void> _playSound(String fileName) async {
    final player = AudioPlayer();
    await player.play(AssetSource('sounds/$fileName'));
  }

  // ---------------- QUESTION ----------------

  void _generateQuestion() {
    _questionStartTime = DateTime.now();

    switch (_operation) {
      case OperationType.addition:
        _num1 = _random.nextInt(20);
        _num2 = _random.nextInt(20);
        _correctAnswer = _num1 + _num2;
        break;

      case OperationType.subtraction:
        _num1 = _random.nextInt(20);
        _num2 = _random.nextInt(20);
        if (_num1 < _num2) {
          int temp = _num1;
          _num1 = _num2;
          _num2 = temp;
        }
        _correctAnswer = _num1 - _num2;
        break;

      case OperationType.multiplication:
        _num1 = _random.nextInt(10);
        _num2 = _random.nextInt(10);
        _correctAnswer = _num1 * _num2;
        break;
    }

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

  // ---------------- ANSWER ----------------

  void _checkAnswer(int selected) async {
    if (_showFeedback) return;

    setState(() {
      _selectedAnswer = selected;
      _showFeedback = true;
    });

    _totalQuestions++;
    if (_totalQuestions >= _targetQuestions) {
      _timer?.cancel();
      _handleSessionEnd();
      return;
    }



    final responseTime =
        DateTime.now().difference(_questionStartTime!).inMilliseconds / 1000;

    _totalResponseTime += responseTime;

    if (selected == _correctAnswer) {
      _correctAnswers++;
      _score += 10;
      _streak++;
      await _playSound('correct.wav');

      if (_streak == 5) {
        _confettiController.play(); // 🎉 streak reward
      }
    } else {
      _streak = 0;
      await _playSound('wrong.wav');
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      _generateQuestion();
    });
  }

  // ---------------- SESSION END ----------------

  void _handleSessionEnd() {
  if (_totalQuestions == 0) return;

  int wrongAnswers = _totalQuestions - _correctAnswers;
  double accuracy = (_correctAnswers / _totalQuestions) * 100;
  double avgTime = _totalResponseTime / _totalQuestions;

  _confettiController.play();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text("🎉 5-Minute Math Report"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("⭐ Questions Attempted: $_totalQuestions"),
          Text("✅ Correct Answers: $_correctAnswers"),
          Text("🔁 Needs Practice: $wrongAnswers"),
          const SizedBox(height: 8),
          Text("📊 Accuracy: ${accuracy.toStringAsFixed(0)}%"),
          Text("⏱ Avg Time: ${avgTime.toStringAsFixed(2)} sec"),
        ],
      ),
actions: [
  TextButton(
    onPressed: () {
      Navigator.pop(context);
      _showParentReport(
        accuracy,
        avgTime,
        wrongAnswers,
      );
    },
    child: const Text("👨‍👩‍👧 Parent View"),
  ),
  TextButton(
    onPressed: () {
      Navigator.pop(context);
      _resetSession();
    },
    child: const Text("Start Again"),
  ),
],

    ),
  );
}

  void _showParentReport(
  double accuracy,
  double avgTime,
  int wrongAnswers,
) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("📈 Parent Performance Report"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Questions Attempted: $_totalQuestions"),
          Text("Correct: $_correctAnswers"),
          Text("Incorrect: $wrongAnswers"),
          const SizedBox(height: 8),
          Text("Accuracy: ${accuracy.toStringAsFixed(1)}%"),
          Text("Average Response Time: ${avgTime.toStringAsFixed(2)} sec"),
          const SizedBox(height: 12),
          const Text(
            "Insight:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            "Consistent daily practice will improve speed and accuracy.",
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Close"),
        ),
      ],
    ),
  );
}

  void _resetSession() {
    setState(() {
      _score = 0;
      _streak = 0;
      _totalQuestions = 0;
      _correctAnswers = 0;
      _totalResponseTime = 0;
      _timeLeft = 300;
    });

    _startTimer();
    _generateQuestion();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    String minutes = (_timeLeft ~/ 60).toString().padLeft(2, '0');
    String seconds = (_timeLeft % 60).toString().padLeft(2, '0');

    String questionText = _operation == OperationType.addition
        ? "$_num1 + $_num2 = ?"
        : _operation == OperationType.subtraction
            ? "$_num1 - $_num2 = ?"
            : "$_num1 × $_num2 = ?";

    return Scaffold(
      appBar: AppBar(
        title: const Text("🎯 Today's 5-Minute Math"),
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    "Time Left: $minutes:$seconds",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text("➕"),
                        selected:
                            _operation == OperationType.addition,
                        onSelected: (_) {
                          setState(() {
                            _operation =
                                OperationType.addition;
                            _generateQuestion();
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text("➖"),
                        selected:
                            _operation == OperationType.subtraction,
                        onSelected: (_) {
                          setState(() {
                            _operation =
                                OperationType.subtraction;
                            _generateQuestion();
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text("✖"),
                        selected:
                            _operation ==
                                OperationType.multiplication,
                        onSelected: (_) {
                          setState(() {
                            _operation =
                                OperationType.multiplication;
                            _generateQuestion();
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Text(
                    questionText,
                    style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 40),

                  GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
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
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 20),
                        ),
                        onPressed: () async {
                          await _playSound('click.wav');
                          _checkAnswer(value);
                        },
                        child: Text(
                          value.toString(),
                          style: const TextStyle(
                              fontSize: 26),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  Text("Score: $_score"),
                  Text("🔥 Streak: $_streak"),
                ],
              ),
            ),
          ),

          // 🎉 Confetti Widget
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality:
                BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 25,
            gravity: 0.3,
          ),
        ],
      ),
    );
  }
}
