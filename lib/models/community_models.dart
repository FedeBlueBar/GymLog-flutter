import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

enum FriendRequestStatus {
  PENDING,
  ACCEPTED,
  REJECTED,
  CANCELLED
}

enum FriendRequestType {
  FRIENDSHIP,
  PT_COACHING
}

class FriendRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final String status;
  final String requestType;
  final int createdAt;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.status = 'PENDING',
    this.requestType = 'FRIENDSHIP',
    required this.createdAt,
  });

  factory FriendRequest.fromMap(Map<String, dynamic> map, String docId) {
    return FriendRequest(
      id: map['id'] ?? docId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      status: map['status'] ?? 'PENDING',
      requestType: map['requestType'] ?? 'FRIENDSHIP',
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status,
      'requestType': requestType,
      'createdAt': createdAt,
    };
  }
}

class Friendship {
  final String id;
  final List<String> users;
  final int createdAt;

  Friendship({
    required this.id,
    required this.users,
    required this.createdAt,
  });

  factory Friendship.fromMap(Map<String, dynamic> map, String docId) {
    return Friendship(
      id: map['id'] ?? docId,
      users: List<String>.from(map['users'] ?? []),
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'users': users,
      'createdAt': createdAt,
    };
  }
}

class PtRelationship {
  final String id;
  final String ptId;
  final String clientId;
  final int createdAt;

  PtRelationship({
    required this.id,
    required this.ptId,
    required this.clientId,
    required this.createdAt,
  });

  factory PtRelationship.fromMap(Map<String, dynamic> map, String docId) {
    return PtRelationship(
      id: map['id'] ?? docId,
      ptId: map['ptId'] ?? '',
      clientId: map['clientId'] ?? '',
      createdAt: map['createdAt'] is num ? (map['createdAt'] as num).toInt() : (map['createdAt']?.millisecondsSinceEpoch ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ptId': ptId,
      'clientId': clientId,
      'createdAt': createdAt,
    };
  }
}

class FriendStats {
  final int workoutsCount;
  final int level;

  FriendStats({
    this.workoutsCount = 0,
    this.level = 1,
  });

  factory FriendStats.fromMap(Map<String, dynamic> map) {
    return FriendStats(
      workoutsCount: (map['workoutsCount'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
    );
  }
}

class IncomingRequestUi {
  final FriendRequest request;
  final UserModel sender;

  IncomingRequestUi({required this.request, required this.sender});
}

class OutgoingRequestUi {
  final FriendRequest request;
  final UserModel receiver;

  OutgoingRequestUi({required this.request, required this.receiver});
}
