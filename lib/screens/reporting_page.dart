import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/message_service.dart';
import 'signin_screen.dart';

class ReportingPage extends StatefulWidget {
  const ReportingPage({super.key});

  @override
  State<ReportingPage> createState() => _ReportingPageState();
}

class _ReportingPageState extends State<ReportingPage>
    with TickerProviderStateMixin {
  final messageController = TextEditingController();
  final searchController = TextEditingController();
  final AuthService _authService = AuthService();
  final MessageService _messageService = MessageService();

  late TabController _tabController;

  bool isLoading = false;
  bool isLoadingMessages = false;
  bool isSigningOut = false;
  bool useRealTime = true;
  List<Message> messages = [];
  List<Message> searchResults = [];
  int currentPage = 1;
  int totalMessages = 0;
  FilterType selectedFilter = FilterType.newest;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTotalCount();
  }

  void _loadMessages() async {
    setState(() {
      isLoadingMessages = true;
    });

    List<Message> loadedMessages = await _messageService.getMessages(
      pageNumber: currentPage,
      filter: selectedFilter,
    );

    setState(() {
      messages = loadedMessages;
      isLoadingMessages = false;
    });
  }

  void _loadTotalCount() async {
    int count = await _messageService.getTotalMessageCount();
    setState(() {
      totalMessages = count;
    });
  }

  void _handlePostMessage() async {
    if (messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    String? messageId =
        await _messageService.postMessage(messageController.text);

    setState(() {
      isLoading = false;
    });

    if (messageId != null) {
      messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message posted anonymously!')),
      );
      setState(() {
        currentPage = 1;
      });
      _loadMessages();
      _loadTotalCount();

      // Switch to View tab
      _tabController.animateTo(1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post message. Try again!')),
      );
    }
  }

  void _handleSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        isSearching = false;
        searchResults = [];
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    List<Message> results = await _messageService.searchMessages(query);

    setState(() {
      searchResults = results;
    });
  }

  void _nextPage() {
    int maxPages = (totalMessages / MessageService.pageSize).ceil();
    if (currentPage < maxPages) {
      setState(() {
        currentPage++;
      });
      _loadMessages();
    }
  }

  void _previousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
      _loadMessages();
    }
  }

  void _deleteMessage(String messageId) async {
    bool success = await _messageService.deleteMessage(messageId);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted')),
      );
      _loadMessages();
      _loadTotalCount();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete message')),
      );
    }
  }

  void _handleSignOut() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sign Out'),
          content: Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Sign Out'),
              onPressed: () async {
                Navigator.of(context).pop();
                
                setState(() {
                  isSigningOut = true;
                });

                try {
                  await _authService.signOut();

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => SignInScreen()),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Signed out successfully')),
                  );
                } catch (e) {
                  setState(() {
                    isSigningOut = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing out')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageCard(Message msg) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(msg.text),
        subtitle: Text(
          _formatDateTime(msg.timestamp),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
          onPressed: () => _deleteMessage(msg.id),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ANONYMOUS MESSAGES"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit), text: "Post"),
            Tab(icon: Icon(Icons.view_list), text: "View"),
          ],
        ),
        actions: [
          isSigningOut
              ? Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: _handleSignOut,
                  tooltip: 'Sign Out',
                ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: POST MESSAGES
          _buildPostTab(),

          // TAB 2: VIEW MESSAGES
          _buildViewTab(),
        ],
      ),
    );
  }

  Widget _buildPostTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Share Your Story",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Anonymous voices can still be powerful. Share your story, inspire others, and help end GBV.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Message input
            TextField(
              controller: messageController,
              maxLines: 8,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: "What would you like to share?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: "Type your anonymous message here...",
                counterText: "${messageController.text.length}/1000",
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 20),

            // Submit button
            isLoading
                ? const SizedBox(
                    height: 50,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _handlePostMessage,
                    child: const Text(
                      "Post Anonymously",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
            const SizedBox(height: 20),
            const Text(
              "💡 Tip: Your message will be posted anonymously and visible to all users.",
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewTab() {
    if (!isLoadingMessages && messages.isEmpty) {
      _loadMessages();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: "Search messages",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        setState(() {
                          isSearching = false;
                          searchResults = [];
                        });
                      },
                    )
                  : null,
            ),
            onChanged: _handleSearch,
          ),
          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Newest'),
                  selected: selectedFilter == FilterType.newest,
                  onSelected: (selected) {
                    setState(() {
                      selectedFilter = FilterType.newest;
                      currentPage = 1;
                    });
                    _loadMessages();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Oldest'),
                  selected: selectedFilter == FilterType.oldest,
                  onSelected: (selected) {
                    setState(() {
                      selectedFilter = FilterType.oldest;
                      currentPage = 1;
                    });
                    _loadMessages();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('My Messages'),
                  selected: selectedFilter == FilterType.myMessages,
                  onSelected: (selected) {
                    setState(() {
                      selectedFilter = FilterType.myMessages;
                      currentPage = 1;
                    });
                    _loadMessages();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Messages list
          Expanded(
            child: isSearching && searchController.text.isNotEmpty
                ? _buildSearchResults()
                : useRealTime
                    ? _buildRealtimeMessages()
                    : _buildPaginatedMessages(),
          ),

          const SizedBox(height: 12),

          // Pagination controls
          if (!isSearching && !useRealTime)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: currentPage > 1 ? _previousPage : null,
                  child: const Text("Previous"),
                ),
                Text('Page $currentPage / ${(totalMessages / MessageService.pageSize).ceil()}'),
                ElevatedButton(
                  onPressed: currentPage <
                          (totalMessages / MessageService.pageSize).ceil()
                      ? _nextPage
                      : null,
                  child: const Text("Next"),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (searchResults.isEmpty) {
      return Center(
        child: Text('No messages found matching "${searchController.text}"'),
      );
    }

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) => _buildMessageCard(searchResults[index]),
    );
  }

  Widget _buildRealtimeMessages() {
    return StreamBuilder<List<Message>>(
      stream: _messageService.getFilteredMessagesStream(selectedFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.message, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No messages yet'),
                const SizedBox(height: 8),
                const Text(
                  'Be the first to post!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) =>
              _buildMessageCard(snapshot.data![index]),
        );
      },
    );
  }

  Widget _buildPaginatedMessages() {
    if (isLoadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.message, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No messages yet'),
            const SizedBox(height: 8),
            const Text(
              'Be the first to post!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) => _buildMessageCard(messages[index]),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}