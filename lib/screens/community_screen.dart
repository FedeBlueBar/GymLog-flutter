import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/community_notifier.dart';
import '../widgets/community_tabs.dart';
import '../widgets/workout_dialogs.dart';

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
    // Initially we don't know if the user is a PT or not until the notifier loads, 
    // but the notifier is likely already loaded or loading.
    // For simplicity, we'll initialize a 4-tab controller. If they are not a PT, 
    // we just hide the second tab or disable it. A better approach is to build 
    // the tab controller dynamically when the state is ready.
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CommunityNotifier(),
      child: Consumer<CommunityNotifier>(
        builder: (context, notifier, child) {
          
          if (notifier.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(notifier.errorMessage!)));
                notifier.clearMessages();
              }
            });
          }
          if (notifier.successMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(notifier.successMessage!)));
                notifier.clearMessages();
              }
            });
          }

          final tabs = [
            const Tab(text: "Amici"),
            if (notifier.isCurrentUserPt) const Tab(text: "Clienti"),
            const Tab(text: "Richieste"),
            const Tab(text: "Cerca"),
          ];

          return DefaultTabController(
            length: tabs.length,
            child: Scaffold(
              backgroundColor: Colors.white,
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
              body: Stack(
                children: [
                  TabBarView(
                    children: [
                      FriendsTab(
                        friends: notifier.friends,
                        stats: notifier.friendStats,
                        onRemove: notifier.removeFriend,
                      ),
                      if (notifier.isCurrentUserPt)
                        PtClientsTab(
                          clients: notifier.ptClients,
                          stats: notifier.friendStats,
                          onRemove: notifier.removePtClient,
                          onCreateWorkout: (uid, name) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => WorkoutPlanDialog(clientUid: uid),
                              ),
                            );
                          },
                        ),
                      RequestsTab(
                        incoming: notifier.incomingRequests,
                        outgoing: notifier.outgoingRequests,
                        onAccept: notifier.acceptRequest,
                        onReject: notifier.rejectRequest,
                        onCancel: notifier.cancelRequest,
                      ),
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
