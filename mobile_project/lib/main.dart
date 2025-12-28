import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database/db.dart';
import 'providers/auth_provider.dart';
import 'providers/friends_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/group_provider.dart';
import 'ui/signup.dart';
import 'ui/login.dart';
import 'ui/home.dart';
import 'ui/friends.dart';
import 'ui/settings.dart';
import 'ui/profile.dart';
import 'ui/create_group.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FriendsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
      ],
      child: MaterialApp(
        title: 'ZC Chat App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
          useMaterial3: true,
          // Add smooth page transitions globally
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: _CustomPageTransitionBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.windows: _CustomPageTransitionBuilder(),
              TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.linux: _CustomPageTransitionBuilder(),
            },
          ),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignupPage(),
          '/home': (context) => const HomePage(),
          '/friends': (context) => const FriendsPage(),
          '/settings': (context) => const SettingsPage(),
          '/profile': (context) => const ProfilePage(),
          '/create-group': (context) => const CreateGroupPage(),
        },
      ),
    );
  }
}

/// Custom page transition with combined fade and slide effect
class _CustomPageTransitionBuilder extends PageTransitionsBuilder {
  const _CustomPageTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Use curved animation for smoother feel
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // Combine fade and slide transitions
    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.1, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }
}
