import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class DateTimeUtils {
  static bool _initialized = false;
  
  // Initialize timezone data
  static void initialize() {
    if (!_initialized) {
      tz_data.initializeTimeZones();
      _initialized = true;
    }
  }
  
  // Get current time in India timezone (UTC+5:30)
  static DateTime nowInIndia() {
    initialize();
    final india = tz.getLocation('Asia/Kolkata');
    return tz.TZDateTime.now(india);
  }
  
  // Get current time in India timezone as ISO8601 string with timezone offset
  static String nowInIndiaIso8601() {
    final now = nowInIndia();
    // Format: 2025-04-17T15:42:25+05:30
    return now.toIso8601String();
  }
  
  // Get current time in India timezone as a Supabase-compatible timestamp
  // Since Supabase stores in UTC internally, we'll explicitly add the timezone offset
  static String nowForSupabase() {
    final now = nowInIndia();
    // Format with explicit timezone offset: YYYY-MM-DDTHH:MM:SS+05:30
    return now.toIso8601String();
  }
  
  // Convert a UTC timestamp from Supabase to India time for display
  static DateTime supabaseTimestampToIndiaTime(String timestamp) {
    // Parse the timestamp (Supabase returns UTC timestamps)
    final utcTime = DateTime.parse(timestamp);
    // Convert to India time
    return toIndiaTime(utcTime);
  }
  
  // Convert any DateTime to India timezone
  static DateTime toIndiaTime(DateTime dateTime) {
    initialize();
    final india = tz.getLocation('Asia/Kolkata');
    return tz.TZDateTime.from(dateTime, india);
  }
  
  // Format date for display
  static String formatDate(DateTime dateTime) {
    final now = nowInIndia();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (dateToCheck == today) {
      return 'Today, ${formatTime(dateTime)}';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday, ${formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}, ${formatTime(dateTime)}';
    }
  }
  
  // Format time for display
  static String formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
