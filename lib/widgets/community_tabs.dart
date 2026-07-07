import 'package:flutter/material.dart';
import '../models/community_models.dart';
import '../models/user_model.dart';
import 'package:provider/provider.dart';
import '../notifiers/community_notifier.dart';

/// Tab che mostra la lista degli amici dell'utente.
class FriendsTab extends StatelessWidget {
  /// Lista degli amici (istanze di UserModel).
  final List<UserModel> friends;
  /// Statistiche degli amici (es. numero di allenamenti).
  final Map<String, FriendStats> stats;
  
  /// Callback per rimuovere un amico.
  final Function(String) onRemove;

  const FriendsTab({
    Key? key,
    required this.friends,
    required this.stats,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Se la lista amici è vuota, mostra un messaggio di fallback centrato.
    if (friends.isEmpty) {
      return const Center(
        child: Text("Non hai ancora aggiunto amici.", style: TextStyle(color: Colors.grey)),
      );
    }
    // Altrimenti, usa una ListView per mostrare la lista degli amici
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        // Estrae l'amico corrente
        final f = friends[index];
        // Estrae le statistiche corrispondenti o usa un oggetto vuoto di default
        final stat = stats[f.uid] ?? FriendStats();
        // Costruisce la UI della card usando il metodo helper
        return _buildUserCard(f, stat, () => onRemove(f.uid), "Rimuovi");
      },
    );
  }

  /// Costruisce una singola card utente (usata sia per amici che in altri contesti se necessario).
  Widget _buildUserCard(UserModel user, FriendStats stat, VoidCallback onAction, String actionText) {
    return Container(
      // Margine tra una card e l'altra
      margin: const EdgeInsets.only(bottom: 12),
      // Padding interno per distanziare il contenuto dai bordi
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F5F8), // Colore di sfondo grigio chiaro
        borderRadius: BorderRadius.circular(12), // Bordi arrotondati
        border: Border.all(color: Colors.black.withOpacity(0.05), width: 0.5), // Bordo sottile
      ),
      child: Row(
        children: [
          // Immagine del profilo o icona di default se assente
          CircleAvatar(
            radius: 24,
            backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
            backgroundColor: Colors.grey.shade300,
            child: user.photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
          ),
          const SizedBox(width: 12),
          // Informazioni dell'utente
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome e cognome
                Text("${user.nome} ${user.cognome}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                // Username
                Text("@${user.username}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                // Statistiche (numero di allenamenti)
                Text("${stat.workoutsCount} Allenamenti", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          // Bottone per l'azione (es. Rimuovi amico)
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

/// Tab che mostra i clienti seguiti da un Personal Trainer.
class PtClientsTab extends StatelessWidget {
  /// Lista dei clienti (istanze di UserModel).
  final List<UserModel> clients;
  
  /// Statistiche dei clienti.
  final Map<String, FriendStats> stats;
  /// Callback per rimuovere un cliente.
  final Function(String) onRemove;
  
  /// Callback per creare una scheda di allenamento per un cliente.
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
    // Se non ci sono clienti, mostra un messaggio centrato
    if (clients.isEmpty) {
      return const Center(
        child: Text("Non hai ancora nessun cliente.", style: TextStyle(color: Colors.grey)),
      );
    }
    // Mostra la lista dei clienti in una ListView
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

  /// Costruisce la card di un singolo cliente, con i suoi dati e il pulsante per creare la scheda.
  Widget _buildClientCard(UserModel user, FriendStats stat) {
    return Container(
      // Margine e padding per spaziare la card
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
              // Avatar del cliente
              CircleAvatar(
                radius: 24,
                backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                backgroundColor: Colors.grey.shade300,
                child: user.photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
              ),
              const SizedBox(width: 12),
              // Dati principali
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${user.nome} ${user.cognome}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("@${user.username}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    // Mostra l'obiettivo del cliente per contestualizzare la scheda
                    Text("Obiettivo: ${user.obiettivo}", style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              // Bottone per rimuovere il cliente
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: () => onRemove(user.uid),
              )
            ],
          ),
          const SizedBox(height: 12),
          // Pulsante per creare una scheda di allenamento per il cliente
          SizedBox(
            width: double.infinity, // Il bottone occupa tutta la larghezza disponibile
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE67E22), // Colore arancione distintivo
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

/// Tab per visualizzare le richieste di amicizia e di coaching (sia in entrata che in uscita).
class RequestsTab extends StatefulWidget {
  /// Lista delle richieste ricevute.
  final List<IncomingRequestUi> incoming;
  
  /// Lista delle richieste inviate.
  final List<OutgoingRequestUi> outgoing;
  /// Callback per accettare una richiesta.
  final Function(String) onAccept;
  
  /// Callback per rifiutare una richiesta (in entrata).
  final Function(String) onReject;
  
  /// Callback per annullare una richiesta (in uscita).
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
  /// Determina se mostrare le richieste in entrata o in uscita.
  bool _isIncomingSelected = true;

  @override
  Widget build(BuildContext context) {
    // Seleziona la lista corretta in base al tab interno scelto
    final list = _isIncomingSelected ? widget.incoming : widget.outgoing;

    return Column(
      children: [
        // Pulsanti di selezione (In entrata / In uscita) (Tab selector customizzato)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Row(
            children: [
              // Pulsante "In entrata"
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isIncomingSelected = true),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      // Sfondo scuro se selezionato, chiaro altrimenti
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
              // Pulsante "In uscita"
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
        // Contenuto della lista selezionata
        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Text("Nessuna richiesta", style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    // Costruisce la card in base al tab attivo
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

  /// Costruisce la card per una richiesta in entrata, mostrando chi l'ha inviata e i pulsanti Accetta/Rifiuta.
  Widget _buildIncomingCard(IncomingRequestUi req) {
    // Determina il testo descrittivo in base al tipo di richiesta
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
              // Avatar del mittente
              CircleAvatar(
                backgroundImage: req.sender.photoUrl.isNotEmpty ? NetworkImage(req.sender.photoUrl) : null,
                backgroundColor: Colors.grey.shade300,
                child: req.sender.photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
              ),
              const SizedBox(width: 12),
              // Nome e username
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
          // Testo esplicativo del tipo di richiesta
          Text(typeText, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          // Pulsanti di azione (Rifiuta / Accetta)
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
                    backgroundColor: const Color(0xFFE67E22), // Arancione di richiamo
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

  /// Costruisce la card per una richiesta in uscita, mostrando il destinatario e il pulsante per annullarla.
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
          // Avatar del destinatario della richiesta
          CircleAvatar(
            backgroundImage: req.receiver.photoUrl.isNotEmpty ? NetworkImage(req.receiver.photoUrl) : null,
            backgroundColor: Colors.grey.shade300,
            child: req.receiver.photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
          ),
          const SizedBox(width: 12),
          // Nome, cognome e tipo di richiesta inviata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${req.receiver.nome} ${req.receiver.cognome}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(typeText, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          // Pulsante per annullare la richiesta
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

/// Tab per cercare nuovi utenti nella community.
class SearchTab extends StatelessWidget {
  /// Testo cercato attualmente.
  final String query;
  
  /// Callback chiamato quando il testo cambia.
  final Function(String) onQueryChange;
  
  /// Risultati della ricerca.
  final List<UserModel> results;
  
  /// Flag che indica se una ricerca è in corso (per mostrare il loading).
  final bool isSearching;
  /// Utente corrente (per controllare relazioni PT o amicizia).
  final UserModel? currentUser;
  
  /// Lista degli amici per nascondere il pulsante "Amico" se già presente.
  final List<UserModel> friends;
  
  /// Callback per inviare richiesta amicizia.
  final Function(String) onSendFriend;
  
  /// Callback per inviare richiesta di coaching (solo verso PT).
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
        // Barra di ricerca
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: onQueryChange, // Aggiorna la query ad ogni input
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
        // Mostra un caricamento se la ricerca è in corso
        if (isSearching)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: Colors.black),
          )
        // Se la ricerca è finita ma non ci sono risultati (e c'è testo cercato)
        else if (results.isEmpty && query.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Nessun utente trovato.", style: TextStyle(color: Colors.grey)),
          )
        // Altrimenti, mostra la lista dei risultati
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

  /// Costruisce un singolo risultato della ricerca, con logica condizionale
  /// per mostrare i pulsanti giusti in base allo stato delle relazioni.
  Widget _buildSearchResult(UserModel user, BuildContext context) {
    // Controlla se l'utente trovato è già nella lista amici
    final bool isFriend = friends.any((f) => f.uid == user.uid);
    // Controlla se l'utente trovato è il Personal Trainer corrente dell'utente
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
              // Avatar utente
              CircleAvatar(
                radius: 24,
                backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                backgroundColor: Colors.grey.shade300,
                child: user.photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
              ),
              const SizedBox(width: 12),
              // Nome e username
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${user.nome} ${user.cognome}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("@${user.username}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    // Mostra un badge "PT" se l'utente cercato è un Personal Trainer
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
          // Pulsanti per inviare richieste
          Row(
            children: [
              // Gestione amicizia: se già amico mostra testo "Già amico", altrimenti pulsante per aggiungere
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
              // Gestione Coaching: se l'utente cercato è un PT E noi NON siamo PT
              if (user.isPersonalTrainer && !(currentUser?.isPersonalTrainer ?? false)) ...[
                const SizedBox(width: 8),
                // Se è già il nostro PT, mostra "Sei già seguito"
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
                // Altrimenti mostra il pulsante "Richiedi PT"
                else
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.fitness_center, size: 16),
                      label: const Text("Richiedi PT", style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE67E22), // Arancione 
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
