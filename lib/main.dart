import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/email_provider.dart';
import 'screens/inbox_screen.dart';

/// The main entry point of the QMail application.
///
/// This function initializes the Flutter binding and runs the [QMailApp].
void main() async {
  // Ensure that the Flutter binding is initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();
  // Run the QMail application.
  runApp(const QMailApp());
}

/// The root widget of the QMail application.
///
/// This widget sets up the entire application, including the theme,
/// state management, and initial screen.
class QMailApp extends StatelessWidget {
  /// Creates a new instance of the QMailApp.
  const QMailApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use ChangeNotifierProvider to manage the application's state.
    // The EmailProvider is created and initialized here.
    return ChangeNotifierProvider(
      create: (context) => EmailProvider()..initialize(),
      child: MaterialApp(
        title: 'QMail - Email Client',
        debugShowCheckedModeBanner: false,
        // Define the light theme for the application.
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        // Define the dark theme for the application.
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        // Use the system's theme mode (light or dark).
        themeMode: ThemeMode.system,
        // Set the initial screen of the application to the InboxScreen.
        home: const InboxScreen(),
      ),
    );
  }
}