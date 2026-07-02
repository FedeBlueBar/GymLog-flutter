import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_models.dart';
import '../models/user_model.dart';

class CommunityService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _friendshipsCol => _db.collection('friends');
  CollectionReference get _requestsCol => _db.collection('friend_requests');
  CollectionReference get _usersCol => _db.collection('users');

  String? get _currentUid => _auth.currentUser?.uid;

  String _friendshipId(String a, String b) {
    return a.compareTo(b) < 0 ? '${a}_$b' : '${b}_$a';
  }

  String _requestId(String sender, String receiver) => '${sender}_$receiver';

  String _ptRelationshipId(String ptId, String clientId) => '${ptId}_$clientId';

  Stream<List<Friendship>> observeFriendships() {
    final uid = _currentUid;
    if (uid == null) return Stream.value([]);

    return _friendshipsCol
        .where('users', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Friendship.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<List<UserModel>> fetchFriendsAsUsers() async {
    final uid = _currentUid;
    if (uid == null) throw Exception("Non autenticato");

    final snapshot = await _friendshipsCol.where('users', arrayContains: uid).get();
    
    List<String> friendUids = [];
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final users = List<String>.from(data['users'] ?? []);
      final friendId = users.firstWhere((id) => id != uid, orElse: () => "");
      if (friendId.isNotEmpty) friendUids.add(friendId);
    }

    if (friendUids.isEmpty) return [];

    return await _fetchUsersByIds(friendUids);
  }

  Future<List<UserModel>> _fetchUsersByIds(List<String> uids) async {
    List<UserModel> users = [];
    for (var i = 0; i < uids.length; i += 10) {
      final chunk = uids.sublist(i, i + 10 > uids.length ? uids.length : i + 10);
      final snapshot = await _usersCol.where(FieldPath.documentId, whereIn: chunk).get();
      users.addAll(snapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)));
    }
    return users;
  }

  Future<void> removeFriend(String friendUid) async {
    final uid = _currentUid;
    if (uid == null) throw Exception("Non autenticato");
    await _friendshipsCol.doc(_friendshipId(uid, friendUid)).delete();
  }

  Stream<List<FriendRequest>> observeIncomingRequests() {
    final uid = _currentUid;
    if (uid == null) return Stream.value([]);

    return _requestsCol
        .where('receiverId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => FriendRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((req) => req.status == FriendRequestStatus.PENDING.name)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<FriendRequest>> observeOutgoingRequests() {
    final uid = _currentUid;
    if (uid == null) return Stream.value([]);

    return _requestsCol
        .where('senderId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => FriendRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((req) => req.status == FriendRequestStatus.PENDING.name)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> sendFriendRequest(String receiverId, String requestType) async {
    final uid = _currentUid;
    if (uid == null) throw Exception("Non autenticato");
    if (uid == receiverId) throw Exception("Non puoi inviare una richiesta a te stesso");

    final friendshipDoc = await _friendshipsCol.doc(_friendshipId(uid, receiverId)).get();
    if (friendshipDoc.exists && requestType == FriendRequestType.FRIENDSHIP.name) {
      throw Exception("Siete già amici");
    }

    final existing = await _requestsCol.doc(_requestId(uid, receiverId)).get();
    if (existing.exists && (existing.data() as Map<String, dynamic>)['status'] == FriendRequestStatus.PENDING.name) {
      throw Exception("Richiesta già inviata");
    }

    final opposite = await _requestsCol.doc(_requestId(receiverId, uid)).get();
    if (opposite.exists && (opposite.data() as Map<String, dynamic>)['status'] == FriendRequestStatus.PENDING.name) {
      throw Exception("Esiste già una richiesta pendente tra voi");
    }

    if (requestType == FriendRequestType.PT_COACHING.name) {
      final receiverDoc = await _usersCol.doc(receiverId).get();
      if (!receiverDoc.exists) throw Exception("Utente non trovato");
      
      final receiverData = receiverDoc.data() as Map<String, dynamic>;
      final isPt = receiverData['personalTrainer'] ?? false;
      if (!isPt) throw Exception("Puoi inviare questa richiesta solo a un personal trainer");
      
      final senderDoc = await _usersCol.doc(uid).get();
      final senderData = senderDoc.data() as Map<String, dynamic>?;
      final hasPt = senderData?['hasPersonalTrainer'];
      final hasPtStr = hasPt?.toString().trim() ?? '';
      if (hasPtStr.isNotEmpty && hasPtStr != 'null' && hasPtStr.toLowerCase() != 'false') {
        // Auto-riparazione: verifichiamo che l'utente sia effettivamente nella lista clienti del PT
        final verifyClientDoc = await _usersCol.doc(hasPtStr).collection('clients').doc(uid).get();
        if (verifyClientDoc.exists) {
          final ptDoc = await _usersCol.doc(hasPtStr).get();
          final ptData = ptDoc.data() as Map<String, dynamic>?;
          final ptName = ptData?['nome'] ?? hasPtStr;
          throw Exception("Risulti già seguito dal personal trainer: $ptName. Devi farti rimuovere prima di richiederne un altro.");
        } else {
          // Il database era disallineato (forse un vecchio PT rimosso male). Ripuliamo il campo e procediamo.
          await _usersCol.doc(uid).update({'hasPersonalTrainer': FieldValue.delete()});
        }
      }
      
      final existingClientDoc = await _usersCol.doc(receiverId).collection('clients').doc(uid).get();
      if (existingClientDoc.exists) {
        throw Exception("Sei già seguito da questo personal trainer");
      }
    }

    final newReq = FriendRequest(
      id: _requestId(uid, receiverId),
      senderId: uid,
      receiverId: receiverId,
      status: FriendRequestStatus.PENDING.name,
      requestType: requestType,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _requestsCol.doc(newReq.id).set(newReq.toMap());
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final docRef = _requestsCol.doc(requestId);
    final doc = await docRef.get();
    if (!doc.exists) throw Exception("Richiesta non trovata");

    final req = FriendRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    
    if (req.requestType == FriendRequestType.FRIENDSHIP.name) {
      final friendship = Friendship(
        id: _friendshipId(req.senderId, req.receiverId),
        users: [req.senderId, req.receiverId],
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _friendshipsCol.doc(friendship.id).set(friendship.toMap());
    } else if (req.requestType == FriendRequestType.PT_COACHING.name) {
      final rel = PtRelationship(
        id: _ptRelationshipId(req.receiverId, req.senderId),
        ptId: req.receiverId,
        clientId: req.senderId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _usersCol.doc(req.receiverId).collection('clients').doc(req.senderId).set(rel.toMap());
      await _usersCol.doc(req.senderId).update({'hasPersonalTrainer': req.receiverId});
    }

    await docRef.update({'status': FriendRequestStatus.ACCEPTED.name});
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _requestsCol.doc(requestId).update({'status': FriendRequestStatus.REJECTED.name});
  }

  Future<void> cancelFriendRequest(String requestId) async {
    await _requestsCol.doc(requestId).update({'status': FriendRequestStatus.CANCELLED.name});
  }

  Stream<List<PtRelationship>> observePtClients() {
    final uid = _currentUid;
    if (uid == null) return Stream.value([]);

    return _usersCol.doc(uid).collection('clients').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => PtRelationship.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<List<UserModel>> fetchPtClientsAsUsers() async {
    final uid = _currentUid;
    if (uid == null) throw Exception("Non autenticato");

    final snapshot = await _usersCol.doc(uid).collection('clients').get();
    List<String> clientUids = snapshot.docs.map((doc) => doc.id).toList();

    if (clientUids.isEmpty) return [];
    return await _fetchUsersByIds(clientUids);
  }

  Future<void> removePtClient(String clientUid) async {
    final uid = _currentUid;
    if (uid == null) throw Exception("Non autenticato");

    await _usersCol.doc(uid).collection('clients').doc(clientUid).delete();
    await _usersCol.doc(clientUid).update({'hasPersonalTrainer': FieldValue.delete()});
  }

  Future<List<UserModel>> getAllUsersForCommunity() async {
    final snapshot = await _usersCol.get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersCol.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<FriendStats> fetchUserStats(String uid) async {
    final workoutsSnap = await _usersCol.doc(uid).collection('workouts').get();
    int count = workoutsSnap.docs.length;
    int level = (count / 5).floor() + 1; 
    return FriendStats(workoutsCount: count, level: level);
  }
}
