class ClockStatus {
  String time = "--:--:--";
  String date = "--.--.----";
  String temperature = "--.-°C";
  String mode = "TIME";
  String autoMode = "OFF";
  String alarm = "OFF";
  String alarmState = "WAITING";
  String timer = "0s";
  String timerState = "STOPPED";
  String stopwatch = "0s";
  String stopwatchState = "STOPPED";

  ClockStatus();

  ClockStatus copy() {
    final copy = ClockStatus();
    copy.time = time;
    copy.date = date;
    copy.temperature = temperature;
    copy.mode = mode;
    copy.autoMode = autoMode;
    copy.alarm = alarm;
    copy.alarmState = alarmState;
    copy.timer = timer;
    copy.timerState = timerState;
    copy.stopwatch = stopwatch;
    copy.stopwatchState = stopwatchState;
    return copy;
  }

  String get formattedTimer {
    final secStr = timer.replaceAll(RegExp(r'[^0-9]'), '');
    final totalSeconds = int.tryParse(secStr) ?? 0;
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  String get formattedStopwatch {
    final secStr = stopwatch.replaceAll(RegExp(r'[^0-9]'), '');
    final totalSeconds = int.tryParse(secStr) ?? 0;
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  /// Чи спрацював будильник зараз (тривога)
  bool get isAlarmTriggered => alarmState == "TRIGGERED";

  /// Чи увімкнений будильник
  bool get isAlarmEnabled => alarm != "OFF";

  /// Чи завершився відлік таймера
  bool get isTimerFinished => timerState == "FINISHED";

  /// Чи запущений секундомір
  bool get isStopwatchRunning => stopwatchState == "RUNNING";

  void updateFromLine(String line) {
    if (line.startsWith("TIME=")) {
      time = line.substring(5);
    } else if (line.startsWith("DATE=")) {
      date = line.substring(5);
    } else if (line.startsWith("TEMP=")) {
      temperature = line.substring(5);
      if (!temperature.contains('°')) {
        temperature = temperature.replaceAll('C', '°C');
      }
    } else if (line.startsWith("MODE=")) {
      mode = line.substring(5);
    } else if (line.startsWith("AUTOMODE=")) {
      autoMode = line.substring(9);
    } else if (line.startsWith("ALARM=")) {
      alarm = line.substring(6);
      if (alarm == "OFF") {
        alarmState = "OFF";
      }
    } else if (line.startsWith("ALARM_STATE=")) {
      alarmState = line.substring(12);
    } else if (line == "ALARM:TRIGGERED") {
      alarmState = "TRIGGERED";
    } else if (line == "ALARM:STOPPED") {
      alarmState = "WAITING";
    } else if (line.startsWith("TIMER=")) {
      timer = line.substring(6);
    } else if (line.startsWith("TIMER_STATE=")) {
      timerState = line.substring(12);
    } else if (line == "TIMER:FINISHED") {
      timerState = "FINISHED";
    } else if (line.startsWith("STOPWATCH=")) {
      stopwatch = line.substring(10);
    } else if (line.startsWith("STOPWATCH_STATE=")) {
      stopwatchState = line.substring(16);
    }
  }
}
