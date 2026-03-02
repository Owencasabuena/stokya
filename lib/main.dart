import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as app;
import 'providers/inventory_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

/// Entry point for the Stokya inventory management app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const StokyaApp());
}

class StokyaApp extends StatelessWidget {
  const StokyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app.AuthProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return ShadApp.material(
            title: 'Stokya',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ShadThemeData(
              brightness: Brightness.light,
              colorScheme: const ShadSlateColorScheme.light(),
            ),
            darkTheme: ShadThemeData(
              brightness: Brightness.dark,
              colorScheme: const ShadSlateColorScheme.dark(),
            ),
            materialThemeBuilder: (context, theme) {
              final isDark = themeProvider.isDarkMode;
              return theme.copyWith(
                scaffoldBackgroundColor:
                    isDark ? const Color(0xFF0A0A0B) : const Color(0xFFF8F9FA),
                appBarTheme: AppBarTheme(
                  backgroundColor:
                      isDark ? const Color(0xFF0A0A0B) : Colors.white,
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  titleTextStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              );
            },
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

/// Listens to auth state and redirects to Login or Home accordingly.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<app.AuthProvider>();

    if (authProvider.isAuthenticated) {
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}
