import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/community_notifier.dart';
import '../widgets/community_tabs.dart';
import '../widgets/workout_dialogs.dart';

// Schermata principale per la Community.
// Da qui l'utente può visualizzare i propri amici, i clienti (se è un PT), 
// gestire le richieste in sospeso e cercare nuovi utenti.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Inizializza e rende disponibile il CommunityNotifier a tutta la gerarchia sottostante
    return ChangeNotifierProvider(
      create: (_) => CommunityNotifier(),
      child: Consumer<CommunityNotifier>(
        builder: (context, notifier, child) {
          
          // Gestione della visualizzazione dei messaggi di errore come SnackBar (popup a scomparsa rapida)
          if (notifier.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(notifier.errorMessage!)));
                notifier.clearMessages();
              }
            });
          }
          
          // Gestione della visualizzazione dei messaggi di successo
          if (notifier.successMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(notifier.successMessage!)));
                notifier.clearMessages();
              }
            });
          }

          // Definisce quali schede (Tab) mostrare nell'interfaccia. 
          // Il tab "Clienti" viene mostrato solo se l'utente corrente è un Personal Trainer.
          final tabs = [
            const Tab(text: "Amici"),
            if (notifier.isCurrentUserPt) const Tab(text: "Clienti"),
            const Tab(text: "Richieste"),
            const Tab(text: "Cerca"),
          ];

          // Controller predefinito per la navigazione tramite tab
          return DefaultTabController(
            length: tabs.length,
            child: Scaffold(
              backgroundColor: Colors.white,
              // Barra superiore con il titolo e l'elenco dei Tab cliccabili
              appBar: AppBar(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                title: const Text("Community", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                bottom: TabBar(
                  isScrollable: false,
                  labelColor: const Color(0xFFE67E22),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFFE67E22),
                  tabs: tabs,
                ),
              ),
              // Corpo centrale della schermata: uno Stack permette di sovrapporre il caricamento (se in corso) alla vista corrente
              body: Stack(
                children: [
                  TabBarView(
                    children: [
                      // Tab 1: Mostra la lista degli amici
                      FriendsTab(
                        friends: notifier.friends,
                        stats: notifier.friendStats,
                        onRemove: notifier.removeFriend,
                      ),
                      // Tab 2 (Opzionale): Mostra la lista dei clienti del Personal Trainer
                      if (notifier.isCurrentUserPt)
                        PtClientsTab(
                          clients: notifier.ptClients,
                          stats: notifier.friendStats,
                          onRemove: notifier.removePtClient,
                          // Azione speciale per il PT: cliccando crea una nuova scheda per il cliente
                          onCreateWorkout: (uid, name) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => WorkoutPlanDialog(clientUid: uid),
                              ),
                            );
                          },
                        ),
                      // Tab 3: Mostra le richieste di amicizia/coaching (ricevute e inviate)
                      RequestsTab(
                        incoming: notifier.incomingRequests,
                        outgoing: notifier.outgoingRequests,
                        onAccept: notifier.acceptRequest,
                        onReject: notifier.rejectRequest,
                        onCancel: notifier.cancelRequest,
                      ),
                      // Tab 4: Mostra la barra di ricerca per trovare e aggiungere nuovi utenti
                      SearchTab(
                        query: notifier.searchQuery,
                        onQueryChange: notifier.onSearchQueryChange,
                        results: notifier.searchResults,
                        isSearching: notifier.isSearching,
                        currentUser: notifier.currentUser,
                        friends: notifier.friends,
                        onSendFriend: notifier.sendFriendshipRequest,
                        onSendCoaching: notifier.sendPtCoachingRequest,
                      ),
                    ],
                  ),
                  // Se un'operazione asincrona è in corso, mostra un indicatore di caricamento trasparente sopra a tutto
                  if (notifier.isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.1),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.black),
                      ),
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
