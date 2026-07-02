import 'dart:async';
import 'package:flutter/material.dart';
import '../models/community_models.dart';
import '../models/user_model.dart';
import '../services/community_service.dart';
import '../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityNotifier extends ChangeNotifier {
  final CommunityService _communityService = CommunityService();
  final UserService _userService = UserService();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool get isCurrentUserPt => _currentUser?.isPersonalTrainer == true;

  List<UserModel> _friends = [];
  List<UserModel> get friends => _friends;

  List<UserModel> _ptClients = [];
  List<UserModel> get ptClients => _ptClients;

  List<IncomingRequestUi> _incomingRequests = [];
  List<IncomingRequestUi> get incomingRequests => _incomingRequests;

  List<OutgoingRequestUi> _outgoingRequests = [];
  List<OutgoingRequestUi> get outgoingRequests => _outgoingRequests;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<UserModel> _searchResults = [];
  List<UserModel> get searchResults => _searchResults;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  Map<String, FriendStats> _friendStats = {};
  Map<String, FriendStats> get friendStats => _friendStats;

  List<UserModel> _allUsersCache = [];
  bool _hasLoadedUsers = false;

  StreamSubscription? _friendsSub;
  StreamSubscription? _incomingSub;
  StreamSubscription? _outgoingSub;
  StreamSubscription? _clientsSub;
  Timer? _debounce;

  CommunityNotifier() {
    _init();
  }

  Future<void> _init() async {
    await _loadCurrentUser();
    _observeAll();
    _loadInitialUsers();
  }

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

  Future<void> _refreshFriendsUsers() async {
    try {
      final users = await _communityService.fetchFriendsAsUsers();
      _friends = users;
      notifyListeners();
      _loadStatsFor(users);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _refreshPtClients() async {
    try {
      final users = await _communityService.fetchPtClientsAsUsers();
      _ptClients = users;
      notifyListeners();
      _loadStatsFor(users);
    } catch (e) {
      // Handle error
    }
  }

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

  void onSearchQueryChange(String query) {
    _searchQuery = query;
    notifyListeners();

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _updateSearchResults();
    });
  }

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

  Future<void> sendFriendshipRequest(String receiverUid) async {
    await _runOnVm(() => _communityService.sendFriendRequest(receiverUid, FriendRequestType.FRIENDSHIP.name), "Richiesta amicizia inviata");
  }

  Future<void> sendPtCoachingRequest(String receiverUid) async {
    await _runOnVm(() => _communityService.sendFriendRequest(receiverUid, FriendRequestType.PT_COACHING.name), "Richiesta coaching inviata");
  }

  Future<void> acceptRequest(String requestId) async {
    await _runOnVm(() => _communityService.acceptFriendRequest(requestId), "Richiesta accettata");
  }

  Future<void> rejectRequest(String requestId) async {
    await _runOnVm(() => _communityService.rejectFriendRequest(requestId), "Richiesta rifiutata");
  }

  Future<void> cancelRequest(String requestId) async {
    await _runOnVm(() => _communityService.cancelFriendRequest(requestId), "Richiesta annullata");
  }

  Future<void> removeFriend(String friendUid) async {
    await _runOnVm(() => _communityService.removeFriend(friendUid), "Amicizia rimossa");
  }

  Future<void> removePtClient(String clientUid) async {
    await _runOnVm(() => _communityService.removePtClient(clientUid), "Cliente rimosso");
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

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
