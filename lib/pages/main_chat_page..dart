import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  // Confirmation system state
  bool _isConfirmationPending = false;
  String _pendingAction = '';
  String _pendingConfirmationContext = '';
  
  // Feedback system state
  final Map<String, String> _messageFeedback = {}; // Maps message ID to feedback type ('like' or 'dislike')
  
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
    
    // No longer creating a new session automatically
    // Session will be created when user sends first message
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
      // Clear existing messages when creating a new chat
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
      // Create a new session with default name
      final session = await _supabaseService.createChatSession('New Chat');
      
      if (session != null) {
        final newSession = ChatSession.fromJson(session);
        
        // Add welcome message
        final welcomeMessage = ChatMessage(
          text: "Hello! I'm Quike AI, your personal assistant. How can I help you today?",
          isUser: false,
          timestamp: DateTimeUtils.nowInIndia(),
        );
        
        setState(() {
          _chatSessions.insert(0, newSession);
          _currentSessionId = newSession.id;
          _isCreatingSession = false;
          _messages.add(welcomeMessage);
        });
        
        // Save welcome message to database
        await _supabaseService.saveChatMessage(
          newSession.id,
          welcomeMessage.text,
          false,
        );
        
        // Scroll to the welcome message
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToBottom();
        });
      }
    } catch (e) {
      print('Error creating new session: $e');
      setState(() {
        _isCreatingSession = false;
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
      
      final chatMessages = messages.map((json) {
        final messageModel = ChatMessageModel.fromJson(json);
        final messageMap = messageModel.toMessageMap();
        return ChatMessage(
          text: messageMap['text'],
          isUser: messageMap['isUser'],
          timestamp: messageMap['timestamp'],
        );
      }).toList();
      
      setState(() {
        _messages.addAll(chatMessages);
        _currentSessionId = sessionId;
        _isTyping = false;
      });
      
      // More reliable scroll to bottom with a slight delay to ensure rendering is complete
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
      
      // Also add another delayed scroll for extra reliability
      Future.delayed(const Duration(milliseconds: 500), () {
        _scrollToBottom();
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
          // Remove the deleted session from the list
          _chatSessions.removeWhere((session) => session.id == sessionId);
          
          // If the current session was deleted
          if (_currentSessionId == sessionId) {
            _currentSessionId = null;
            _messages.clear();
            
            // Add only the welcome message to the UI without creating a new session
            _messages.add(ChatMessage(
              text: "Hello! I'm Quike AI, your personal assistant. How can I help you today?",
              isUser: false,
              timestamp: DateTimeUtils.nowInIndia(),
            ));
            
            // Close the sidebar if it's open
            if (_isSidebarOpen) {
              _toggleSidebar();
            }
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
      
      // If we just created a new session, also save the welcome message
      // that was previously only in the UI
      if (_currentSessionId != null && _messages.isNotEmpty) {
        // Find the welcome message (should be the first one)
        final welcomeMessage = _messages.firstWhere(
          (msg) => !msg.isUser,
          orElse: () => ChatMessage(
            text: "Hello! I'm Quike AI, your personal assistant. How can I help you today?",
            isUser: false,
            timestamp: DateTimeUtils.nowInIndia(),
          ),
        );
        
        // Save welcome message to database
        await _supabaseService.saveChatMessage(
          _currentSessionId!,
          welcomeMessage.text,
          false,
        );
      }
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
    
    // Check if this is a confirmation response to a specific proposal
    // Only process as confirmation if we're actually waiting for one AND have a specific action pending
    if (_isConfirmationPending && 
        _pendingAction.isNotEmpty && 
        _pendingAction != 'general_question' && 
        _isConfirmationResponse(text)) {
      await _processConfirmation(text);
      return;
    }
    
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
      _scrollToBottom();
    });
    
    try {
      // Determine if this is a direct question from the user
      bool isDirectQuestion = text.trim().toLowerCase().startsWith('what') ||
                            text.trim().toLowerCase().startsWith('how') ||
                            text.trim().toLowerCase().startsWith('why') ||
                            text.trim().toLowerCase().startsWith('when') ||
                            text.trim().toLowerCase().startsWith('where') ||
                            text.trim().toLowerCase().startsWith('who') ||
                            text.trim().toLowerCase().startsWith('which') ||
                            text.trim().toLowerCase().contains('?');
      
      // If this is a direct question, we should reset any pending confirmation state
      if (isDirectQuestion && _isConfirmationPending) {
        _isConfirmationPending = false;
        _pendingAction = '';
        _pendingConfirmationContext = '';
      }
      
      // Default system prompt
      String systemPrompt = """You are Quike AI, a helpful assistant embedded in a chat app.

Your main goal is to understand whether the user's latest message is:
1. A direct response to your previous question or suggestion.
2. A new, unrelated question or command.

Use this logic:
- If you recently asked a question, treat the user's input as a response **unless** it clearly starts a new topic (like "By the way," "Also," or asks something totally different).
- If you didn't ask a question before, treat the input as a new request.

Always keep the previous message context in mind.

Provide concise, accurate, and helpful responses. For direct questions, answer directly without asking for confirmation.""";
      
      // Customize system prompt for confirmation scenarios
      if (_isConfirmationPending) {
        if (_pendingAction == 'recommendations_request') {
          systemPrompt = """You are Quike AI, a helpful and friendly assistant. 
          
The user has responded to your list of recommendations. You previously shared a list and asked if they wanted more specific recommendations. 
Context of previous message: $_pendingConfirmationContext

If their response is 'yes' or similar, provide more detailed recommendations or options based on the category you were discussing. Do not ask for confirmation again - just provide more recommendations.

If they specified a particular type/genre/category, focus your recommendations on that specific request.

If the user's response is clearly a new question unrelated to recommendations, answer that new question instead.""";
        } else if (_pendingAction == 'information_request') {
          systemPrompt = """You are Quike AI, a helpful and friendly assistant. 
          
The user has expressed interest in learning more about the topic you previously discussed. 
Context of previous message: $_pendingConfirmationContext

Provide detailed, informative content about the topic. Be thorough but concise. Do not ask for further confirmation - just provide the information.

If the user's response is clearly a new question unrelated to the previous topic, answer that new question instead.""";
        } else if (_pendingAction == 'question') {
          systemPrompt = """You are Quike AI, a helpful and friendly assistant.
          
The user is responding to a question you asked. Your previous message was: $_pendingConfirmationContext

Treat the user's input as a direct response to your question unless it clearly introduces a new, unrelated topic.
Provide a helpful, informative response based on their answer. Do not ask for further confirmation unless necessary.

If their response is ambiguous or unclear, provide the most helpful response you can based on your best interpretation.""";
        }
      }
      
      // Fetch the last 10 messages for conversation history
      List<Map<String, String>> conversationHistory = [];
      if (_currentSessionId != null) {
        try {
          conversationHistory = await _supabaseService.getLastMessagesForAIContext(_currentSessionId!, limit: 10);
          print('Using ${conversationHistory.length} messages as context for AI response');
        } catch (e) {
          print('Error fetching conversation history: $e');
          // Continue with empty history if there's an error
        }
      }
      
      // Generate AI response
      String response;
      if (conversationHistory.isNotEmpty) {
        // Use conversation history when available
        if (_isConfirmationPending) {
          // For confirmation scenarios, we still use the conversation history but with a special system prompt
          response = await _groqService.generateResponseWithHistory(text, conversationHistory);
        } else {
          // Standard case - use conversation history with default system prompt
          response = await _groqService.generateResponseWithHistory(text, conversationHistory);
        }
      } else {
        // Fallback to standard response generation if history is not available
        if (_isConfirmationPending) {
          response = await _groqService.sendMessageWithSystemPrompt(text, systemPrompt);
        } else {
          response = await _groqService.generateResponse(text);
        }
      }
      
      // Check if this response is asking for confirmation
      if (_detectConfirmationRequest(response)) {
        // Extract the proposed action from the response
        _pendingAction = _extractProposedAction(response);
        _isConfirmationPending = true;
        _pendingConfirmationContext = response;
      } else if (_isConfirmationPending) {
        // Reset confirmation state after handling the response
        _isConfirmationPending = false;
        _pendingAction = '';
        _pendingConfirmationContext = '';
      }
      
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
        );
        
        // Update session title if it's the first message
        if (_messages.length == 3) { // Welcome message + user message + AI response
          final title = text.length > 30 ? '${text.substring(0, 27)}...' : text;
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
  
  // Check if the user's response is a confirmation
  bool _isConfirmationResponse(String text) {
    final String normalizedText = text.toLowerCase().trim();
    
    // Simple yes/no responses
    bool isSimpleConfirmation = 
           normalizedText == 'yes' || 
           normalizedText == 'ok' || 
           normalizedText == 'sure' || 
           normalizedText == 'proceed' || 
           normalizedText == 'go ahead' || 
           normalizedText == 'confirm' || 
           normalizedText == 'approved' ||
           normalizedText == 'do it';
    
    // Action-oriented confirmation phrases
    bool isActionConfirmation =
           normalizedText.contains('yes do it') ||
           normalizedText.contains('yes, do it') ||
           normalizedText.contains('ok do it') ||
           normalizedText.contains('ok, do it') ||
           normalizedText.contains('sure do it') ||
           normalizedText.contains('please do it') ||
           normalizedText.contains('yes assist me') ||
           normalizedText.contains('yes, assist me') ||
           normalizedText.contains('ok assist me') ||
           normalizedText.contains('assist me') ||
           normalizedText.contains('yes help me') ||
           normalizedText.contains('help me with this');
    
    // Responses that start with confirmation words
    bool startsWithConfirmation = 
           normalizedText.startsWith('yes,') || 
           normalizedText.startsWith('ok,') || 
           normalizedText.startsWith('sure,') ||
           normalizedText.startsWith('yes i') ||
           normalizedText.startsWith('yes please');
    
    // Longer affirmative responses
    bool isLongerConfirmation = 
           normalizedText.contains('sounds good') ||
           normalizedText.contains('that works') ||
           normalizedText.contains('please do') ||
           normalizedText.contains('go for it') ||
           normalizedText.contains('go ahead with it') ||
           normalizedText.contains('that would be great') ||
           normalizedText.contains('i would like that');
    
    return isSimpleConfirmation || isActionConfirmation || startsWithConfirmation || isLongerConfirmation;
  }
  
  // Process a confirmation response from the user
  Future<void> _processConfirmation(String text) async {
    // Save user message to database if session exists
    if (_currentSessionId != null) {
      await _supabaseService.saveChatMessage(
        _currentSessionId!,
        text,
        true,
      );
    }
    
    try {
      final String normalizedText = text.toLowerCase().trim();
      final bool isConfirmed = _isConfirmationResponse(normalizedText);
      
      // Create a special system prompt for handling the confirmation
      final String systemPrompt = isConfirmed
          ? "You are Quike AI. The user has confirmed your proposal. Implement the solution you suggested and explain what you've done. Be thorough but concise."
          : "You are Quike AI. The user has declined your proposal. Acknowledge their decision respectfully and ask what alternative approach they would prefer."; 
      
      // Create a special prompt that includes the context
      final String prompt = isConfirmed
          ? "I am confirming your proposal. Please implement what you suggested regarding: $_pendingAction"
          : "I am declining your proposal about: $_pendingAction. Please suggest an alternative approach."; 
      
      // Fetch the last 10 messages for conversation history
      List<Map<String, String>> conversationHistory = [];
      if (_currentSessionId != null) {
        try {
          conversationHistory = await _supabaseService.getLastMessagesForAIContext(_currentSessionId!, limit: 10);
          print('Using ${conversationHistory.length} messages as context for AI response');
        } catch (e) {
          print('Error fetching conversation history: $e');
          // Continue with empty history if there's an error
        }
      }
      
      // Generate AI response
      String response;
      if (conversationHistory.isNotEmpty) {
        // Use conversation history when available
        if (_isConfirmationPending) {
          // For confirmation scenarios, we still use the conversation history but with a special system prompt
          response = await _groqService.generateResponseWithHistory(prompt, conversationHistory);
        } else {
          // Standard case - use conversation history with default system prompt
          response = await _groqService.generateResponseWithHistory(prompt, conversationHistory);
        }
      } else {
        // Fallback to standard response generation if history is not available
        if (_isConfirmationPending) {
          response = await _groqService.sendMessageWithSystemPrompt(prompt, systemPrompt);
        } else {
          response = await _groqService.generateResponse(prompt);
        }
      }
      
      final aiMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTimeUtils.nowInIndia(),
      );
      
      setState(() {
        _isTyping = false;
        _messages.add(aiMessage);
        // Reset confirmation state
        _isConfirmationPending = false;
        _pendingAction = '';
        _pendingConfirmationContext = '';
      });
      
      // Save AI response to database if session exists
      if (_currentSessionId != null) {
        await _supabaseService.saveChatMessage(
          _currentSessionId!,
          response,
          false,
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
    } catch (e) {
      final errorMessage = ChatMessage(
        text: "Sorry, I encountered an error processing your confirmation: ${e.toString()}",
        isUser: false,
        timestamp: DateTimeUtils.nowInIndia(),
      );
      
      setState(() {
        _isTyping = false;
        _messages.add(errorMessage);
        // Reset confirmation state on error
        _isConfirmationPending = false;
        _pendingAction = '';
        _pendingConfirmationContext = '';
      });
      
      // Save error message to database if session exists
      if (_currentSessionId != null) {
        await _supabaseService.saveChatMessage(
          _currentSessionId!,
          "Sorry, I encountered an error processing your confirmation: ${e.toString()}",
          false,
        );
      }
    }
  }
  
  // Detect if the AI response is asking for confirmation for a specific action
  // or asking a question that expects a response
  bool _detectConfirmationRequest(String response) {
    final String normalizedText = response.toLowerCase();
    
    // Check for numbered or bulleted lists (common in option presentations)
    bool containsListFormat = RegExp(r'\d+\.\s+[A-Z]').hasMatch(response) || // Numbered list (1. Item)
                             RegExp(r'•\s+[A-Z]').hasMatch(response) ||      // Bullet points
                             RegExp(r'\*\s+[A-Z]').hasMatch(response);      // Asterisk bullets
    
    // If response contains a list format, it's likely presenting options, not asking for confirmation
    if (containsListFormat) {
      return false;
    }
    
    // Check if the response is asking a question that expects a response
    // This includes questions about preferences, follow-up questions, etc.
    bool isAskingQuestion = response.trim().endsWith('?');
    int questionMarkCount = '?'.allMatches(response).length;
    
    // Check for lists of items (common in recommendations, options, etc.)
    bool containsNumberedList = RegExp(r'\d+\.\s+[A-Za-z]').hasMatch(response);
    bool containsBulletList = RegExp(r'•\s+[A-Za-z]').hasMatch(response) || RegExp(r'\*\s+[A-Za-z]').hasMatch(response);
    bool containsList = containsNumberedList || containsBulletList;
    
    // Special case for lists followed by a question - this is likely a recommendation list
    // followed by asking if the user wants more or has specific preferences
    if (containsList && isAskingQuestion) {
      // This is a list with a question at the end, like game recommendations followed by
      // "Is there a specific genre you're interested in?" or "Would you like more recommendations?"
      return true;
    }
    
    // If the last sentence ends with a question mark, it's likely expecting a response
    if (isAskingQuestion) {
      // Check if it's offering information and asking if the user wants more
      bool isOfferingInformation = 
             (normalizedText.contains('would you like to know more') || 
             normalizedText.contains('would you like to learn more') ||
             normalizedText.contains('would you like me to explain') ||
             normalizedText.contains('would you like more information') ||
             normalizedText.contains('would you like to hear more') ||
             normalizedText.contains('would you like recommendations') ||
             normalizedText.contains('i can provide more') ||
             normalizedText.contains('i can recommend more') ||
             normalizedText.contains('or is there something specific'));
      
      if (isOfferingInformation) {
        return true; // This is a special type of confirmation request for information
      }
      
      // If there's only one question mark and it's at the end, it's likely a simple question
      // that expects a direct response
      if (questionMarkCount == 1) {
        return true;
      }
    }
    
    // Check if the response is directly asking a question that expects a specific answer
    bool isAskingDirectQuestion = 
           normalizedText.contains('what specific') || 
           normalizedText.contains('which one') || 
           normalizedText.contains('what would you like') || 
           normalizedText.contains('what are you interested') ||
           normalizedText.contains('what aspect') ||
           normalizedText.contains('what type') ||
           normalizedText.contains('what kind') ||
           normalizedText.contains('what topic') ||
           (normalizedText.contains('would you like to') && normalizedText.contains('discuss'));
    
    // If it's asking a direct question about preferences, it's not a confirmation request
    if (isAskingDirectQuestion) {
      return false;
    }
    
    // Check if the response is primarily informational (contains multiple sentences without action items)
    int sentenceCount = RegExp(r'[.!?]\s+[A-Z]').allMatches(response).length + 1;
    if (sentenceCount > 3 && !normalizedText.contains('would you like me to')) {
      return false; // Likely an informational response, not asking for confirmation
    }
    
    // Check if the response contains phrases that indicate a specific proposal
    bool containsSpecificProposal = 
           (normalizedText.contains('i can') && !normalizedText.contains('i can help') && !normalizedText.contains('i can explain') && !normalizedText.contains('i can assist')) || 
           (normalizedText.contains('i could') && !normalizedText.contains('i could help') && !normalizedText.contains('i could explain')) || 
           normalizedText.contains('i will implement') || 
           normalizedText.contains('i would implement') ||
           normalizedText.contains('i will create') ||
           normalizedText.contains('i would create') ||
           normalizedText.contains('i will add') ||
           normalizedText.contains('i would add');
    
    // Check for confirmation-seeking phrases
    bool hasConfirmationPhrase = 
           normalizedText.contains('would you like me to') || 
           normalizedText.contains('should i proceed') || 
           normalizedText.contains('would you like to proceed') || 
           normalizedText.contains('shall i proceed') || 
           normalizedText.contains('do you want me to') || 
           (normalizedText.contains('would you prefer') && !normalizedText.contains('would you prefer to learn about')) || 
           normalizedText.contains('is that okay') || 
           normalizedText.contains('is this what you want') || 
           normalizedText.contains('would you like that') || 
           normalizedText.contains('should i implement') || 
           normalizedText.contains('would you like me to implement') ||
           (normalizedText.contains('would you') && normalizedText.contains('confirm'));
    
    // Only detect as confirmation request if there's a specific proposal AND a confirmation-seeking phrase
    return containsSpecificProposal && hasConfirmationPhrase;
  }
  
  // Extract the proposed action from the AI response
  String _extractProposedAction(String response) {
    final String normalizedText = response.toLowerCase();
    
    // Check for lists of items followed by a question (common in recommendations)
    bool containsNumberedList = RegExp(r'\d+\.\s+[A-Za-z]').hasMatch(response);
    bool containsBulletList = RegExp(r'•\s+[A-Za-z]').hasMatch(response) || RegExp(r'\*\s+[A-Za-z]').hasMatch(response);
    bool containsList = containsNumberedList || containsBulletList;
    bool endsWithQuestion = response.trim().endsWith('?');
    
    // If it contains a list and ends with a question, it's likely a recommendation list
    // followed by asking if the user wants more specific recommendations
    if (containsList && endsWithQuestion) {
      if (normalizedText.contains('genre') || 
          normalizedText.contains('type') || 
          normalizedText.contains('recommend') || 
          normalizedText.contains('interested in') ||
          normalizedText.contains('i can provide more')) {
        return 'recommendations_request';
      }
    }
    
    // Check if this is an information offering response
    if (normalizedText.contains('would you like to know more') || 
        normalizedText.contains('would you like to learn more') ||
        normalizedText.contains('would you like me to explain') ||
        normalizedText.contains('would you like more information') ||
        normalizedText.contains('would you like to hear more') ||
        normalizedText.contains('would you like recommendations') ||
        normalizedText.contains('i can provide more') ||
        normalizedText.contains('i can recommend more') ||
        (normalizedText.contains('is there something specific') && normalizedText.contains('like to ask'))) {
      return 'information_request';
    }
    
    // Check if this is a question expecting a response
    if (endsWithQuestion) {
      // If it's a simple question at the end of the message, mark it as a question
      // This helps with context tracking for follow-up responses
      return 'question';
    }
    
    // This is a simplified extraction - in a real app, you might use more sophisticated NLP
    // For now, we'll extract action-oriented sentences
    final sentences = response.split(RegExp(r'(?<=[.!?])\s+'));
    
    for (final sentence in sentences) {
      final lowerSentence = sentence.toLowerCase();
      
      // Implementation-related actions
      if (lowerSentence.contains('i will implement') || lowerSentence.contains('i would implement')) {
        return 'implement';
      }
      
      // Creation-related actions
      if (lowerSentence.contains('i will create') || lowerSentence.contains('i would create')) {
        return 'create';
      }
      
      // Addition-related actions
      if (lowerSentence.contains('i will add') || lowerSentence.contains('i would add')) {
        return 'add';
      }
      
      // Help-related actions
      if (lowerSentence.contains('i can help') || lowerSentence.contains('i could help')) {
        return 'help';
      }
    }
    
    // If no specific action is found, return a generic action
    return 'proceed';
  }
  
  // Get user info from Supabase
  Future<void> _getUserInfo() async {
    try {
      // Use the new getUserProfile method to get consistent user information
      final profileData = await _supabaseService.getUserProfile();
      
      if (profileData != null) {
        setState(() {
          _userEmail = profileData['email'] ?? 'No email';
          _userName = profileData['full_name'] ?? 'User';
        });
        
        print('User info retrieved: $_userName, $_userEmail');
      } else {
        // Fallback to basic info if profile couldn't be retrieved
        final user = _supabaseService.currentUser;
        if (user != null) {
          setState(() {
            _userEmail = user.email ?? 'No email';
            _userName = user.email?.split('@').first ?? 'User';
          });
        }
      }
    } catch (e) {
      print('Error retrieving user info: $e');
      // Fallback to basic info in case of error
      final user = _supabaseService.currentUser;
      if (user != null) {
        setState(() {
          _userEmail = user.email ?? 'No email';
          _userName = user.email?.split('@').first ?? 'User';
        });
      }
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
              _topMenuButton(Icons.settings_outlined, 'Settings', _showSettingsPage),
              _topMenuButton(Icons.help_outline, 'Help', _showHelpPage),
              _topMenuButton(Icons.info_outline, 'About', _showAboutPage),
            ],
          ),
        ),
        
        // Chat history list
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                // Remove space between label and content
                
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
                    padding: const EdgeInsets.all(8.0),
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
                      padding: EdgeInsets.zero, // Remove default padding
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
                            margin: const EdgeInsets.only(bottom: 4),
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
        
        // Add a small fixed space instead of a flexible spacer
        const SizedBox(height: 20),
        
        // Sign out button with proper spacing
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 24),
          child: InkWell(
            onTap: _signOut,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: Colors.white70, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
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
                  message.isUser ? (_userName ?? 'You') : 'Quike AI',
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
                // Add feedback buttons for AI messages (except welcome message)
                if (!message.isUser && message.text != "Hello! I'm Quike AI, your personal assistant. How can I help you today?")
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Like button
                        _buildFeedbackButton(
                          icon: _getFeedbackIcon(message, 'like'),
                          tooltip: 'Like',
                          onPressed: () => _handleFeedback(message, 'like'),
                          color: _getFeedbackColor(message, 'like'),
                        ),
                        const SizedBox(width: 8),
                        // Dislike button
                        _buildFeedbackButton(
                          icon: _getFeedbackIcon(message, 'dislike'),
                          tooltip: 'Dislike',
                          onPressed: () => _handleFeedback(message, 'dislike'),
                          color: _getFeedbackColor(message, 'dislike'),
                        ),
                        const SizedBox(width: 8),
                        // Copy button
                        _buildFeedbackButton(
                          icon: Icons.copy_outlined,
                          tooltip: 'Copy',
                          onPressed: () => _copyMessageToClipboard(message.text),
                        ),
                        const SizedBox(width: 12),
                        // Time indicator
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                // Only show timestamp for welcome message
                else if (!message.isUser && message.text == "Hello! I'm Quike AI, your personal assistant. How can I help you today?")
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Time indicator only
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Time indicator for user messages
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
      // If there's only regular text, check for bullet points or bold formatting
      if (_containsBulletPoints(message)) {
        return _formatBulletPoints(message);
      } else if (message.contains('**')) {
        return _formatBoldText(message);
      } else {
        // No code, bullet points, or bold formatting, display normally
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
        // Apply bullet point formatting to text segments if needed
        if (segment is TextSegment && _containsBulletPoints(segment.text)) {
          return _formatBulletPoints(segment.text);
        }
        // Apply bold formatting to text segments
        else if (segment is TextSegment && segment.text.contains('**')) {
          return _formatBoldText(segment.text);
        } else {
          return segment.buildWidget(context);
        }
      }).toList(),
    );
  }
  
  // Helper method to check if text contains bullet points
  bool _containsBulletPoints(String text) {
    // Check for lines starting with asterisks (*) or bullet points (•)
    final RegExp bulletRegex = RegExp(r'(^|\n)\s*\*\s', multiLine: true);
    return bulletRegex.hasMatch(text);
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
  
  // Helper method to format bullet points
  Widget _formatBulletPoints(String text) {
    // Split the text into lines
    final lines = text.split('\n');
    final List<Widget> lineWidgets = [];
    
    // Base text style
    final baseStyle = TextStyle(
      color: Colors.white.withOpacity(0.95),
      fontSize: 15,
    );
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Check if this line is a bullet point (starts with * followed by space or text)
      if (line.startsWith('*')) {
        // Extract the content after the bullet
        final bulletContent = line.startsWith('* ') 
            ? line.substring(2) // For asterisks with space
            : line.substring(1); // For asterisks without space
        
        lineWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bullet point symbol
                const Padding(
                  padding: EdgeInsets.only(top: 3.0, right: 4.0),
                  child: Text('•', 
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 15,
                      fontWeight: FontWeight.bold
                    )
                  ),
                ),
                const SizedBox(width: 6),
                // Bullet point content
                Expanded(
                  child: bulletContent.contains('**') 
                      ? _formatBoldText(bulletContent)
                      : Text(bulletContent, style: baseStyle),
                ),
              ],
            ),
          ),
        );
      } else if (line.isNotEmpty) {
        // Regular line (not a bullet point)
        lineWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: line.contains('**')
                ? _formatBoldText(line)
                : Text(line, style: baseStyle),
          ),
        );
      } else {
        // Empty line
        lineWidgets.add(const SizedBox(height: 8));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lineWidgets,
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
  
  // Navigate to the settings page
  void _showSettingsPage() {
    _toggleSidebar(); // Close the sidebar
    Navigator.pushNamed(context, '/settings');
  }
  
  // Navigate to the about page
  void _showAboutPage() {
    _toggleSidebar(); // Close the sidebar
    Navigator.pushNamed(context, '/about');
  }
  
  // Navigate to the help page
  void _showHelpPage() {
    _toggleSidebar(); // Close the sidebar
    Navigator.pushNamed(context, '/help');
  }
  
  String _formatTime(DateTime timestamp) {
    return DateTimeUtils.formatTime(timestamp);
  }
  
  // Format date for chat history display
  String _formatDate(DateTime dateTime) {
    return DateTimeUtils.formatDate(dateTime);
  }
  
  // Helper method to scroll to the bottom of the chat
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  // Build a feedback button (like, dislike, copy)
  Widget _buildFeedbackButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Tooltip(
          message: tooltip,
          child: Container(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 16,
              color: color ?? Colors.grey[400],
            ),
          ),
        ),
      ),
    );
  }
  
  // Handle feedback (like or dislike)
  void _handleFeedback(ChatMessage message, String feedbackType) {
    // Generate a unique ID for the message if it doesn't exist
    final String messageId = '${message.timestamp.millisecondsSinceEpoch}_${message.text.hashCode}';
    
    // Check if we're selecting or deselecting
    final bool isDeselecting = _messageFeedback[messageId] == feedbackType;
    
    setState(() {
      // If the same button is clicked again, remove the feedback
      if (isDeselecting) {
        _messageFeedback.remove(messageId);
      } else {
        // Otherwise set the new feedback type
        _messageFeedback[messageId] = feedbackType;
      }
    });
    
    // Only show thank you message when selecting feedback, not when deselecting
    if (!isDeselecting) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you for your feedback!'),
          duration: const Duration(seconds: 2),
          backgroundColor: feedbackType == 'like' ? Colors.green[700] : Colors.blue[700],
        ),
      );
    }
    
    // In a real app, you would send this feedback to your backend
    // For example:
    // _supabaseService.saveFeedback(_currentSessionId, message.text, feedbackType, isDeselecting);
  }
  
  // Copy message text to clipboard
  void _copyMessageToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  // Get the appropriate icon for feedback buttons based on current state
  IconData _getFeedbackIcon(ChatMessage message, String feedbackType) {
    final String messageId = '${message.timestamp.millisecondsSinceEpoch}_${message.text.hashCode}';
    final String? currentFeedback = _messageFeedback[messageId];
    
    if (currentFeedback == feedbackType) {
      // Use filled icon if this feedback type is selected
      return feedbackType == 'like' ? Icons.thumb_up : Icons.thumb_down;
    } else {
      // Use outlined icon otherwise
      return feedbackType == 'like' ? Icons.thumb_up_outlined : Icons.thumb_down_outlined;
    }
  }
  
  // Get the appropriate color for feedback buttons based on current state
  Color? _getFeedbackColor(ChatMessage message, String feedbackType) {
    final String messageId = '${message.timestamp.millisecondsSinceEpoch}_${message.text.hashCode}';
    final String? currentFeedback = _messageFeedback[messageId];
    
    if (currentFeedback == feedbackType) {
      // Use accent color if this feedback type is selected
      return feedbackType == 'like' ? Colors.green[400] : Colors.blue[400];
    } else {
      // Use default gray otherwise
      return Colors.grey[400];
    }
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
