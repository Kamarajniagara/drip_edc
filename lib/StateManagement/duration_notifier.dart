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

  // New variables for Method 3 & 4 (Pro Methods)
  String _frtMethod = '1';
  int _onTime = 0;
  int _offTime = 0;

  int _currentStatus = 1; // 1 = ON, 0 = OFF
  int _remainingOnTime = 0;
  int _remainingOffTime = 0;

  String get onCompletedDrQ =>
      _isTimeFormat ? _formatTime(_duration) : _liters.toStringAsFixed(2);

  IncreaseDurationNotifier(
      String setValve,
      String completedValve,
      double flowRate, {
        String frtMethod = '1',
        int onTime = 0,
        int offTime = 0,
      }) {
    _isTimeFormat = _checkIsTimeFormat(completedValve);
    _flowRate = flowRate;
    _frtMethod = frtMethod;
    _onTime = onTime;
    _offTime = offTime;

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
      // Handle ON/OFF timing for Pro Methods (3 & 4)
      if ((_frtMethod == '3' || _frtMethod == '4') && (_onTime > 0 || _offTime > 0)) {
        _handleOnOffTiming();
      }

      // Method 1 & 3: Time-based (increment only when status is ON for Method 3)
      if (_frtMethod == '1' || _frtMethod == '3') {
        // For Method 3, only increment if currentStatus is 1 (ON)
        // For Method 1, always increment
        if (_frtMethod == '3' && _currentStatus != 1) {
          // Skip increment for Method 3 when OFF
          notifyListeners();
          return;
        }

        _duration += const Duration(seconds: 1);

        // Check completion only for Method 1 (Method 3 will be handled by ChannelWidget)
        if (_frtMethod == '1') {
          // You might want to add completion logic here
        }
      }
      // Method 2 & 4: Flow-based (increment only when status is ON for Method 4)
      else if (_frtMethod == '2' || _frtMethod == '4') {
        // For Method 4, only increment if currentStatus is 1 (ON)
        // For Method 2, always increment
        if (_frtMethod == '4' && _currentStatus != 1) {
          // Skip increment for Method 4 when OFF
          notifyListeners();
          return;
        }

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

  void _handleOnOffTiming() {
    // Initialize remaining times if needed
    if (_currentStatus == 1 && _onTime > 0 && _remainingOnTime <= 0) {
      _remainingOnTime = _onTime;
    }

    if (_currentStatus == 0 && _offTime > 0 && _remainingOffTime <= 0) {
      _remainingOffTime = _offTime;
    }

    if (_currentStatus == 1 && _onTime > 0) {
      _remainingOnTime--;

      if (_remainingOnTime <= 0) {
        _currentStatus = 0;
        _remainingOffTime = _offTime;
        print('Method $_frtMethod - ON period ended, switching to OFF for $_offTime seconds');
      }
    }
    else if (_currentStatus == 0 && _offTime > 0) {
      _remainingOffTime--;

      if (_remainingOffTime <= 0) {
        _currentStatus = 1;
        _remainingOnTime = _onTime;
        print('Method $_frtMethod - OFF period ended, switching to ON for $_onTime seconds');
      }
    }
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