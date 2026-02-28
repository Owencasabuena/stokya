import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as app;
import 'providers/inventory_provider.dart';
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
      ],
      child: ShadApp.material(
        title: 'Stokya',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ShadThemeData(
          brightness: Brightness.dark,
          colorScheme: const ShadSlateColorScheme.dark(),
        ),
        materialThemeBuilder: (context, theme) {
          return theme.copyWith(
            scaffoldBackgroundColor: const Color(0xFF0A0A0B),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0A0A0B),
              foregroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          );
        },
        home: const _AuthGate(),
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
