import 'package:flutter/material.dart';
import 'package:animated_background/animated_background.dart';
import '../services/groq_service.dart';
import '../utils/code_highlighter.dart';
import '../utils/date_time_utils.dart';
// App config is used indirectly through GroqService
import 'home_page.dart';

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
  
  // Initialize Groq service using app configuration
  final GroqService _groqService = GroqService();
  
  // Sample welcome message
  @override
  void initState() {
    super.initState();
    // Add welcome message after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Hello! I'm Quike AI, your personal assistant. How can I help you today?",
            isUser: false,
            timestamp: DateTimeUtils.nowInIndia(),
          ),
        );
      });
    });
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    
    _messageController.clear();
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
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
      
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTimeUtils.nowInIndia(),
          ),
        );
      });
      
      // Scroll to bottom again after response
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: "I'm sorry, I encountered an error. Please try again later.",
            isUser: false,
            timestamp: DateTimeUtils.nowInIndia(),
          ),
        );
      });
      print('Error: $e');
    }
  }
  

  
  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }
  
  void _showSignupModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[900]?.withOpacity(0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.pinkAccent.withOpacity(0.7), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.pinkAccent.withOpacity(0.22),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(blurRadius: 8, color: Colors.pinkAccent.withOpacity(0.5), offset: const Offset(0, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _glowingTextField(hintText: 'Name', icon: Icons.person_outline, obscureText: false, glowColor: Colors.pinkAccent),
              const SizedBox(height: 16),
              _glowingTextField(hintText: 'Email', icon: Icons.email_outlined, obscureText: false, glowColor: Colors.pinkAccent),
              const SizedBox(height: 16),
              _glowingTextField(hintText: 'Password', icon: Icons.lock_outline, obscureText: true, glowColor: Colors.pinkAccent),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Add signup logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor: Colors.pinkAccent.withOpacity(0.5),
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Glowing text field
  Widget _glowingTextField({
    required String hintText,
    required IconData icon,
    required bool obscureText,
    required Color glowColor,
  }) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: glowColor),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[850]?.withOpacity(0.92),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: glowColor.withOpacity(0.7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: glowColor.withOpacity(0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: glowColor, width: 2),
        ),
      ),
    );
  }

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
          Column(
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
          
          // Optimized semi-transparent overlay with animation
          // Using IgnorePointer to improve performance when not visible
          IgnorePointer(
            ignoring: !_isSidebarOpen,
            child: AnimatedOpacity(
              opacity: _isSidebarOpen ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: GestureDetector(
                onTap: _toggleSidebar, // Close sidebar when tapping outside
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),
            
          // Optimized sidebar overlay with hardware acceleration
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.fastOutSlowIn, // More efficient curve
            left: _isSidebarOpen ? 0 : -MediaQuery.of(context).size.width,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.85, // 85% of screen width
            child: RepaintBoundary(
              child: Material(
                elevation: 16,
                color: Colors.transparent,
                child: GestureDetector(
                  // This ensures touches are handled by the sidebar
                  onTap: () {}, // Empty onTap to capture gestures
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
                      'Demo User',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      'Trial Mode',
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
                // Clear the chat
                setState(() {
                  _messages.clear();
                  // Add welcome message
                  _messages.add(
                    ChatMessage(
                      text: "Hello! I'm Quike AI, your personal assistant. How can I help you today?",
                      isUser: false,
                      timestamp: DateTimeUtils.nowInIndia(),
                    ),
                  );
                });
              }),
              _topMenuButton(Icons.settings_outlined, 'Settings', () {
                _toggleSidebar();
                _showSettingsPage();
              }),
              _topMenuButton(Icons.info_outline, 'About', () {
                _toggleSidebar();
                _showAboutDialog();
              }),
              _topMenuButton(Icons.help_outline, 'Help', () {
                _toggleSidebar();
                _showHelpDialog();
              }),
              _topMenuButton(Icons.home_outlined, 'Home', () {
                _toggleSidebar();
                // Navigate to home page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const TrialChatPage()),
                );
              }),
            ],
          ),
        ),
        
        // Expanded area for additional content
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _quickActionTile(
                    'Create a new document', 
                    Icons.description_outlined,
                    prompt: 'Help me create a document about [topic]. Include an introduction, key points, and conclusion.',
                  ),
                  _quickActionTile(
                    'Write Python code', 
                    Icons.code_outlined,
                    prompt: 'Write a Python function that [describe what the function should do].',
                  ),
                  _quickActionTile(
                    'Explain a concept', 
                    Icons.question_answer_outlined,
                    prompt: 'Explain the concept of [topic] in simple terms. Include examples if possible.',
                  ),
                  _quickActionTile(
                    'Summarize text', 
                    Icons.summarize_outlined,
                    prompt: 'Summarize the following text in a few bullet points: [paste your text here]',
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Sign up button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showSignupModal,
            icon: const Icon(Icons.person_add),
            label: const Text('Sign Up for Full Access'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 0),
            ),
          ),
        ),
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
  
  Widget _quickActionTile(String title, IconData icon, {String? prompt}) {
    return Card(
      color: Colors.grey[850]?.withOpacity(0.7),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.blueAccent.withOpacity(0.1),
          highlightColor: Colors.blueAccent.withOpacity(0.05),
          onTap: () {
            // Close sidebar
            _toggleSidebar(); 
            
            // If prompt is provided, insert it into the chat input
            if (prompt != null && prompt.isNotEmpty) {
              _messageController.text = prompt;
              // Focus the text field
              FocusScope.of(context).requestFocus(FocusNode());
              Future.delayed(const Duration(milliseconds: 100), () {
                // This ensures the text field gets focus after sidebar is closed
                FocusScope.of(context).requestFocus(FocusNode());
              });
            }
          },
          child: ListTile(
            leading: Icon(icon, color: Colors.blueAccent),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ),
        ),
      ),
    );
  }
  

  
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                const SizedBox(height: 4),
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
  
  // Show help dialog
  void _showHelpDialog() {
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
            border: Border.all(color: Colors.greenAccent.withOpacity(0.7), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withOpacity(0.22),
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
                    'Help & Tips',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(blurRadius: 8, color: Colors.greenAccent.withOpacity(0.5), offset: const Offset(0, 2)),
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
              
              // Help items
              _helpItem(
                'Ask Questions',
                'You can ask Quike AI any question and get instant answers.',
                Icons.question_answer,
              ),
              _helpItem(
                'Generate Code',
                'Ask for code examples in various programming languages.',
                Icons.code,
              ),
              _helpItem(
                'Format Text',
                'Use **bold text** in your messages for emphasis.',
                Icons.format_bold,
              ),
              _helpItem(
                'Quick Actions',
                'Use the sidebar quick actions for common tasks.',
                Icons.flash_on,
              ),
              _helpItem(
                'Sign Up',
                'Create an account to save chat history and access more features.',
                Icons.person_add,
              ),
              
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Got it'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Help item widget
  Widget _helpItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.greenAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime timestamp) {
    return DateTimeUtils.formatTime(timestamp);
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
