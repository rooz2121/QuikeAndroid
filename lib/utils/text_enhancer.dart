import 'package:flutter/material.dart';

class TextEnhancer {
  // Regular expression for bold text
  static final RegExp _boldRegex = RegExp(r'\*\*(.*?)\*\*');
  
  // Build a RichText widget that formats text with various formatting
  static Widget buildRichText(String text, {TextStyle? baseStyle}) {
    final baseTextStyle = baseStyle ?? const TextStyle(
      color: Colors.white,
      fontSize: 15,
    );
    
    final boldStyle = baseTextStyle.copyWith(
      fontWeight: FontWeight.bold,
    );
    
    // Clean up the text by replacing special symbols with standard bullet markers
    String cleanedText = _preprocessText(text);
    
    // Check if text contains any kind of bullet points
    if (_containsBulletPoints(cleanedText)) {
      return _buildFormattedText(cleanedText, baseTextStyle, boldStyle);
    }
    
    // If no bullet points but has bold formatting
    if (cleanedText.contains('**')) {
      return _buildBoldText(cleanedText, baseTextStyle, boldStyle);
    }
    
    // Plain text, no formatting
    return Text(cleanedText, style: baseTextStyle);
  }
  
  // Preprocess text to normalize bullet points
  static String _preprocessText(String text) {
    // Replace special symbols with standard bullet markers
    String result = text;
    
    // Replace all åXX patterns (like åtc, åiC, å1C) with a standard bullet marker
    result = result.replaceAllMapped(
      RegExp(r'^\s*å[A-Za-z0-9]{2}\s+', multiLine: true), 
      (match) => '• '
    );
    
    // Replace parenthetical symbols like (åjC) with nothing
    result = result.replaceAll(RegExp(r'\(å[A-Za-z0-9]{2}\)'), '');
    
    // Replace + at the beginning of lines with a standard bullet marker
    result = result.replaceAllMapped(
      RegExp(r'^\s*\+\s+', multiLine: true), 
      (match) => '• '
    );
    
    // Replace * at the beginning of lines with a standard bullet marker, even if not followed by space
    result = result.replaceAllMapped(
      RegExp(r'^\s*\*(?:\s+|(?=[^\s]))', multiLine: true), 
      (match) => '• '
    );
    
    // Handle lines that are part of a list but don't have a bullet marker
    // This is more complex and requires context analysis
    result = _handleUnmarkedListItems(result);
    
    return result;
  }
  
  // Check if text contains any kind of bullet points
  static bool _containsBulletPoints(String text) {
    return text.contains(RegExp(r'^\s*[•+]\s', multiLine: true)) || 
           text.contains(RegExp(r'^\s*\*', multiLine: true)) || 
           text.contains(RegExp(r'å[A-Za-z0-9]{2}\s+')) ||
           text.contains(RegExp(r'\(å[A-Za-z0-9]{2}\)'));
  }
  
  // Build formatted text with bullet points and possibly bold text
  // Helper method to handle lines that are part of a list but don't have a bullet marker
  static String _handleUnmarkedListItems(String text) {
    final lines = text.split('\n');
    final List<String> processedLines = [];
    bool inList = false;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Check if this is a bullet point line
      if (line.startsWith('• ') || 
          RegExp(r'^\s*å[A-Za-z0-9]{2}\s+').hasMatch(line) || 
          line.startsWith('*') || 
          line.startsWith('+ ')) {
        // We're in a list now
        inList = true;
        processedLines.add(lines[i]);
      } 
      // Check if this might be an unmarked list item in a list context
      else if (inList && 
               line.isNotEmpty && 
               !line.startsWith('•') &&
               // Check if the line doesn't start with common non-list markers
               !line.startsWith('What') && 
               !line.startsWith('Types') && 
               !line.startsWith('Best') &&
               // Avoid headers or questions
               !line.endsWith('?') &&
               !line.endsWith(':')) {
        // This looks like an unmarked list item, add a bullet
        processedLines.add('• $line');
      } else {
        // Not a list item or end of list
        if (line.endsWith(':') || line.endsWith('?')) {
          inList = false; // Reset list state for headers or questions
        }
        processedLines.add(lines[i]);
      }
    }
    
    return processedLines.join('\n');
  }
  
  static Widget _buildFormattedText(String text, TextStyle baseStyle, TextStyle boldStyle) {
    // Split the text into lines
    final lines = text.split('\n');
    final List<Widget> lineWidgets = [];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Check if this line is a bullet point
      if (line.startsWith('• ') || line.startsWith('*') || line.startsWith('+ ')) {
        // Extract the content after the bullet
        final bulletContent = line.startsWith('*') && !line.startsWith('* ') 
            ? line.substring(1) // For asterisks without space
            : line.substring(line.indexOf(' ') + 1);
        
        lineWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Colors.white, fontSize: 15)),
                Expanded(
                  child: bulletContent.contains('**') 
                      ? _buildBoldText(bulletContent, baseStyle, boldStyle)
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
            padding: const EdgeInsets.only(bottom: 6.0),
            child: line.contains('**')
                ? _buildBoldText(line, baseStyle, boldStyle)
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
  
  // Helper method to build text with bold formatting
  static Widget _buildBoldText(String text, TextStyle baseStyle, TextStyle boldStyle) {
    // Find all bold text matches
    final matches = _boldRegex.allMatches(text).toList();
    final List<TextSpan> spans = [];
    int lastIndex = 0;
    
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
}
