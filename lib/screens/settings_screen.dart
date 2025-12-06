import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/todo_provider.dart';
import '../providers/focus_provider.dart';
import '../services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final status = await Permission.notification.status;
    setState(() {
      _notificationsEnabled = status.isGranted;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final granted = await AppNotificationService().requestPermissions();
      setState(() {
        _notificationsEnabled = granted;
      });
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable notifications in system settings'),
          ),
        );
        openAppSettings();
      }
    } else {
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Helper for elevated cards
    Widget buildElevatedCard({required Widget child}) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 6, // High elevation for drop shadow
        shadowColor: Colors.black54, // Darker shadow
        color: Theme.of(context).cardColor, // Opaque
        surfaceTintColor: Colors.transparent, // Avoid tint washing out color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: child,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'Appearance'),
          _buildThemeSelector(context, themeProvider),
          _buildSectionHeader(context, 'Notifications'),
          buildElevatedCard(
            child: SwitchListTile(
              title: const Text('Enable Reminders'),
              subtitle: const Text('Get notified for scheduled tasks'),
              value: _notificationsEnabled,
              activeThumbColor: Theme.of(context).colorScheme.primary,
              onChanged: _toggleNotifications,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          _buildSectionHeader(context, 'Sound Effects'),
          Consumer<TodoProvider>(
            builder: (context, todoProvider, _) {
              return buildElevatedCard(
                child: SwitchListTile(
                  title: const Text('Completion Sounds'),
                  subtitle: const Text('Play a sound when completing a task'),
                  value: todoProvider.soundEnabled,
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  onChanged: (value) => todoProvider.toggleSound(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            },
          ),
          _buildSectionHeader(context, 'Focus & Pomodoro'),
          Consumer2<TodoProvider, FocusProvider>(
            builder: (context, todoProvider, focusProvider, _) {
              return buildElevatedCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Focus Duration
                      _buildSliderSection(
                        context,
                        title: 'Focus Duration',
                        value: todoProvider.focusDurationMinutes.toDouble(),
                        min: 15,
                        max: 60,
                        divisions: 9,
                        label: '${todoProvider.focusDurationMinutes} min',
                        icon: Icons.timer_outlined,
                        onChanged: (val) {
                          final newMin = val.toInt();
                          todoProvider.updateFocusSettings(
                            newMin,
                            todoProvider.dailyGoalHours,
                          );
                          focusProvider.updateSettings(newMin);
                        },
                      ),
                      const SizedBox(height: 24),
                      // Short Break
                      _buildSliderSection(
                        context,
                        title: 'Short Break',
                        value: focusProvider.shortBreakMinutes.toDouble(),
                        min: 1,
                        max: 15,
                        divisions: 14,
                        label: '${focusProvider.shortBreakMinutes} min',
                        icon: Icons.coffee,
                        onChanged: (val) {
                          focusProvider.updateBreakSettings(
                            val.toInt(),
                            focusProvider.longBreakMinutes,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Long Break
                      _buildSliderSection(
                        context,
                        title: 'Long Break',
                        value: focusProvider.longBreakMinutes.toDouble(),
                        min: 5,
                        max: 45,
                        divisions: 8,
                        label: '${focusProvider.longBreakMinutes} min',
                        icon: Icons.schedule,
                        onChanged: (val) {
                          focusProvider.updateBreakSettings(
                            focusProvider.shortBreakMinutes,
                            val.toInt(),
                          );
                        },
                      ),
                      const Divider(height: 48, thickness: 1),
                      // Daily Goal
                      Row(
                        children: [
                          Icon(
                            Icons.flag_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Daily Goal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              '${todoProvider.dailyGoalHours}h',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Target: ${todoProvider.dailyPomodoroCapacity} sessions',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 14,
                          activeTrackColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          inactiveTrackColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.2),
                          thumbColor: Theme.of(context).colorScheme.surface,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 14,
                            elevation: 4,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 26,
                          ),
                          tickMarkShape: const RoundSliderTickMarkShape(
                            tickMarkRadius: 4,
                          ),
                          activeTickMarkColor: Colors.white.withOpacity(0.8),
                          inactiveTickMarkColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                          valueIndicatorShape:
                              const PaddleSliderValueIndicatorShape(),
                        ),
                        child: Slider(
                          value: todoProvider.dailyGoalHours.toDouble(),
                          min: 1,
                          max: 12,
                          divisions: 11,
                          label: '${todoProvider.dailyGoalHours} hours',
                          onChanged: (val) {
                            todoProvider.updateFocusSettings(
                              todoProvider.focusDurationMinutes,
                              val.toInt(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'About'),
          ListTile(
            title: const Text('Version'),
            trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
          ),
          ListTile(
            title: const Text('Developer'),
            subtitle: const Text('Gangasaikumar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, ThemeProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildThemeTab(
            context,
            provider,
            ThemeMode.system,
            Icons.brightness_auto,
            'System',
          ),
          _buildThemeTab(
            context,
            provider,
            ThemeMode.light,
            Icons.light_mode,
            'Light',
          ),
          _buildThemeTab(
            context,
            provider,
            ThemeMode.dark,
            Icons.dark_mode,
            'Dark',
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTab(
    BuildContext context,
    ThemeProvider provider,
    ThemeMode mode,
    IconData icon,
    String label,
  ) {
    final isSelected = provider.themeMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.black
                    : Theme.of(context).iconTheme.color,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.black
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderSection(
    BuildContext context, {
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 14,
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.primary.withOpacity(
              0.2,
            ), // Lighter shade of primary for background
            thumbColor: theme.colorScheme.surface,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 14,
              elevation: 4,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 26),
            tickMarkShape: const RoundSliderTickMarkShape(
              tickMarkRadius: 4,
            ), // Visible ticks for "stepper" look
            activeTickMarkColor: Colors.white.withOpacity(0.8),
            inactiveTickMarkColor: theme.colorScheme.primary.withOpacity(0.3),
            valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: label,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
