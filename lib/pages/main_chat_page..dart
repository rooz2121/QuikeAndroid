import 'package:flutter/material.dart';
import 'package:animated_background/animated_background.dart';
import '../services/groq_service.dart';
import '../utils/code_highlighter.dart';
import '../services/supabase_service.dart';
import '../models/chat_models.dart';
import '../utils/date_time_utils.dart';
// App config is used indirectly through GroqService

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isSidebarOpen = false;
  String? _userEmail;
  String? _userName;
  
  // Chat history state
  List<ChatSession> _chatSessions = [];
  String? _currentSessionId;
  bool _isLoadingSessions = false;
  bool _isCreatingSession = false;
  
  // Initialize Groq service using app configuration
  final GroqService _groqService = GroqService();
  final SupabaseService _supabaseService = SupabaseService();
  
  @override
  void initState() {
    super.initState();
    // Get user info from Supabase
    _getUserInfo();
    
    // Add initial welcome message immediately
    _messages.add(
      ChatMessage(
        text: "Hello! I'm Quike AI, your personal assistant. How can I help you today?",
        isUser: false,
        timestamp: DateTimeUtils.nowInIndia(),
      ),
    );
    
    // Load chat sessions
    _loadChatSessions();
    
    // Create a new session if authenticated
    Future.microtask(() => _createNewSession());
  }
  
  // Load chat sessions from Supabase
  Future<void> _loadChatSessions() async {
    if (_supabaseService.currentUser == null) return;
    
    setState(() {
      _isLoadingSessions = true;
    });
    
    try {
      final sessions = await _supabaseService.getChatSessions();
      setState(() {
        _chatSessions = sessions.map((json) => ChatSession.fromJson(json)).toList();
        _isLoadingSessions = false;
      });
    } catch (e) {
      print('Error loading chat sessions: $e');
      setState(() {
        _isLoadingSessions = false;
      });
    }
  }
  
  // Create a new chat session
  Future<void> _createNewSession() async {
    // Skip if not authenticated
    if (_supabaseService.currentUser == null) {
      return;
    }
    
    setState(() {
      _isCreatingSession = true;
      _messages.clear();
    });
    
    // Show loading indicator if creating a new session
    if (_isCreatingSession) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Creating new chat...'),
          duration: Duration(seconds: 1),
        ),
      );
    }
    
    try {
      final session = await _supabaseService.createChatSession('New Chat');
      
      if (session != null) {
        final newSession = ChatSession.fromJson(session);
        
        setState(() {
          _chatSessions.insert(0, newSession);
          _currentSessionId = newSession.id;
          _isCreatingSession = false;
        });
        
        // Add welcome message
        _messages.add(
          ChatMessage(
            text: "Hello! I'm Quike AI, your personal assistant. How can I help you today?",
            isUser: false,
            timestamp: DateTimeUtils.nowInIndia(),
          ),
        );
        
        // Save welcome message to database
        await _supabaseService.saveChatMessage(
          newSession.id,
          "Hello! I'm Quike AI, your personal assistant. How can I help you today?",
          false,
        );
      }
    } catch (e) {
      print('Error creating new session: $e');
      setState(() {
        _isCreatingSession = false;
        
        // Add welcome message even if session creation fails
        _messages.add(
          ChatMessage(
            text: "Hello! I'm Quike AI, your personal assistant. How can I help you today?",
            isUser: false,
            timestamp: DateTimeUtils.nowInIndia(),
          ),
        );
      });
    }
  }
  
  // Load messages for a specific chat session
  Future<void> _loadSessionMessages(String sessionId) async {
    setState(() {
      _messages.clear();
      _isTyping = true; // Show loading indicator
    });
    
    try {
      final messages = await _supabaseService.getChatMessages(sessionId);
      
      setState(() {
        _messages.addAll(
          messages.map((json) {
            final messageModel = ChatMessageModel.fromJson(json);
            final messageMap = messageModel.toMessageMap();
            return ChatMessage(
              text: messageMap['text'],
              isUser: messageMap['isUser'],
              timestamp: messageMap['timestamp'],
            );
          }).toList(),
        );
        _currentSessionId = sessionId;
        _isTyping = false;
      });
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Error loading session messages: $e');
      setState(() {
        _isTyping = false;
      });
    }
  }
  
  // Delete a chat session
  Future<void> _deleteSession(String sessionId) async {
    try {
      final success = await _supabaseService.deleteChatSession(sessionId);
      
      if (success) {
        setState(() {
          _chatSessions.removeWhere((session) => session.id == sessionId);
          
          // If the current session was deleted, create a new one
          if (_currentSessionId == sessionId) {
            _currentSessionId = null;
            _messages.clear();
            _createNewSession();
          }
        });
      }
    } catch (e) {
      print('Error deleting session: $e');
    }
  }

  void _handleSubmitted(String text) async {
    _messageController.clear();
    
    if (text.trim().isEmpty) return;
    
    // Create a new session if none exists
    if (_currentSessionId == null) {
      await _createNewSession();
    }
    
    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    
    // Save user message to database if session exists
    if (_currentSessionId != null) {
      await _supabaseService.saveChatMessage(
        _currentSessionId!,
        text,
        true,
      );
    }
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    try {
      // Get response from Groq API
      final response = await _groqService.generateResponse(text);
      
      // Check if response contains code
      final hasCode = response.contains('```');
      
      final aiMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTimeUtils.nowInIndia(),
      );
      
      setState(() {
        _isTyping = false;
        _messages.add(aiMessage);
      });
      
      // Save AI response to database if session exists
      if (_currentSessionId != null) {
        await _supabaseService.saveChatMessage(
          _currentSessionId!,
          response,
          false,
          hasCode: hasCode,
        );
        
        // Update session title if it's the first message
        if (_messages.length == 3) { // Welcome message + user message + AI response
          final title = text.length > 30 ? text.substring(0, 27) + '...' : text;
          await _supabaseService.updateChatSessionTitle(_currentSessionId!, title);
          
          // Refresh chat sessions to get updated title
          _loadChatSessions();
        }
      }
      
      // Scroll to bottom again after response
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      final errorMessage = ChatMessage(
        text: "Sorry, I encountered an error: ${e.toString()}",
        isUser: false,
        timestamp: DateTimeUtils.nowInIndia(),
      );
      
      setState(() {
        _isTyping = false;
        _messages.add(errorMessage);
      });
      
      // Save error message to database if session exists
      if (_currentSessionId != null) {
        await _supabaseService.saveChatMessage(
          _currentSessionId!,
          "Sorry, I encountered an error: ${e.toString()}",
          false,
        );
      }
    }
  }
  

  
  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }
  
  // Get user info from Supabase
  void _getUserInfo() {
    final supabaseService = SupabaseService();
    final user = supabaseService.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email;
        _userName = user.userMetadata?['full_name'] as String? ?? 'User';
      });
    }
  }
  
  // Sign out from Supabase
  void _signOut() async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Confirm Logout', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to log out?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    
    // If user confirmed logout
    if (confirm == true) {
      try {
        await SupabaseService().signOut();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error signing out: $e')),
          );
        }
      }
    }
  }
  
  // These methods are implemented below
  
  // This method was removed as it's no longer used

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Animated background
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: AnimatedBackground(
              behaviour: RandomParticleBehaviour(
                options: ParticleOptions(
                  baseColor: Colors.blueAccent.withOpacity(0.4),
                  spawnMinSpeed: 5.0,
                  spawnMaxSpeed: 20.0,
                  spawnMinRadius: 1.0,
                  spawnMaxRadius: 2.0,
                  particleCount: 80,
                  image: null,
                ),
              ),
              vsync: this,
              child: Container(),
            ),
          ),
          
          // Main content - Chat area
          GestureDetector(
            // Add horizontal drag gesture to open sidebar
            onHorizontalDragEnd: (details) {
              // If dragged to the right with sufficient velocity, open the sidebar
              if (!_isSidebarOpen && details.primaryVelocity != null && details.primaryVelocity! > 300) {
                _toggleSidebar();
              }
            },
            child: Column(
              children: [
                // App bar
                _buildAppBar(),
                
                // Chat area
                Expanded(
                  child: Column(
                    children: [
                      // Messages area
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildMessagesList(),
                        ),
                      ),
                      
                      // Input area
                      _buildInputArea(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Semi-transparent overlay with animation
          AnimatedOpacity(
            opacity: _isSidebarOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: _isSidebarOpen ? GestureDetector(
              onTap: _toggleSidebar, // Close sidebar when tapping outside
              child: Container(
                color: Colors.black.withOpacity(0.4),
                width: double.infinity,
                height: double.infinity,
              ),
            ) : const SizedBox(),
          ),
            
          // Sidebar overlay - slides in from left on z-axis (on top of overlay)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _isSidebarOpen ? 0 : -MediaQuery.of(context).size.width,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.85, // 85% of screen width
            child: Material(
              elevation: 16,
              color: Colors.transparent,
              child: GestureDetector(
                // This ensures touches are handled by the sidebar
                onTap: () {}, // Empty onTap to capture gestures
                // Add horizontal drag gesture to close sidebar
                onHorizontalDragEnd: (details) {
                  // If dragged to the left with sufficient velocity, close the sidebar
                  if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
                    _toggleSidebar();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.92),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: _buildSidebar(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _isSidebarOpen ? Icons.close : Icons.menu, 
                color: Colors.white
              ),
              onPressed: _toggleSidebar,
            ),
            const SizedBox(width: 8),
            Text(
              'Quike AI Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(blurRadius: 5, color: Colors.blue.withOpacity(0.5), offset: const Offset(0, 2)),
                ],
              ),
            ),
            const Spacer(),
            // Quick Actions dropdown menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.lightbulb_outline, color: Colors.amber),
              tooltip: 'Quick Actions',
              onSelected: (String value) {
                String prompt = '';
                switch (value) {
                  case 'document':
                    prompt = 'Help me create a document about [topic]. Include an introduction, key points, and conclusion.';
                    break;
                  case 'code':
                    prompt = 'Write a Python function that [describe what the function should do].';
                    break;
                  case 'explain':
                    prompt = 'Explain the concept of [topic] in simple terms. Include examples if possible.';
                    break;
                  case 'summarize':
                    prompt = 'Summarize the following text in a few bullet points: [paste your text here]';
                    break;
                }
                if (prompt.isNotEmpty) {
                  _messageController.text = prompt;
                  // Focus the text field
                  FocusScope.of(context).requestFocus(FocusNode());
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'document',
                  child: Row(
                    children: [
                      Icon(Icons.description_outlined, color: Colors.blueAccent),
                      SizedBox(width: 12),
                      Text('Create a document'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'code',
                  child: Row(
                    children: [
                      Icon(Icons.code_outlined, color: Colors.greenAccent),
                      SizedBox(width: 12),
                      Text('Write Python code'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'explain',
                  child: Row(
                    children: [
                      Icon(Icons.question_answer_outlined, color: Colors.purpleAccent),
                      SizedBox(width: 12),
                      Text('Explain a concept'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'summarize',
                  child: Row(
                    children: [
                      Icon(Icons.summarize_outlined, color: Colors.orangeAccent),
                      SizedBox(width: 12),
                      Text('Summarize text'),
                    ],
                  ),
                ),
              ],
            ),
            // Theme toggle removed
          ],
        ),
      ),
    );
  }
  
  Widget _buildSidebar() {
    return Column(
      children: [
        // Safe area at the top to avoid status bar
        SizedBox(height: MediaQuery.of(context).padding.top + 20),
        
        // User profile section
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[800],
                radius: 24,
                child: const Icon(Icons.person, color: Colors.white70, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName ?? 'User',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      _userEmail ?? 'Authenticated User',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: _toggleSidebar,
              ),
            ],
          ),
        ),
        const Divider(color: Colors.grey, height: 1, thickness: 0.5),
        
        // Menu items in a horizontal row
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _topMenuButton(Icons.chat_bubble_outline, 'New Chat', () {
                _toggleSidebar();
                _createNewSession();
              }),
              _topMenuButton(Icons.settings_outlined, 'Settings', () {
                _toggleSidebar();
                _showSettingsPage();
              }),
              _topMenuButton(Icons.info_outline, 'About', () {
                _toggleSidebar();
                _showAboutDialog();
              }),
              _topMenuButton(Icons.logout, 'Sign Out', _signOut),
            ],
          ),
        ),
        
        // Chat history list
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chat History',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Loading indicator
                if (_isLoadingSessions)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_chatSessions.isEmpty)
                  // No chat history placeholder
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No chat history yet',
                      style: TextStyle(color: Colors.grey[400]),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  // Chat history list
                  Expanded(
                    child: ListView.builder(
                      itemCount: _chatSessions.length,
                      itemBuilder: (context, index) {
                        final session = _chatSessions[index];
                        final isSelected = session.id == _currentSessionId;
                        
                        return InkWell(
                          onTap: () {
                            _loadSessionMessages(session.id);
                            if (_isSidebarOpen && MediaQuery.of(context).size.width < 1200) {
                              _toggleSidebar();
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 18,
                                  color: isSelected ? Colors.blue[300] : Colors.grey[400],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        session.title,
                                        style: TextStyle(
                                          color: isSelected ? Colors.blue[300] : Colors.white,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _formatDate(session.updatedAt),
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey[600]),
                                  onPressed: () {
                                    // Show confirmation dialog
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: Colors.grey[900],
                                        title: const Text('Delete Chat', style: TextStyle(color: Colors.white)),
                                        content: const Text(
                                          'Are you sure you want to delete this chat? This action cannot be undone.',
                                          style: TextStyle(color: Colors.white70),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _deleteSession(session.id);
                                            },
                                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  tooltip: 'Delete chat',
                                  splashRadius: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Extra spacing at the bottom
        const SizedBox(height: 16),
      ],
    );
  }
  
  Widget _topMenuButton(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withOpacity(0.1),
        highlightColor: Colors.white.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // This method was removed as it's no longer used
  

  
  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          // Show typing indicator
          return _buildTypingIndicator();
        }
        final message = _messages[index];
        return _buildMessageItem(message);
      },
    );
  }
  
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(isUser: false),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 10),
            decoration: BoxDecoration(
              color: Colors.grey[850]?.withOpacity(0.8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(delay: 0),
                _buildDot(delay: 300),
                _buildDot(delay: 600),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDot({required int delay}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: AnimatedBuilder(
        animation: AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1200),
        )..repeat(),
        builder: (context, child) {
          return Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildMessageItem(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Avatar and sender info row
          Padding(
            padding: EdgeInsets.only(
              left: message.isUser ? 0 : 8,
              right: message.isUser ? 8 : 0,
              bottom: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!message.isUser) _buildAvatar(isUser: false),
                if (!message.isUser) const SizedBox(width: 8),
                Text(
                  message.isUser ? 'You' : 'Quike AI',
                  style: TextStyle(
                    color: message.isUser ? Colors.blueAccent : Colors.pinkAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (message.isUser) const SizedBox(width: 8),
                if (message.isUser) _buildAvatar(isUser: true),
              ],
            ),
          ),
          
          // Message content
          Container(
            width: MediaQuery.of(context).size.width * 0.85, // Wider message container
            margin: EdgeInsets.only(
              left: message.isUser ? 40 : 8,
              right: message.isUser ? 8 : 40,
            ),
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: message.isUser 
                  ? Colors.blueAccent.withOpacity(0.2)
                  : Colors.grey[850]?.withOpacity(0.8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: message.isUser 
                    ? Colors.blueAccent.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: message.isUser 
                      ? Colors.blueAccent.withOpacity(0.15)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Use code highlighter for AI responses, regular text for user messages
                if (message.isUser)
                  Text(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    softWrap: true,
                  )
                else
                  _buildMessageWithCodeHighlighting(message.text),
                // Time indicator with no extra spacing
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageWithCodeHighlighting(String message) {
    // First parse for code blocks
    final List<MessageSegment> segments = CodeHighlighter.parseMessageWithCode(message);
    
    if (segments.length == 1 && segments.first is TextSegment) {
      // If there's only regular text, check for bold formatting
      if (message.contains('**')) {
        return _formatBoldText(message);
      } else {
        // No code or bold formatting, display normally
        return Text(
          message,
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 15,
          ),
          softWrap: true,
        );
      }
    }
    
    // For messages with code blocks, process each segment
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.map((segment) {
        // Apply bold formatting to text segments
        if (segment is TextSegment && segment.text.contains('**')) {
          return _formatBoldText(segment.text);
        } else {
          return segment.buildWidget(context);
        }
      }).toList(),
    );
  }
  
  // Helper method to format bold text
  Widget _formatBoldText(String text) {
    // Regular expression to find bold text
    final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
    
    // If no bold text, return normal text
    if (!text.contains('**')) {
      return Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.95),
          fontSize: 15,
        ),
        softWrap: true,
      );
    }
    
    // Find all bold text matches
    final matches = boldRegex.allMatches(text).toList();
    final List<TextSpan> spans = [];
    int lastIndex = 0;
    
    // Base text style
    final baseStyle = TextStyle(
      color: Colors.white.withOpacity(0.95),
      fontSize: 15,
    );
    
    // Bold text style
    final boldStyle = baseStyle.copyWith(
      fontWeight: FontWeight.bold,
    );
    
    for (final match in matches) {
      // Add text before the bold part
      if (match.start > lastIndex) {
        final beforeText = text.substring(lastIndex, match.start);
        spans.add(TextSpan(text: beforeText, style: baseStyle));
      }
      
      // Add the bold text (without the ** markers)
      final boldText = match.group(1)!;
      spans.add(TextSpan(text: boldText, style: boldStyle));
      
      lastIndex = match.end;
    }
    
    // Add any remaining text after the last bold part
    if (lastIndex < text.length) {
      final afterText = text.substring(lastIndex);
      spans.add(TextSpan(text: afterText, style: baseStyle));
    }
    
    return RichText(
      text: TextSpan(children: spans),
      softWrap: true,
    );
  }
  
  Widget _buildAvatar({required bool isUser}) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: isUser ? Colors.blueAccent.withOpacity(0.2) : Colors.pinkAccent.withOpacity(0.2),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 20,
        color: isUser ? Colors.blueAccent : Colors.pinkAccent,
      ),
    );
  }
  
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[850]?.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _handleSubmitted,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.mic, color: Colors.grey),
                      onPressed: () {}, // Voice input would go here
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () => _handleSubmitted(_messageController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Show settings page dialog
  void _showSettingsPage() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[900]?.withOpacity(0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.7), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.22),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(blurRadius: 8, color: Colors.blueAccent.withOpacity(0.5), offset: const Offset(0, 2)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Theme setting
              _settingTile(
                'Dark Theme',
                'Enable dark theme for the application',
                Icons.dark_mode,
                true,
                (value) {},
              ),
              
              // Notifications setting
              _settingTile(
                'Notifications',
                'Enable notifications (Demo only)',
                Icons.notifications,
                false,
                (value) {},
              ),
              
              // Sound setting
              _settingTile(
                'Sound Effects',
                'Enable sound effects (Demo only)',
                Icons.volume_up,
                true,
                (value) {},
              ),
              
              const SizedBox(height: 20),
              Text(
                'Demo Mode - Settings are not saved',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Setting tile widget
  Widget _settingTile(String title, String subtitle, IconData icon, bool initialValue, Function(bool) onChanged) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      trailing: Switch(
        value: initialValue,
        onChanged: onChanged,
        activeColor: Colors.blueAccent,
      ),
    );
  }
  
  // Show about dialog with credits
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[900]?.withOpacity(0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.purpleAccent.withOpacity(0.7), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.22),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'About Quike AI',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(blurRadius: 8, color: Colors.purpleAccent.withOpacity(0.5), offset: const Offset(0, 2)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // App logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.purpleAccent.withOpacity(0.7), width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.bolt, size: 40, color: Colors.purpleAccent),
                ),
              ),
              const SizedBox(height: 16),
              
              // App version
              const Text(
                'Quike AI v1.0.0',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // App description
              Text(
                'Your personal AI assistant powered by Groq.',
                style: TextStyle(color: Colors.grey[300], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Developer credits
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Developed by',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Muhammed Zaheer R',
                      style: TextStyle(
                        color: Colors.purpleAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.purpleAccent.withOpacity(0.5), offset: const Offset(0, 2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Close button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatTime(DateTime timestamp) {
    return DateTimeUtils.formatTime(timestamp);
  }
  
  // Format date for chat history display
  String _formatDate(DateTime dateTime) {
    return DateTimeUtils.formatDate(dateTime);
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
