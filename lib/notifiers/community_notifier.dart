// Questo file contiene il Notifier (Controller di stato) per la gestione della Community.
// Agisce da "ponte" tra l'interfaccia utente (UI) e i servizi backend (CommunityService).
// Mantiene aggiornato in tempo reale lo stato di amici, richieste e clienti del Personal Trainer.

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/community_models.dart';
import '../models/user_model.dart';
import '../services/community_service.dart';
import '../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Classe che estende ChangeNotifier per notificare la UI ad ogni cambiamento di stato.
class CommunityNotifier extends ChangeNotifier {
  // Servizi per comunicare con Firebase
  final CommunityService _communityService = CommunityService();
  final UserService _userService = UserService();

  // Dati dell'utente attualmente connesso
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isCurrentUserPt => _currentUser?.isPersonalTrainer == true;

  // Liste degli utenti con cui c'è una relazione consolidata
  List<UserModel> _friends = [];
  List<UserModel> get friends => _friends;

  List<UserModel> _ptClients = [];
  List<UserModel> get ptClients => _ptClients;

  // Liste delle richieste (amicizia/PT) in attesa, arricchite con i dati dell'utente per mostrarli nella UI
  List<IncomingRequestUi> _incomingRequests = [];
  List<IncomingRequestUi> get incomingRequests => _incomingRequests;

  List<OutgoingRequestUi> _outgoingRequests = [];
  List<OutgoingRequestUi> get outgoingRequests => _outgoingRequests;

  // Stato della funzione di ricerca utenti
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<UserModel> _searchResults = [];
  List<UserModel> get searchResults => _searchResults;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  // Gestione messaggi di errore e successo per mostrarli all'utente tramite SnackBar
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  // Mappa delle statistiche (es. allenamenti completati) dei propri amici
  Map<String, FriendStats> _friendStats = {};
  Map<String, FriendStats> get friendStats => _friendStats;

  // Cache interna degli utenti per velocizzare la ricerca
  List<UserModel> _allUsersCache = [];
  bool _hasLoadedUsers = false;

  // Sottoscrizioni agli Stream di Firebase per aggiornamenti in tempo reale
  StreamSubscription? _friendsSub;
  StreamSubscription? _incomingSub;
  StreamSubscription? _outgoingSub;
  StreamSubscription? _clientsSub;
  Timer? _debounce;

  // Al momento della creazione, avvia subito l'inizializzazione dei dati
  CommunityNotifier() {
    _init();
  }

  // Metodo interno di avvio: carica il profilo utente, imposta l'ascolto in tempo reale e prepara la cache
  Future<void> _init() async {
    await _loadCurrentUser();
    _observeAll();
    _loadInitialUsers();
  }

