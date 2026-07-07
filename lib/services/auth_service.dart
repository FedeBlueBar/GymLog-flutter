import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Servizio per la gestione dell'autenticazione tramite Firebase Auth e Google Sign-In.
/// Fornisce metodi per la registrazione, l'accesso, il logout e la gestione dell'account.
class AuthService {
  // Istanza principale di FirebaseAuth per interagire con il backend
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Istanza per gestire l'accesso tramite account Google
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Restituisce l'utente attualmente loggato (Firebase User)
  User? get currentFirebaseUser => _auth.currentUser;
  
  /// Restituisce l'utente attualmente loggato (alias per currentFirebaseUser)
  User? get currentUser => _auth.currentUser;
  
  /// Restituisce l'ID univoco (UID) dell'utente attualmente loggato
  String? get currentUserId => _auth.currentUser?.uid;
  
  /// Controlla se c'è un utente correntemente connesso all'applicazione
  bool get isUserLoggedIn => _auth.currentUser != null;

  /// Stream che notifica eventuali cambiamenti nello stato di autenticazione 
  /// (es. login effettuato, logout, sessione scaduta)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Registra un nuovo utente utilizzando email e password.
  /// 
  /// Pulisce eventuali spazi vuoti nell'email prima di passarla a Firebase.
  Future<UserCredential> register(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Effettua l'accesso di un utente esistente utilizzando email e password.
  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Mostra il popup di accesso con Google ed effettua l'accesso a Firebase
  /// utilizzando le credenziali fornite dall'account Google.
  Future<UserCredential?> signInWithGoogle() async {
    // 1. Richiede all'utente di scegliere un account Google
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // L'utente ha annullato l'operazione

    // 2. Ottiene i dettagli di autenticazione (token) dalla sessione Google
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    // 3. Crea le credenziali compatibili con Firebase
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 4. Effettua l'accesso a Firebase con tali credenziali
    return await _auth.signInWithCredential(credential);
  }

  /// Disconnette l'utente dall'applicazione.
  /// Esegue il logout sia da Google Sign-In (se usato) sia da Firebase Auth.
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignora errori se l'utente non era loggato con Google
    }
    await _auth.signOut();
  }

  /// Richiede nuovamente le credenziali all'utente per operazioni sensibili 
  /// (come il cambio password o l'eliminazione dell'account).
  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception("Nessun utente autenticato");
    }
    // Ricrea le credenziali dell'utente utilizzando la password appena inserita
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    // Effettua la ri-autenticazione tramite Firebase
    await user.reauthenticateWithCredential(credential);
  }

  /// Cambia la password dell'utente attualmente connesso.
  /// Solitamente richiede una ri-autenticazione preventiva se l'ultimo login 
  /// è avvenuto da troppo tempo.
  Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Nessun utente autenticato");
    }
    await user.updatePassword(newPassword);
  }

  /// Invia un'email all'indirizzo specificato per consentire all'utente di 
  /// reimpostare la propria password dimenticata.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Elimina definitivamente l'account Firebase dell'utente attualmente connesso.
  /// Come il cambio password, potrebbe richiedere una ri-autenticazione recente.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.delete();
  }
}

