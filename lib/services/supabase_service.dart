import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/date_time_utils.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _client;

  // Supabase credentials
  static const String supabaseUrl = 'https://gazkqkkutqwjspceubvh.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdhemtxa2t1dHF3anNwY2V1YnZoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ4MjE0NTAsImV4cCI6MjA2MDM5NzQ1MH0.Wo6N-mOaHBJdjOrI3tBDXPZs74iSc58x0UC_k1Lg6e0';

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  SupabaseClient get client => _client;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
      },
    );
    
    return response;
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    return response;
  }

  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  // CHAT HISTORY METHODS
  
  // Create a new chat session
  Future<Map<String, dynamic>?> createChatSession(String title) async {
    final user = currentUser;
    if (user == null) return null;
    
    try {
      final now = DateTimeUtils.nowForSupabase();
      final response = await _client
          .from('chat_sessions')
          .insert({
            'user_id': user.id,
            'title': title,
            'created_at': now,
            'updated_at': now,
          })
          .select()
          .single();
      
      return response;
    } catch (e) {
      print('Error creating chat session: $e');
      return null;
    }
  }
  
  // Get all chat sessions for current user
  Future<List<Map<String, dynamic>>> getChatSessions() async {
    final user = currentUser;
    if (user == null) return [];
    
    try {
      final response = await _client
          .from('chat_sessions')
          .select()
          .eq('user_id', user.id)
          .order('updated_at', ascending: false);
      
      // Convert UTC timestamps to IST for display
      final sessions = List<Map<String, dynamic>>.from(response);
      for (var session in sessions) {
        // Add IST timestamp for display
        final createdAt = DateTime.parse(session['created_at']);
        final updatedAt = DateTime.parse(session['updated_at']);
        
        // Add 5 hours and 30 minutes to convert UTC to IST
        session['created_at_ist'] = createdAt.add(const Duration(hours: 5, minutes: 30)).toIso8601String();
        session['updated_at_ist'] = updatedAt.add(const Duration(hours: 5, minutes: 30)).toIso8601String();
        
        // Keep original timestamps for database operations
        session['created_at'] = session['created_at'];
        session['updated_at'] = session['updated_at'];
      }
      
      return sessions;
    } catch (e) {
      print('Error getting chat sessions: $e');
      return [];
    }
  }
  
  // Update chat session title
  Future<bool> updateChatSessionTitle(String sessionId, String newTitle) async {
    try {
      await _client
          .from('chat_sessions')
          .update({'title': newTitle, 'updated_at': DateTimeUtils.nowForSupabase()})
          .eq('id', sessionId);
      
      return true;
    } catch (e) {
      print('Error updating chat session title: $e');
      return false;
    }
  }
  
  // Delete a chat session
  Future<bool> deleteChatSession(String sessionId) async {
    try {
      await _client
          .from('chat_sessions')
          .delete()
          .eq('id', sessionId);
      
      return true;
    } catch (e) {
      print('Error deleting chat session: $e');
      return false;
    }
  }
  
  // Save a message to a chat session
  Future<bool> saveChatMessage(String sessionId, String content, bool isUser, {bool hasCode = false}) async {
    try {
      final now = DateTimeUtils.nowForSupabase();
      
      await _client
          .from('chat_messages')
          .insert({
            'session_id': sessionId,
            'content': content,
            'is_user': isUser,
            'has_code': hasCode,
            'created_at': now,
          });
      
      // Update the session's updated_at timestamp
      await _client
          .from('chat_sessions')
          .update({'updated_at': now})
          .eq('id', sessionId);
      
      return true;
    } catch (e) {
      print('Error saving chat message: $e');
      return false;
    }
  }
  
  // Get all messages for a specific chat session
  Future<List<Map<String, dynamic>>> getChatMessages(String sessionId) async {
    try {
      final response = await _client
          .from('chat_messages')
          .select()
          .eq('session_id', sessionId)
          .order('created_at', ascending: true);
      
      // Convert UTC timestamps to IST for display
      final messages = List<Map<String, dynamic>>.from(response);
      for (var message in messages) {
        // Add IST timestamp for display
        final createdAt = DateTime.parse(message['created_at']);
        
        // Add 5 hours and 30 minutes to convert UTC to IST
        message['created_at_ist'] = createdAt.add(const Duration(hours: 5, minutes: 30)).toIso8601String();
        
        // Keep original timestamp for database operations
        message['created_at'] = message['created_at'];
      }
      
      return messages;
    } catch (e) {
      print('Error getting chat messages: $e');
      return [];
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // Get current user
  User? get currentUser => _client.auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Get session
  Session? get currentSession => _client.auth.currentSession;
}
