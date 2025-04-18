import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'text_enhancer.dart';

class CodeHighlighter {
  static final RegExp _codeBlockRegex = RegExp(
    r'```(?:(\w+)\n)?([\s\S]*?)```',
    multiLine: true,
  );
  
  static final RegExp _inlineCodeRegex = RegExp(r'`([^`]+)`');
  
  // Map of language names to their common aliases
  static final Map<String, String> _languageAliases = {
    'javascript': 'js',
    'typescript': 'ts',
    'python': 'py',
    'csharp': 'cs',
    // Add more aliases as needed
  };
  
  // Detect if a string contains code blocks and parse them
  static List<MessageSegment> parseMessageWithCode(String message) {
    final List<MessageSegment> segments = [];
    int lastIndex = 0;
    
    // Find code blocks (```code```)
    for (final Match match in _codeBlockRegex.allMatches(message)) {
      final int startIndex = match.start;
      final int endIndex = match.end;
      
      // Add text before code block
      if (startIndex > lastIndex) {
        final String textBefore = message.substring(lastIndex, startIndex);
        if (textBefore.trim().isNotEmpty) {
          segments.add(TextSegment(textBefore));
        }
      }
      
      // Extract language and code
      String? language = match.group(1)?.toLowerCase();
      final String code = match.group(2) ?? '';
      
      // Normalize language name
      if (language != null) {
        language = _languageAliases[language] ?? language;
      }
      
      segments.add(CodeSegment(code, language: language));
      lastIndex = endIndex;
    }
    
    // Add remaining text after last code block
    if (lastIndex < message.length) {
      final String remainingText = message.substring(lastIndex);
      
      // Process inline code in the remaining text
      if (remainingText.contains('`')) {
        int lastInlineIndex = 0;
        final List<MessageSegment> inlineSegments = [];
        
        for (final Match match in _inlineCodeRegex.allMatches(remainingText)) {
          final int startIndex = match.start;
          final int endIndex = match.end;
          
          // Add text before inline code
          if (startIndex > lastInlineIndex) {
            final String textBefore = remainingText.substring(lastInlineIndex, startIndex);
            if (textBefore.isNotEmpty) {
              inlineSegments.add(TextSegment(textBefore));
            }
          }
          
          // Add inline code
          final String code = match.group(1) ?? '';
          inlineSegments.add(InlineCodeSegment(code));
          lastInlineIndex = endIndex;
        }
        
        // Add remaining text after last inline code
        if (lastInlineIndex < remainingText.length) {
          final String textAfter = remainingText.substring(lastInlineIndex);
          if (textAfter.isNotEmpty) {
            inlineSegments.add(TextSegment(textAfter));
          }
        }
        
        segments.addAll(inlineSegments);
      } else if (remainingText.isNotEmpty) {
        segments.add(TextSegment(remainingText));
      }
    }
    
    return segments;
  }
}

// Base class for message segments
abstract class MessageSegment {
  Widget buildWidget(BuildContext context);
}

// Regular text segment
class TextSegment extends MessageSegment {
  final String text;
  
  TextSegment(this.text);
  
  @override
  Widget buildWidget(BuildContext context) {
    // Check if text contains bold formatting (**text**)  
    if (text.contains('**')) {
      // Use TextEnhancer to format only the bold text
      return TextEnhancer.buildRichText(
        text,
        baseStyle: const TextStyle(
          color: Colors.white,
          fontSize: 15,
        ),
      );
    } else {
      // Regular text without formatting
      return Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
        ),
      );
    }
  }
}

  // Code block segment
class CodeSegment extends MessageSegment {
  final String code;
  final String? language;
  
  CodeSegment(this.code, {this.language});
  
  @override
  Widget buildWidget(BuildContext context) {
    // Normalize language code for the highlighter
    String lang = language?.toLowerCase() ?? 'plaintext';
    
    // Map common language names to ones supported by highlight.js
    final Map<String, String> languageMapping = {
      'py': 'python',
      'js': 'javascript',
      'ts': 'typescript',
      'jsx': 'javascript',
      'tsx': 'typescript',
      'csharp': 'cs',
      'c#': 'cs',
      'sh': 'bash',
      'shell': 'bash',
      'yml': 'yaml',
      'rust': 'rust',
      'rs': 'rust',
      'go': 'go',
      'golang': 'go',
      'rb': 'ruby',
      'kt': 'kotlin',
      'plaintext': 'plaintext',
      'txt': 'plaintext',
      'json': 'json',
      'xml': 'xml',
      'html': 'html',
      'css': 'css',
      'scss': 'scss',
      'md': 'markdown',
      'sql': 'sql',
      'php': 'php',
      'java': 'java',
      'swift': 'swift',
      'c': 'c',
      'cpp': 'cpp',
      'c++': 'cpp',
      'dart': 'dart',
      'dockerfile': 'dockerfile',
    };
    
    // Use the mapped language or the original if not found
    lang = languageMapping[lang] ?? lang;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language header with copy button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language != null ? language! : 'Code',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  color: Colors.grey[400],
                  onPressed: () {
                    // Copy code to clipboard
                    Clipboard.setData(ClipboardData(text: code));
                    
                    // Show a snackbar to indicate copied
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Code copied to clipboard'),
                        backgroundColor: Colors.blueAccent,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  padding: EdgeInsets.zero,
                  splashRadius: 16,
                ),
              ],
            ),
          ),
          // Code content with syntax highlighting
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 2000, // Large enough to avoid wrapping in most cases
              child: HighlightView(
                code,
                language: lang,
                theme: atomOneDarkTheme,
                padding: const EdgeInsets.all(12),
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Inline code segment
class InlineCodeSegment extends MessageSegment {
  final String code;
  
  InlineCodeSegment(this.code);
  
  @override
  Widget buildWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        code,
        style: const TextStyle(
          color: Color(0xFFE0E0E0), // Light gray for better readability
          fontSize: 14,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
