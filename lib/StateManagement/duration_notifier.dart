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
  late Duration _duration;
  late Timer _timer;
  late bool _isTimeFormat;
  double _liters = 0.0;
  double _setLiters = 0.0;
  double _flowRate = 0.0;

  // Variables for ON/OFF timing
  int _onTime = 0;
  int _offTime = 0;
  int _currentStatus = 1;
  int _remainingOnTime = 0;
  int _remainingOffTime = 0;
  bool _isPaused = false;
  String _frtMethod = '0';
  bool _isCompleted = false;
  int _externalStatus = 1;
  bool _hasValidPayload = true;

  // Flag to prevent multiple post-frame callbacks
  bool _hasPendingUpdate = false;

  String get onCompletedDrQ {
    if (_isCompleted) return _formatTime(_duration);
    return _isTimeFormat ? _formatTime(_duration) : _liters.toStringAsFixed(2);
  }

  String get currentDuration => _formatTime(_duration);
  int get currentStatus => _currentStatus;
  bool get isPaused => _isPaused;
  bool get isCompleted => _isCompleted;
  int get remainingOnTime => _remainingOnTime;
  int get remainingOffTime => _remainingOffTime;

  IncreaseDurationNotifier(
      String setValve,
      String completedValve,
      double flowRate, {
        int onTime = 0,
        int offTime = 0,
        String frtMethod = '0',
        int externalStatus = 1,
        bool hasValidPayload = true,
      }) {
    _isTimeFormat = _checkIsTimeFormat(completedValve);
    _flowRate = flowRate;
    _onTime = onTime;
    _offTime = offTime;
    _frtMethod = frtMethod;
    _externalStatus = externalStatus;
    _hasValidPayload = hasValidPayload;

    _setLiters = _parseDurationToSeconds(setValve);

    if (_isTimeFormat) {
      _duration = _parseTime(completedValve);
    } else {
      _liters = double.tryParse(completedValve) ?? 0.0;
      _setLiters = double.tryParse(setValve.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }

    _checkIfCompleted();

    if (_shouldRunTimer()) {
      _startTimer();
    }
  }

  bool _shouldRunTimer() {
    return _externalStatus == 1 && _hasValidPayload && !_isCompleted;
  }

  void _checkIfCompleted() {
    if (_isTimeFormat) {
      double currentSeconds = _duration.inSeconds.toDouble();
      if (currentSeconds >= _setLiters) {
        _isCompleted = true;
        _currentStatus = 0;
      }
    } else {
      if (_liters >= _setLiters) {
        _isCompleted = true;
        _currentStatus = 0;
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_shouldRunTimer()) {
        if (_timer != null && _timer.isActive) {
          _stopTimer();
        }
        return;
      }

      if (_isPaused) return;

      if (_frtMethod == '3' && (_onTime > 0 || _offTime > 0)) {
        _handleOnOffTiming();
      }

      if (_currentStatus == 1 && !_isCompleted) {
        if (_isTimeFormat) {
          _duration += const Duration(seconds: 1);
          if (_duration.inSeconds >= _setLiters) {
            _isCompleted = true;
            _currentStatus = 0;
            _stopTimer();
          }
        } else {
          double flowRatePerSecond = _flowRate / 3600;
          _liters += flowRatePerSecond;

          if (_liters >= _setLiters) {
            _liters = _setLiters;
            _isCompleted = true;
            _currentStatus = 0;
            _stopTimer();
          }
        }
      }

      // Schedule notification after build phase
      _scheduleNotifyListeners();
    });
  }

  void _handleOnOffTiming() {
    if (_isCompleted) return;
    if (!_shouldRunTimer()) return;

    if (_currentStatus == 1 && _onTime > 0) {
      if (_remainingOnTime == 0) {
        _remainingOnTime = _onTime;
      }

      _remainingOnTime--;

      if (_remainingOnTime <= 0) {
        _currentStatus = 0;
        _remainingOffTime = _offTime;
      }
    }
    else if (_currentStatus == 0 && _offTime > 0 && !_isCompleted) {
      if (_remainingOffTime == 0) {
        _remainingOffTime = _offTime;
      }

      _remainingOffTime--;

      if (_remainingOffTime <= 0) {
        _currentStatus = 1;
        _remainingOnTime = _onTime;
      }
    }
  }

  void updateExternalStatus(int status, bool hasValidPayload) {
    bool shouldRestart = false;

    if (_externalStatus != status) {
      _externalStatus = status;
      shouldRestart = true;
    }

    if (_hasValidPayload != hasValidPayload) {
      _hasValidPayload = hasValidPayload;
      shouldRestart = true;
    }

    if (shouldRestart) {
      _restartTimerIfNeeded();
      // Schedule notification after build phase
      _scheduleNotifyListeners();
    }
  }

  void _restartTimerIfNeeded() {
    _stopTimer();

    // Reset state when external status becomes invalid
    if (!_shouldRunTimer()) {
      _currentStatus = 1;
      _remainingOnTime = 0;
      _remainingOffTime = 0;
      _isPaused = false;
    }

    if (_shouldRunTimer()) {
      _startTimer();
    }
  }

  void pauseTimer() {
    if (!_isPaused && _shouldRunTimer()) {
      _isPaused = true;
      _scheduleNotifyListeners();
    }
  }

  void resumeTimer() {
    if (_isPaused && _shouldRunTimer()) {
      _isPaused = false;
      _scheduleNotifyListeners();
    }
  }

  void resetTimer() {
    _stopTimer();
    _isPaused = false;
    _isCompleted = false;
    _currentStatus = 1;
    _remainingOnTime = 0;
    _remainingOffTime = 0;

    if (_isTimeFormat) {
      _duration = Duration.zero;
    } else {
      _liters = 0.0;
    }

    if (_shouldRunTimer()) {
      _startTimer();
    }

    _scheduleNotifyListeners();
  }

  void _scheduleNotifyListeners() {
    if (!_hasPendingUpdate) {
      _hasPendingUpdate = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hasPendingUpdate = false;
        notifyListeners();
      });
    }
  }

  void _stopTimer() {
    if (_timer != null && _timer.isActive) {
      _timer.cancel();
    }
  }

  double _parseDurationToSeconds(String duration) {
    if (duration.isEmpty || duration == '00:00:00') return 0;
    List<String> parts = duration.split(':');
    if (parts.length == 3) {
      int hours = int.parse(parts[0]);
      int minutes = int.parse(parts[1]);
      int seconds = int.parse(parts[2]);
      return (hours * 3600 + minutes * 60 + seconds).toDouble();
    }
    return 0;
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
    _stopTimer();
    super.dispose();
  }
}


/*class IncreaseDurationNotifier extends ChangeNotifier {
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
