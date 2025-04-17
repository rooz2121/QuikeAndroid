import 'package:flutter/material.dart';

class TextEnhancer {
  // Regular expression for bold text only
  static final RegExp _boldRegex = RegExp(r'\*\*(.*?)\*\*');
  
  // Build a RichText widget that only formats bold text
  static Widget buildRichText(String text, {TextStyle? baseStyle}) {
    final baseTextStyle = baseStyle ?? const TextStyle(
      color: Colors.white,
      fontSize: 15,
    );
    
    final boldStyle = baseTextStyle.copyWith(
      fontWeight: FontWeight.bold,
    );
    
    // If no bold formatting, return regular text
    if (!text.contains('**')) {
      return Text(text, style: baseTextStyle);
    }
    
    // Find all bold text matches
    final matches = _boldRegex.allMatches(text).toList();
    final List<TextSpan> spans = [];
    int lastIndex = 0;
    
    for (final match in matches) {
      // Add text before the bold part
      if (match.start > lastIndex) {
        final beforeText = text.substring(lastIndex, match.start);
        spans.add(TextSpan(text: beforeText, style: baseTextStyle));
      }
      
      // Add the bold text (without the ** markers)
      final boldText = match.group(1)!;
      spans.add(TextSpan(text: boldText, style: boldStyle));
      
      lastIndex = match.end;
    }
    
    // Add any remaining text after the last bold part
    if (lastIndex < text.length) {
      final afterText = text.substring(lastIndex);
      spans.add(TextSpan(text: afterText, style: baseTextStyle));
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
