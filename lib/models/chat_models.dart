import '../utils/date_time_utils.dart';

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory ChatSession.fromJson(Map<String, dynamic> json) {
    // Use the IST timestamps if available, otherwise convert the UTC timestamps
    final createdAt = json.containsKey('created_at_ist')
        ? DateTime.parse(json['created_at_ist'])
        : DateTimeUtils.supabaseTimestampToIndiaTime(json['created_at']);
        
    final updatedAt = json.containsKey('updated_at_ist')
        ? DateTime.parse(json['updated_at_ist'])
        : DateTimeUtils.supabaseTimestampToIndiaTime(json['updated_at']);
        
    return ChatSession(
      id: json['id'],
      title: json['title'],
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ChatMessageModel {
  final String? id;
  final String sessionId;
  final String content;
  final bool isUser;
  final DateTime createdAt;
  final bool hasCode;
  
  ChatMessageModel({
    this.id,
    required this.sessionId,
    required this.content,
    required this.isUser,
    required this.createdAt,
    this.hasCode = false,
  });
  
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    // Use the IST timestamp if available, otherwise convert the UTC timestamp
    final createdAt = json.containsKey('created_at_ist')
        ? DateTime.parse(json['created_at_ist'])
        : DateTimeUtils.supabaseTimestampToIndiaTime(json['created_at']);
        
    return ChatMessageModel(
      id: json['id'],
      sessionId: json['session_id'],
      content: json['content'],
      isUser: json['is_user'],
      createdAt: createdAt,
      hasCode: json['has_code'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'content': content,
      'is_user': isUser,
      'created_at': createdAt.toIso8601String(),
      'has_code': hasCode,
    };
  }
  
  // Convert to a map that can be used to create a ChatMessage
  Map<String, dynamic> toMessageMap() {
    return {
      'text': content,
      'isUser': isUser,
      'timestamp': createdAt,
    };
  }
}
