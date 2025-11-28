import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/email_provider.dart';
import 'screens/inbox_screen.dart';
import 'services/oauth_callback_handler.dart';
import 'services/auth_service.dart';
import 'widgets/yahoo_app_password_dialog.dart';

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
class QMailApp extends StatefulWidget {
  /// Creates a new instance of the QMailApp.
  const QMailApp({super.key});

  @override
  State<QMailApp> createState() => _QMailAppState();
}

class _QMailAppState extends State<QMailApp> {
  EmailProvider? _emailProvider;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _setupOAuthCallbackHandler();
  }

  void _setupOAuthCallbackHandler() {
    OAuthCallbackHandler.instance.setCallbacks(
      onAccountAdded: (account) async {
        if (_emailProvider != null) {
          try {
            await _emailProvider!.addAccount(account);

            // For Yahoo accounts, show app password dialog for full email access
            if (account.provider.name == 'yahoo') {
              await _handleYahooAppPasswordSetup(account);
            } else {
              // Show success message for other providers
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Account ${account.email} added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('Failed to add account: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to add account: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      },
      onError: (error) {
        debugPrint('OAuth error: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Authentication failed: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  /// Handles Yahoo App Password setup for full email access
  Future<void> _handleYahooAppPasswordSetup(dynamic account) async {
    try {
      if (!mounted) return;

      // Show the app password dialog
      final appPassword = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => YahooAppPasswordDialog(userEmail: account.email),
      );

      if (appPassword != null && appPassword.isNotEmpty) {
        // Get the Yahoo service and set the app password
        final yahooService = AuthService.getYahooApiService();
        if (yahooService != null) {
          yahooService.setAppPassword(appPassword);

          // Test the IMAP connection
          try {
            // Force a refresh to test the connection and fetch emails
            if (mounted) {
              await _emailProvider?.syncEmails();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Yahoo Mail access enabled for ${account.email}!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('App password connection failed: $e'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      } else {
        // User cancelled - show limited access message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Yahoo account ${account.email} added with limited access. Set up App Password later for full email access.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in Yahoo app password setup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _initializeApp() async {
    // Create and initialize the email provider
    final provider = EmailProvider();
    await provider.initialize();

    if (mounted) {
      setState(() {
        _emailProvider = provider;
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen until provider is initialized
    if (!_isInitialized || _emailProvider == null) {
      return MaterialApp(
        title: 'QMail - Email Client',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('es', 'ES'),
          Locale('fr', 'FR'),
          Locale('de', 'DE'),
        ],
        home: const _SplashScreen(),
      );
    }

    // Use ChangeNotifierProvider with the already-initialized provider
    return ChangeNotifierProvider.value(
      value: _emailProvider!,
      child: MaterialApp(
        title: 'QMail - Email Client',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('es', 'ES'),
          Locale('fr', 'FR'),
          Locale('de', 'DE'),
        ],
        home: const InboxScreen(),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: brightness,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}

/// Splash screen shown while the app initializes
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'QMail',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Smart Email Reader',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading your emails...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}