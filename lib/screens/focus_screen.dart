import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/focus_provider.dart';

class FocusScreen extends StatefulWidget {
  final String? taskTitle;
  final String? todoId;

  const FocusScreen({super.key, this.taskTitle, this.todoId});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.todoId != null) {
      // Delay to ensure provider is available and avoid build conflicts
      Future.microtask(() {
        Provider.of<FocusProvider>(
          context,
          listen: false,
        ).startWorkSession(widget.todoId);
      });
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds / 60).floor();
    final remainingSeconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final focusProvider = Provider.of<FocusProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color getStatusColor() {
      switch (focusProvider.mode) {
        case FocusMode.work:
          return Colors.redAccent;
        case FocusMode.shortBreak:
          return isDark
              ? Colors.tealAccent
              : Colors.teal; // Darker teal for Light Mode
        case FocusMode.longBreak:
          return Colors.blueAccent;
      }
    }

    final statusColor = getStatusColor();
    // In dark mode, lighter status color. In light mode, slightly darker for readability on white/grey?
    // Actually, keeping vibrant colors is better for Focus apps.

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Focus Mode'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Mode Toggles
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildModeTab(context, FocusMode.work, 'Work', focusProvider),
                  _buildModeTab(
                    context,
                    FocusMode.shortBreak,
                    'Short Break',
                    focusProvider,
                  ),
                  _buildModeTab(
                    context,
                    FocusMode.longBreak,
                    'Long Break',
                    focusProvider,
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Digital Clock
                  Text(
                    _formatTime(focusProvider.currentDuration),
                    style: TextStyle(
                      fontSize: 100, // HUGE FONT
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      // tabularFigures ensures numbers don't jump around
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    focusProvider.timerState == TimerState.running
                        ? 'FOCUS'
                        : 'READY?',
                    style: TextStyle(
                      fontSize: 20,
                      letterSpacing: 4,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.6,
                      ),
                    ),
                  ),
                  if (widget.taskTitle != null) ...[
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, color: statusColor),
                          const SizedBox(width: 8),
                          Text(
                            widget.taskTitle!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Controls
            Container(
              padding: const EdgeInsets.only(bottom: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (focusProvider.timerState == TimerState.running)
                    _buildControlButton(
                      context,
                      icon: Icons.pause_rounded,
                      color: isDark ? Colors.grey[800]! : Colors.white,
                      iconColor: statusColor,
                      onPressed: focusProvider.pauseTimer,
                      size: 80,
                    )
                  else
                    _buildControlButton(
                      context,
                      icon: Icons.play_arrow_rounded,
                      color: statusColor,
                      iconColor: Colors.white,
                      onPressed: focusProvider.startTimer,
                      size: 90, // Slightly bigger for Play
                    ),

                  // Stop Button is secondary
                  if (focusProvider.timerState != TimerState.initial) ...[
                    const SizedBox(width: 20),
                    _buildControlButton(
                      context,
                      icon: Icons.stop_rounded,
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                      iconColor: Colors.grey,
                      onPressed: focusProvider.stopTimer,
                      size: 60,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(
    BuildContext context,
    FocusMode mode,
    String label,
    FocusProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = provider.mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? colorScheme.primary : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onPressed,
    required double size,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: size * 0.4),
      ),
    );
  }
}
