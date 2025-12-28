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
        title: 'ChatApp',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
          useMaterial3: true,
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
