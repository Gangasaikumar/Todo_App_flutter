import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/todo_provider.dart';
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
      // We cannot programmatically disable notifications, so we guide the user to settings
      openAppSettings();
      // Optimistically update UI, but actual status depends on return
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          const Divider(),
          _buildSectionHeader(context, 'Notifications'),
          SwitchListTile(
            title: const Text('Enable Reminders'),
            subtitle: const Text('Get notified for scheduled tasks'),
            value: _notificationsEnabled,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: _toggleNotifications,
          ),
          const Divider(),
          _buildSectionHeader(context, 'Sound Effects'),
          Consumer<TodoProvider>(
            builder: (context, todoProvider, _) {
              return SwitchListTile(
                title: const Text('Completion Sounds'),
                subtitle: const Text('Play a sound when completing a task'),
                value: todoProvider.soundEnabled,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (value) => todoProvider.toggleSound(),
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
}