  // Recupera dal database i dati completi dell'utente loggato per sapere se è un PT o un utente standard
  Future<void> _loadCurrentUser() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        _currentUser = await _userService.getUser(uid);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "Errore nel caricamento profilo: $e";
      notifyListeners();
    }
  }

  // Si iscrive a diversi "Stream" per ricevere dal database aggiornamenti in tempo reale
  // (amicizie, richieste in attesa e lista clienti).
  void _observeAll() {
    _friendsSub = _communityService.observeFriendships().listen((_) {
      _refreshFriendsUsers();
    });

    _incomingSub = _communityService.observeIncomingRequests().listen((requests) async {
      List<IncomingRequestUi> enriched = [];
      for (var req in requests) {
        final user = await _communityService.getUser(req.senderId);
        if (user != null) {
          enriched.add(IncomingRequestUi(request: req, sender: user));
        }
      }
      _incomingRequests = enriched;
      notifyListeners();
    });

    _outgoingSub = _communityService.observeOutgoingRequests().listen((requests) async {
      List<OutgoingRequestUi> enriched = [];
      for (var req in requests) {
        final user = await _communityService.getUser(req.receiverId);
        if (user != null) {
          enriched.add(OutgoingRequestUi(request: req, receiver: user));
        }
      }
      _outgoingRequests = enriched;
      notifyListeners();
    });

    _clientsSub = _communityService.observePtClients().listen((_) {
      _refreshPtClients();
    });
  }

  // Aggiorna la lista degli amici scaricando i dati completi (nome, foto) di ciascuno
  Future<void> _refreshFriendsUsers() async {
    try {
      final users = await _communityService.fetchFriendsAsUsers();
      _friends = users;
      notifyListeners();
      _loadStatsFor(users);
    } catch (e) {
    }
  }

  // Aggiorna la lista dei clienti del Personal Trainer scaricando i dati completi
  Future<void> _refreshPtClients() async {
    try {
      final users = await _communityService.fetchPtClientsAsUsers();
      _ptClients = users;
      notifyListeners();
      _loadStatsFor(users);
    } catch (e) {
    }
  }

  // Metodo di utilità per scaricare in modo asincrono le statistiche (livello, numero allenamenti)
  // per una lista specifica di utenti (amici o clienti) e aggiornare la mappa interna
  Future<void> _loadStatsFor(List<UserModel> users) async {
    bool updated = false;
    for (var u in users) {
      if (!_friendStats.containsKey(u.uid)) {
        _friendStats[u.uid] = await _communityService.fetchUserStats(u.uid);
        updated = true;
      }
    }
    if (updated) notifyListeners();
  }

  // Scarica una sola volta TUTTI gli utenti dell'app per popolare una cache locale.
  // Questo permette alla barra di ricerca di essere istantanea senza fare continue chiamate al server.
  Future<void> _loadInitialUsers() async {
    _isSearching = true;
    notifyListeners();
    try {
      final users = await _communityService.getAllUsersForCommunity();
      _allUsersCache = users;
      _hasLoadedUsers = true;
      _updateSearchResults();
    } catch (e) {
      _errorMessage = "Errore nel caricamento utenti";
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // Gestisce l'inserimento di testo nella barra di ricerca usando un "debounce"
  // (aspetta 300ms prima di filtrare per evitare calcoli inutili ad ogni singola lettera digitata)
  void onSearchQueryChange(String query) {
    _searchQuery = query;
    notifyListeners();

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _updateSearchResults();
    });
  }

  // Filtra la cache locale degli utenti in base a nome, cognome o username inseriti
  void _updateSearchResults() {
    final query = _searchQuery.trim().toLowerCase();
    final currentUid = _currentUser?.uid;

    final baseList = _allUsersCache.where((u) => u.uid != currentUid).toList();

    if (query.isEmpty) {
      _searchResults = [];
    } else {
      _searchResults = baseList.where((user) {
        return user.username.toLowerCase().contains(query) ||
            user.nome.toLowerCase().contains(query) ||
            user.cognome.toLowerCase().contains(query);
      }).toList();
    }
    notifyListeners();
  }

  // Funzione "wrapper" (involucro) per eseguire comandi complessi gestendo automaticamente:
  // 1. Mostrare/nascondere il caricamento
  // 2. Impostare un messaggio di successo
  // 3. Catturare ed esporre eventuali errori
  Future<void> _runOnVm(Future<void> Function() block, String successMsg) async {
    _isLoading = true;
    notifyListeners();
    try {
      await block();
      _successMessage = successMsg;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Invia una richiesta di amicizia standard a un altro utente
  Future<void> sendFriendshipRequest(String receiverUid) async {
    await _runOnVm(() => _communityService.sendFriendRequest(receiverUid, FriendRequestType.FRIENDSHIP.name), "Richiesta amicizia inviata");
  }

  // Invia una richiesta di affiancamento da Personal Trainer
  Future<void> sendPtCoachingRequest(String receiverUid) async {
    await _runOnVm(() => _communityService.sendFriendRequest(receiverUid, FriendRequestType.PT_COACHING.name), "Richiesta coaching inviata");
  }

  // Accetta una richiesta (amicizia o coaching) in entrata
  Future<void> acceptRequest(String requestId) async {
    await _runOnVm(() => _communityService.acceptFriendRequest(requestId), "Richiesta accettata");
  }

  // Rifiuta una richiesta in entrata
  Future<void> rejectRequest(String requestId) async {
    await _runOnVm(() => _communityService.rejectFriendRequest(requestId), "Richiesta rifiutata");
  }

  // Annulla una richiesta precedentemente inviata ma non ancora accettata
  Future<void> cancelRequest(String requestId) async {
    await _runOnVm(() => _communityService.cancelFriendRequest(requestId), "Richiesta annullata");
  }

  // Rimuove un amico consolidato dalla propria lista
  Future<void> removeFriend(String friendUid) async {
    await _runOnVm(() => _communityService.removeFriend(friendUid), "Amicizia rimossa");
  }

  // Rimuove un cliente dalla lista di coaching di un Personal Trainer
  Future<void> removePtClient(String clientUid) async {
    await _runOnVm(() => _communityService.removePtClient(clientUid), "Cliente rimosso");
  }

  // Pulisce i messaggi temporanei per evitare che vecchi popup riappaiano
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // Chiude tutte le connessioni in tempo reale al database per evitare sprechi di memoria
  @override
  void dispose() {
    _friendsSub?.cancel();
    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    _clientsSub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }
}
