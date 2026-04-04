import 'dart:async';

import 'package:flutter/cupertino.dart';

class DurationNotifier extends ChangeNotifier {
  ValueNotifier<String> leftDurationOrFlow = ValueNotifier<String>('00:00:00');
  ValueNotifier<String> onDelayLeft = ValueNotifier<String>('00:00:00');

  void updateDuration(String newDuration) {
    leftDurationOrFlow.value = newDuration;
  }

  void updateOnDelayTime(String onDelayTime) {
    onDelayLeft.value = onDelayTime;
  }
}

class DecreaseDurationNotifier extends ChangeNotifier {
  late Duration _duration;
  late Timer _timer;

  DecreaseDurationNotifier(String timeLeft) {
    _duration = _parseTime(timeLeft);
    _startTimer();
  }

  String get onDelayLeft => _formatTime(_duration);

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_duration.inSeconds > 0) {
        _duration -= const Duration(seconds: 1);
        notifyListeners();
      } else {
        _timer.cancel();
        notifyListeners();
      }
    });
  }

  Duration _parseTime(String time) {
    List<String> parts = time.split(':');
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: int.parse(parts[2]),
    );
  }

  String _formatTime(Duration duration) {
    return "${duration.inHours.toString().padLeft(2, '0')}:"
        "${(duration.inMinutes % 60).toString().padLeft(2, '0')}:"
        "${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

class IncreaseDurationNotifier extends ChangeNotifier {
  // Existing variables
  late Duration _duration;
  late Timer _timer;
  late bool _isTimeFormat;
  double _liters = 0.0;
  double _setLiters = 0.0;
  double _flowRate = 0.0;

  // New variables for status toggling
  int _currentStatus = 1;  // 1 = ON, 0 = OFF (default ON)
  int _onTime = 0;         // Seconds to stay ON
  int _offTime = 0;        // Seconds to stay OFF
  int _remainingOnTime = 0;
  int _remainingOffTime = 0;
  bool _isPaused = false;

  // Getters
  String get onCompletedDrQ =>
      _isTimeFormat ? _formatTime(_duration) : _liters.toStringAsFixed(2);

  int get currentStatus => _currentStatus;
  bool get isPaused => _isPaused;
  int get remainingOnTime => _remainingOnTime;
  int get remainingOffTime => _remainingOffTime;

  // Updated constructor
  IncreaseDurationNotifier(
      String setValve,
      String completedValve,
      double flowRate, {
        int onTime = 0,      // New parameter
        int offTime = 0,     // New parameter
        int initialStatus = 1, // New parameter
      }) {
    _isTimeFormat = _checkIsTimeFormat(completedValve);
    _flowRate = flowRate;
    _onTime = onTime;
    _offTime = offTime;
    _currentStatus = initialStatus;

    if (_isTimeFormat) {
      _duration = _parseTime(completedValve);
    } else {
      _liters = double.tryParse(completedValve) ?? 0.0;
      _setLiters = double.tryParse(setValve.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;

      // Handle status toggling if onTime/offTime are set
      if (_onTime > 0 || _offTime > 0) {
        _handleStatusToggle();
      }

      // Only update duration/liters when status is ON (1)
      if (_currentStatus == 1) {
        if (_isTimeFormat) {
          _duration += const Duration(seconds: 1);
        } else {
          double flowRatePerSecond = _flowRate / 3600;
          _liters += flowRatePerSecond;

          if (_liters >= _setLiters) {
            _liters = _setLiters;
            _timer.cancel();
          }
        }
      }

      notifyListeners();
    });
  }

  // New method to handle status toggling
  void _handleStatusToggle() {
    if (_currentStatus == 1 && _onTime > 0) {
      // Currently ON
      if (_remainingOnTime == 0) {
        _remainingOnTime = _onTime;
      }

      _remainingOnTime--;

      if (_remainingOnTime <= 0) {
        // Switch to OFF
        _currentStatus = 0;
        _remainingOffTime = _offTime;
      }
    }
    else if (_currentStatus == 0 && _offTime > 0) {
      // Currently OFF
      if (_remainingOffTime == 0) {
        _remainingOffTime = _offTime;
      }

      _remainingOffTime--;

      if (_remainingOffTime <= 0) {
        // Switch to ON
        _currentStatus = 1;
        _remainingOnTime = _onTime;
      }
    }
  }

  // New methods for timer control
  void pauseTimer() {
    if (!_isPaused) {
      _isPaused = true;
      notifyListeners();
    }
  }

  void resumeTimer() {
    if (_isPaused) {
      _isPaused = false;
      notifyListeners();
    }
  }

  void resetTimer() {
    _isPaused = false;
    _currentStatus = 1;
    _remainingOnTime = 0;
    _remainingOffTime = 0;

    // Reset duration/liters to initial values
    if (_isTimeFormat) {
      _duration = Duration.zero;
    } else {
      _liters = 0.0;
    }

    notifyListeners();
  }

  void forceStatus(int status) {
    _currentStatus = status;
    _remainingOnTime = 0;
    _remainingOffTime = 0;
    notifyListeners();
  }

  bool _checkIsTimeFormat(String value) {
    return value.contains(':');
  }

  Duration _parseTime(String time) {
    List<String> parts = time.split(':');
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: int.parse(parts[2]),
    );
  }

  String _formatTime(Duration duration) {
    return "${duration.inHours.toString().padLeft(2, '0')}:"
        "${(duration.inMinutes % 60).toString().padLeft(2, '0')}:"
        "${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

/*
class IncreaseDurationNotifier extends ChangeNotifier {
  late Duration _duration;
  late Timer _timer;

  late bool _isTimeFormat;
  double _liters = 0.0;
  double _setLiters = 0.0;
  double _flowRate = 0.0;

  String get onCompletedDrQ =>
      _isTimeFormat ? _formatTime(_duration) : _liters.toStringAsFixed(2);

  IncreaseDurationNotifier(String setValve, String completedValve, double flowRate) {
    _isTimeFormat = _checkIsTimeFormat(completedValve);
    _flowRate = flowRate;

    if (_isTimeFormat) {
      _duration = _parseTime(completedValve);
    } else {
      _liters = double.tryParse(completedValve) ?? 0.0;
      _setLiters = double.tryParse(setValve.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isTimeFormat) {
        _duration += const Duration(seconds: 1);
      } else {
        double flowRatePerSecond = _flowRate / 3600;
        _liters += flowRatePerSecond;

        if (_liters >= _setLiters) {
          _liters = _setLiters;
          _timer.cancel();
        }
      }

      notifyListeners();
    });
  }

  bool _checkIsTimeFormat(String value) {
    return value.contains(':');
  }

  Duration _parseTime(String time) {
    List<String> parts = time.split(':');
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: int.parse(parts[2]),
    );
  }

  String _formatTime(Duration duration) {
    return "${duration.inHours.toString().padLeft(2, '0')}:"
        "${(duration.inMinutes % 60).toString().padLeft(2, '0')}:"
        "${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}*/
