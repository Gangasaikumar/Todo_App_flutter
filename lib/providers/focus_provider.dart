import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/notification_service.dart';

enum FocusMode { work, shortBreak, longBreak }

enum TimerState { initial, running, paused }

enum Soundscape { none, rain, forest, whiteNoise, cafe }

class FocusProvider with ChangeNotifier {
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _backgroundPlayer = AudioPlayer();
  final AppNotificationService _notificationService = AppNotificationService();

  // Settings
  int _workDurationMinutes = 30; // Default
  String? _currentTodoId;
  Function(String)? onPomodoroComplete;

  // State
  FocusMode _mode = FocusMode.work;
  TimerState _timerState = TimerState.initial;
  Soundscape _selectedSoundscape = Soundscape.none; // Sound State
  int _currentDuration = 30 * 60;
  int _initialDuration = 30 * 60;

  FocusMode get mode => _mode;
  TimerState get timerState => _timerState;
  Soundscape get selectedSoundscape => _selectedSoundscape;
  int get currentDuration => _currentDuration;
  int get initialDuration => _initialDuration;

  // Presets (in seconds)
  // Work duration depends on setting _workDurationMinutes
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;

  int get shortBreakMinutes => _shortBreakMinutes;
  int get longBreakMinutes => _longBreakMinutes;

  FocusProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _workDurationMinutes = prefs.getInt('focusDurationMinutes') ?? 30;
    _shortBreakMinutes = prefs.getInt('shortBreakMinutes') ?? 5;
    _longBreakMinutes = prefs.getInt('longBreakMinutes') ?? 15;

    // Update current duration if we are in work mode and initial state
    if (_mode == FocusMode.work && _timerState == TimerState.initial) {
      _currentDuration = _workDurationMinutes * 60;
      _initialDuration = _workDurationMinutes * 60;
      notifyListeners();
    }
  }

  Future<void> updateSettings(int workMinutes) async {
    _workDurationMinutes = workMinutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('focusDurationMinutes', workMinutes);

    // Reset if currently idle to reflect new settings immediately
    if (_mode == FocusMode.work && _timerState == TimerState.initial) {
      _currentDuration = _workDurationMinutes * 60;
      _initialDuration = _workDurationMinutes * 60;
      notifyListeners();
    }
  }

  Future<void> updateBreakSettings(int shortMinutes, int longMinutes) async {
    _shortBreakMinutes = shortMinutes;
    _longBreakMinutes = longMinutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('shortBreakMinutes', shortMinutes);
    await prefs.setInt('longBreakMinutes', longMinutes);
    notifyListeners();
  }

  void startWorkSession(String? todoId) {
    _currentTodoId = todoId;
    setMode(FocusMode.work);
    // Auto-start or wait for user? Let's just set the mode and ID.
  }

  void setMode(FocusMode mode) {
    _stopTimerInternal();
    _mode = mode;
    switch (mode) {
      case FocusMode.work:
        _currentDuration = _workDurationMinutes * 60;
        _initialDuration = _workDurationMinutes * 60;
        break;
      case FocusMode.shortBreak:
        _currentDuration = _shortBreakMinutes * 60;
        _initialDuration = _shortBreakMinutes * 60;
        break;
      case FocusMode.longBreak:
        _currentDuration = _longBreakMinutes * 60;
        _initialDuration = _longBreakMinutes * 60;
        break;
    }
    _timerState = TimerState.initial;
    notifyListeners();
  }

  // --- Soundscape Logic ---

  void setSoundscape(Soundscape sound) {
    _selectedSoundscape = sound;
    notifyListeners();
    // If running, switch sound immediately
    if (_timerState == TimerState.running) {
      _playBackgroundSound();
    }
  }

  Future<void> _playBackgroundSound() async {
    if (_selectedSoundscape == Soundscape.none) {
      await _backgroundPlayer.stop();
      return;
    }

    final filename = _getSoundFilename(_selectedSoundscape);
    if (filename == null) return;

    try {
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      // Wait a bit to ensure clean switch if swiping fast
      await _backgroundPlayer.stop();
      await _backgroundPlayer.play(AssetSource(filename));
    } catch (e) {
      debugPrint('Error playing background sound: $e');
    }
  }

  Future<void> _stopBackgroundSound() async {
    try {
      await _backgroundPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping background sound: $e');
    }
  }

  String? _getSoundFilename(Soundscape sound) {
    switch (sound) {
      case Soundscape.rain:
        return 'sounds/rain.mp3';
      case Soundscape.forest:
        return 'sounds/forest.mp3';
      case Soundscape.whiteNoise:
        return 'sounds/white_noise.mp3';
      case Soundscape.cafe:
        return 'sounds/cafe.mp3';
      default:
        return null; // None
    }
  }

  void startTimer() {
    if (_timerState == TimerState.running) return;

    _timerState = TimerState.running;
    notifyListeners();

    _playBackgroundSound(); // Start sound

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentDuration > 0) {
        _currentDuration--;
        notifyListeners();
      } else {
        _completeSession();
      }
    });
  }

  void pauseTimer() {
    if (_timerState != TimerState.running) return;
    _timer?.cancel();
    _timerState = TimerState.paused;
    _stopBackgroundSound();
    notifyListeners();
  }

  void stopTimer() {
    _stopTimerInternal();
    _stopBackgroundSound();
    // Reset to initial of current mode
    switch (_mode) {
      case FocusMode.work:
        _currentDuration = _workDurationMinutes * 60;
        break;
      case FocusMode.shortBreak:
        _currentDuration = _shortBreakMinutes * 60;
        break;
      case FocusMode.longBreak:
        _currentDuration = _longBreakMinutes * 60;
        break;
    }
    _timerState = TimerState.initial;
    notifyListeners();
  }

  void _stopTimerInternal() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _completeSession() async {
    stopTimer();

    // Logic for Pomodoro Completion
    if (_mode == FocusMode.work) {
      if (_currentTodoId != null && onPomodoroComplete != null) {
        onPomodoroComplete!(_currentTodoId!);
      }
    }

    // Play sound
    try {
      await _audioPlayer.play(AssetSource('sounds/completion.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }

    // Notify
    String title = 'Session Completed!';
    String body = _mode == FocusMode.work
        ? 'Great job! Take a break.'
        : 'Break is over. Ready to focus?';

    _notificationService.showNotification(title: title, body: body);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _backgroundPlayer.dispose();
    super.dispose();
  }
}
