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
  // Assicura che i binding di Flutter siano inizializzati prima di usare plugin asincroni (es. Firebase)
  WidgetsFlutterBinding.ensureInitialized();
  
  bool firebaseInitialized = false;
  String? firebaseError;
  
  try {
    // Inizializza l'istanza di Firebase con le opzioni specifiche della piattaforma (generate dalla Firebase CLI)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
  } catch (e, stack) {
    // In caso di errore (es. configurazione mancante o assenza di connessione), cattura l'eccezione
    debugPrint("Firebase initialization failed: $e\n$stack");
    firebaseError = e.toString();
  }
  
  // Avvia l'applicazione passando i flag di stato relativi all'inizializzazione di Firebase
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
    // Se Firebase non è stato inizializzato correttamente, mostra una schermata di errore bloccante.
    // L'app non può funzionare senza Firebase.
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
                  // Stampa i dettagli dell'errore per facilitare il debug
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

    // Iniezione delle dipendenze (Dependency Injection) usando MultiProvider.
    // In questo modo i servizi e i Notifier sono accessibili in tutta l'app.
    return MultiProvider(
      providers: [
        // Servizi base (Auth e Database)
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<UserService>(create: (_) => UserService()),
        
        // Notifier per l'allenamento. Dipende da AuthService per conoscere l'ID utente.
        ChangeNotifierProxyProvider<AuthService, WorkoutNotifier>(
          create: (context) => WorkoutNotifier(),
          update: (context, authService, previous) {
            final notifier = previous ?? WorkoutNotifier();
            // Aggiorna l'ID utente nel Notifier ogni volta che lo stato di autenticazione cambia
            notifier.updateUserId(authService.currentFirebaseUser?.uid);
            return notifier;
          },
        ),
        
        // LoginNotifier: gestisce lo stato del login
        ChangeNotifierProxyProvider2<AuthService, UserService, LoginNotifier>(
          create: (context) => LoginNotifier(
            authService: context.read<AuthService>(),
            userService: context.read<UserService>(),
          ),
          update: (context, authService, userService, previous) =>
              previous ?? LoginNotifier(authService: authService, userService: userService),
        ),
        
        // RegisterNotifier: gestisce lo stato e il flusso della registrazione
        ChangeNotifierProxyProvider2<AuthService, UserService, RegisterNotifier>(
          create: (context) => RegisterNotifier(
            authService: context.read<AuthService>(),
            userService: context.read<UserService>(),
          ),
          update: (context, authService, userService, previous) =>
              previous ?? RegisterNotifier(authService: authService, userService: userService),
        ),
        
        // HomeNotifier: carica e gestisce i dati mostrati nella dashboard
        ChangeNotifierProxyProvider2<AuthService, UserService, HomeNotifier>(
          create: (context) => HomeNotifier(
            authService: context.read<AuthService>(),
            userService: context.read<UserService>(),
          ),
          update: (context, authService, userService, previous) =>
              previous ?? HomeNotifier(authService: authService, userService: userService),
        ),
        
        // ProfileNotifier: gestisce il recupero e l'aggiornamento del profilo utente
        ChangeNotifierProxyProvider2<AuthService, UserService, ProfileNotifier>(
          create: (context) => ProfileNotifier(
            authService: context.read<AuthService>(),
            userService: context.read<UserService>(),
          ),
          update: (context, authService, userService, previous) =>
              previous ?? ProfileNotifier(authService: authService, userService: userService),
        ),
      ],
      // Definizione del layout base e delle rotte di navigazione
      child: MaterialApp(
        title: 'GymLog',
        debugShowCheckedModeBanner: false, // Nasconde il banner "DEBUG"
        theme: ThemeData(
          // Combinazione di colori dell'app (bianco/nero stile minimal)
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black,
            primary: Colors.black,
            secondary: Colors.black54,
          ),
          // Tema uniforme per tutti i dialog/popup
          dialogTheme: const DialogThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
          ),
          useMaterial3: true, // Utilizza le componenti aggiornate di Material Design 3
        ),
        // AuthWrapper decide automaticamente se mandare l'utente al Login o alla Home
        home: const AuthWrapper(),
        // Tabella delle rotte (Named Routes) per navigare tra gli schermi
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


/// Widget che funge da entry point di routing dinamico.
/// Ascolta lo stato di autenticazione e instrada l'utente alla schermata appropriata.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    // StreamBuilder resta in ascolto del flusso 'authStateChanges' di Firebase.
    // Ogni volta che l'utente effettua login/logout, il builder viene richiamato.
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Se sta ancora caricando il primo valore, mostra uno spinner circolare.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        }
        
        // Se c'è un utente autenticato (snapshot.hasData è true), va alla Home.
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        
        // Altrimenti, se non c'è sessione, mostra la schermata di Login.
        return const LoginScreen();
      },
    );
  }
}
