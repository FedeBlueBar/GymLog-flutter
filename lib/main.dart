import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymlog_flutter/firebase_options.dart';
import 'package:gymlog_flutter/services/auth_service.dart';
import 'package:gymlog_flutter/services/user_service.dart';
import 'package:gymlog_flutter/notifiers/login_notifier.dart';
import 'package:gymlog_flutter/notifiers/register_notifier.dart';
import 'package:gymlog_flutter/notifiers/home_notifier.dart';
import 'package:gymlog_flutter/notifiers/workout_notifier.dart';
import 'package:gymlog_flutter/notifiers/profile_notifier.dart';
import 'package:gymlog_flutter/screens/login_screen.dart';
import 'package:gymlog_flutter/screens/register_step1_screen.dart';
import 'package:gymlog_flutter/screens/register_step2_screen.dart';
import 'package:gymlog_flutter/screens/google_onboarding_screen.dart';
import 'package:gymlog_flutter/screens/home_screen.dart';
import 'package:gymlog_flutter/screens/profile_screen.dart';
import 'package:gymlog_flutter/screens/workout_screen.dart';
import 'package:gymlog_flutter/screens/placeholder_screen.dart';
import 'package:gymlog_flutter/screens/community_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool firebaseInitialized = false;
  String? firebaseError;
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
  } catch (e, stack) {
    debugPrint("Firebase initialization failed: $e\n$stack");
    firebaseError = e.toString();
  }
  
  runApp(MyApp(
    firebaseInitialized: firebaseInitialized,
    firebaseError: firebaseError,
  ));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  final String? firebaseError;

  const MyApp({
    super.key,
    required this.firebaseInitialized,
    required this.firebaseError,
  });

  @override
  Widget build(BuildContext context) {
    if (!firebaseInitialized) {
      return MaterialApp(
        title: 'GymLog',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          useMaterial3: true,
        ),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 80),
                  const SizedBox(height: 16),
                  const Text(
                    "Errore di Inizializzazione Firebase",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Non è stato possibile connettersi a Firebase. Dettagli errore:\n\n$firebaseError",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<UserService>(create: (_) => UserService()),
        ChangeNotifierProxyProvider<AuthService, WorkoutNotifier>(
          create: (context) => WorkoutNotifier(),
          update: (context, authService, previous) {
            final notifier = previous ?? WorkoutNotifier();
            notifier.updateUserId(authService.currentFirebaseUser?.uid);
            return notifier;
          },
        ),
        ChangeNotifierProxyProvider2<AuthService, UserService, LoginNotifier>(
          create: (context) => LoginNotifier(
            authService: context.read<AuthService>(),
            userService: context.read<UserService>(),
          ),
          update: (context, authService, userService, previous) =>
              previous ?? LoginNotifier(authService: authService, userService: userService),
        ),
        ChangeNotifierProxyProvider2<AuthService, UserService, RegisterNotifier>(
          create: (context) => RegisterNotifier(
            authService: context.read<AuthService>(),
            userService: context.read<UserService>(),
          ),
          update: (context, authService, userService, previous) =>
              previous ?? RegisterNotifier(authService: authService, userService: userService),
        ),
        ChangeNotifierProxyProvider2<AuthService, UserService, HomeNotifier>(
          create: (context) => HomeNotifier(
            authService: context.read<AuthService>(),
            userService: context.read<UserService>(),
          ),
          update: (context, authService, userService, previous) =>
              previous ?? HomeNotifier(authService: authService, userService: userService),
        ),
        ChangeNotifierProxyProvider2<AuthService, UserService, ProfileNotifier>(
          create: (context) => ProfileNotifier(
            authService: context.read<AuthService>(),
            userService: context.read<UserService>(),
          ),
          update: (context, authService, userService, previous) =>
              previous ?? ProfileNotifier(authService: authService, userService: userService),
        ),
      ],
      child: MaterialApp(
        title: 'GymLog',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black,
            primary: Colors.black,
            secondary: Colors.black54,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
          ),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register_step1': (context) => const RegisterStep1Screen(),
          '/register_step2': (context) => const RegisterStep2Screen(),
          '/google_onboarding': (context) => const GoogleOnboardingScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/workout': (context) => const WorkoutScreen(),
          '/diet': (context) => const PlaceholderScreen(title: "Dieta"),
          '/community': (context) => const CommunityScreen(),
          '/progress': (context) => const PlaceholderScreen(title: "Progressi"),
        },
      ),
    );
  }
}


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
