import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/todo_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/focus_provider.dart';
import 'utils/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TodoProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FocusProvider()),
      ],
      child: Builder(
        builder: (context) {
          // Link Providers
          final focusProvider = Provider.of<FocusProvider>(
            context,
            listen: false,
          );
          final todoProvider = Provider.of<TodoProvider>(
            context,
            listen: false,
          );
          focusProvider.onPomodoroComplete = (id) {
            todoProvider.incrementCompletedPomodoros(id);
          };

          return Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return MaterialApp(
                title: 'My Todo App',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeProvider.themeMode,
                home: const SplashScreen(),
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  FlutterQuillLocalizations.delegate,
                ],
                supportedLocales: const [Locale('en', 'US')],
              );
            },
          );
        },
      ),
    );
  }
}
