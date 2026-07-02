import 'package:flutter/material.dart';
import '../models/community_models.dart';
import '../models/user_model.dart';
import 'package:provider/provider.dart';
import '../notifiers/community_notifier.dart';

class FriendsTab extends StatelessWidget {
  final List<UserModel> friends;
  final Map<String, FriendStats> stats;
  final Function(String) onRemove;

  const FriendsTab({
    Key? key,
    required this.friends,
    required this.stats,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return const Center(
        child: Text("Non hai ancora aggiunto amici.", style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final f = friends[index];
        final stat = stats[f.uid] ?? FriendStats();
        return _buildUserCard(f, stat, () => onRemove(f.uid), "Rimuovi");
      },
    );
  }

  Widget _buildUserCard(UserModel user, FriendStats stat, VoidCallback onAction, String actionText) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F5F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05), width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
            backgroundColor: Colors.grey.shade300,
            child: user.photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${user.nome} ${user.cognome}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("@${user.username}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text("${stat.workoutsCount} Allenamenti", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_remove, color: Colors.black54),
            onPressed: onAction,
            tooltip: actionText,
          )
        ],
      ),
    );
  }
}

class PtClientsTab extends StatelessWidget {
  final List<UserModel> clients;
  final Map<String, FriendStats> stats;
  final Function(String) onRemove;
  final Function(String, String) onCreateWorkout;

  const PtClientsTab({
    Key? key,
    required this.clients,
    required this.stats,
    required this.onRemove,
    required this.onCreateWorkout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) {
      return const Center(
        child: Text("Non hai ancora nessun cliente.", style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clients.length,
      itemBuilder: (context, index) {
        final c = clients[index];
        final stat = stats[c.uid] ?? FriendStats();
        return _buildClientCard(c, stat);
      },
    );
  }

  Widget _buildClientCard(UserModel user, FriendStats stat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F5F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05), width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                backgroundColor: Colors.grey.shade300,
                child: user.photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${user.nome} ${user.cognome}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("@${user.username}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text("Obiettivo: ${user.obiettivo}", style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: () => onRemove(user.uid),
              )
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE67E22),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => onCreateWorkout(user.uid, "${user.nome} ${user.cognome}"),
              child: const Text("Crea Scheda di Allenamento"),
            ),
          )
        ],
      ),
    );
  }
}

class RequestsTab extends StatefulWidget {
  final List<IncomingRequestUi> incoming;
  final List<OutgoingRequestUi> outgoing;
  final Function(String) onAccept;
  final Function(String) onReject;
  final Function(String) onCancel;

  const RequestsTab({
    Key? key,
    required this.incoming,
    required this.outgoing,
    required this.onAccept,
    required this.onReject,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> {
  bool _isIncomingSelected = true;

  @override
  Widget build(BuildContext context) {
    final list = _isIncomingSelected ? widget.incoming : widget.outgoing;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isIncomingSelected = true),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: _isIncomingSelected ? const Color(0xFF1C1C1E) : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "In entrata (${widget.incoming.length})",
                      style: TextStyle(
                        color: _isIncomingSelected ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isIncomingSelected = false),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: !_isIncomingSelected ? const Color(0xFF1C1C1E) : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "In uscita (${widget.outgoing.length})",
                      style: TextStyle(
                        color: !_isIncomingSelected ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Text("Nessuna richiesta", style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    if (_isIncomingSelected) {
                      return _buildIncomingCard(list[index] as IncomingRequestUi);
                    } else {
                      return _buildOutgoingCard(list[index] as OutgoingRequestUi);
                    }
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildIncomingCard(IncomingRequestUi req) {
    final typeText = req.request.requestType == FriendRequestType.PT_COACHING.name
        ? "Ti ha richiesto come Personal Trainer"
        : "Ti ha inviato una richiesta di amicizia";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F5F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: req.sender.photoUrl.isNotEmpty ? NetworkImage(req.sender.photoUrl) : null,
                backgroundColor: Colors.grey.shade300,
                child: req.sender.photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${req.sender.nome} ${req.sender.cognome}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("@${req.sender.username}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(typeText, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.black.withOpacity(0.2)),
                  ),
                  onPressed: () => widget.onReject(req.request.id),
                  child: const Text("Rifiuta"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE67E22),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => widget.onAccept(req.request.id),
                  child: const Text("Accetta"),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildOutgoingCard(OutgoingRequestUi req) {
    final typeText = req.request.requestType == FriendRequestType.PT_COACHING.name
        ? "Richiesta coaching inviata"
        : "Richiesta di amicizia inviata";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F5F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05), width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: req.receiver.photoUrl.isNotEmpty ? NetworkImage(req.receiver.photoUrl) : null,
            backgroundColor: Colors.grey.shade300,
            child: req.receiver.photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${req.receiver.nome} ${req.receiver.cognome}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(typeText, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: Colors.black54),
            onPressed: () => widget.onCancel(req.request.id),
            tooltip: "Annulla richiesta",
          )
        ],
      ),
    );
  }
}

class SearchTab extends StatelessWidget {
  final String query;
  final Function(String) onQueryChange;
  final List<UserModel> results;
  final bool isSearching;
  final UserModel? currentUser;
  final List<UserModel> friends;
  final Function(String) onSendFriend;
  final Function(String) onSendCoaching;

  const SearchTab({
    Key? key,
    required this.query,
    required this.onQueryChange,
    required this.results,
    required this.isSearching,
    required this.currentUser,
    required this.friends,
    required this.onSendFriend,
    required this.onSendCoaching,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: onQueryChange,
            decoration: InputDecoration(
              hintText: "Cerca utenti per nome o username...",
              prefixIcon: const Icon(Icons.search, color: Colors.black),
              filled: true,
              fillColor: const Color(0xFFF6F5F8),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
              ),
            ),
          ),
        ),
        if (isSearching)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: Colors.black),
          )
        else if (results.isEmpty && query.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Nessun utente trovato.", style: TextStyle(color: Colors.grey)),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                return _buildSearchResult(results[index], context);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResult(UserModel user, BuildContext context) {
    final bool isFriend = friends.any((f) => f.uid == user.uid);
    final bool hasThisPt = currentUser?.hasPersonalTrainer == user.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F5F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05), width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                backgroundColor: Colors.grey.shade300,
                child: user.photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${user.nome} ${user.cognome}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("@${user.username}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    if (user.isPersonalTrainer)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text("PT", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (isFriend)
                const Expanded(
                  child: Center(
                    child: Text(
                      "Già amico",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              else
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text("Amico"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.black.withOpacity(0.2)),
                    ),
                    onPressed: () => onSendFriend(user.uid),
                  ),
                ),
              if (user.isPersonalTrainer && !(currentUser?.isPersonalTrainer ?? false)) ...[
                const SizedBox(width: 8),
                if (hasThisPt)
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Sei già seguito",
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.fitness_center, size: 16),
                      label: const Text("Richiedi PT", style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE67E22),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => onSendCoaching(user.uid),
                    ),
                  )
              ]
            ],
          )
        ],
      ),
    );
  }
}
