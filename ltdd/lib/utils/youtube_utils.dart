/// Utility functions for working with YouTube URLs
class YoutubeUtils {
  /// Extract YouTube video ID from various YouTube URL formats
  /// 
  /// Supports:
  /// - https://www.youtube.com/watch?v=VIDEO_ID
  /// - https://youtu.be/VIDEO_ID
  /// - https://www.youtube.com/embed/VIDEO_ID
  /// - https://m.youtube.com/watch?v=VIDEO_ID
  /// - youtube://watch?v=VIDEO_ID (YouTube app URL)
  /// - VIDEO_ID (already an ID)
  static String? extractVideoId(String url) {
    if (url.isEmpty) return null;

    print('🎬 Extracting video ID from: $url');

    // If it's already just an ID (no URL format)
    if (!url.contains('youtube') && !url.contains('youtu.be') && 
        !url.contains('http') && !url.contains('youtube://') && 
        !url.contains('/') && !url.contains('?')) {
      print('✅ Video ID (direct): $url');
      return url;
    }

    // Try to parse as URI
    try {
      final uri = Uri.parse(url);
      
      // Format: youtube://watch?v=VIDEO_ID (YouTube app URL)
      if (uri.scheme == 'youtube' && uri.queryParameters.containsKey('v')) {
        final videoId = uri.queryParameters['v'];
        print('✅ Video ID from youtube://: $videoId');
        return videoId;
      }
      
      // Format: https://www.youtube.com/watch?v=VIDEO_ID
      if ((uri.host.contains('youtube.com') || uri.host.contains('m.youtube.com')) && 
          uri.queryParameters.containsKey('v')) {
        final videoId = uri.queryParameters['v'];
        print('✅ Video ID from https://youtube.com: $videoId');
        return videoId;
      }
      
      // Format: https://youtu.be/VIDEO_ID
      if (uri.host == 'youtu.be') {
        final segments = uri.pathSegments;
        if (segments.isNotEmpty) {
          final videoId = segments.first;
          print('✅ Video ID from youtu.be: $videoId');
          return videoId;
        }
      }
      
      // Format: https://www.youtube.com/embed/VIDEO_ID
      if (uri.host.contains('youtube.com') && uri.path.contains('/embed/')) {
        final segments = uri.pathSegments;
        final embedIndex = segments.indexOf('embed');
        if (embedIndex != -1 && embedIndex < segments.length - 1) {
          final videoId = segments[embedIndex + 1];
          print('✅ Video ID from embed: $videoId');
          return videoId;
        }
      }
      
      // Try to extract from path if it looks like an ID
      if (uri.pathSegments.isNotEmpty) {
        final lastSegment = uri.pathSegments.last;
        // YouTube video IDs are typically 11 characters
        if (lastSegment.length == 11 && RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(lastSegment)) {
          print('✅ Video ID from path: $lastSegment');
          return lastSegment;
        }
      }
    } catch (e) {
      print('❌ Error parsing YouTube URL: $e');
    }

    print('❌ Could not extract video ID from: $url');
    return null;
  }

  /// Check if a URL is a valid YouTube URL
  static bool isValidYoutubeUrl(String url) {
    return extractVideoId(url) != null;
  }

  /// Generate YouTube embed URL from a YouTube URL or video ID
  /// Returns a URL that can be used in an iframe/WebView
  static String? getEmbedUrl(String url) {
    final videoId = extractVideoId(url);
    if (videoId == null) return null;
    
    // Thử với youtube.com với các parameters để tự động phát và tránh lỗi
    return 'https://www.youtube.com/embed/$videoId?autoplay=1&mute=0&rel=0&modestbranding=1&playsinline=1&controls=1&showinfo=0&iv_load_policy=3';
  }

  /// Get YouTube watch URL (for opening in YouTube app or browser)
  static String? getWatchUrl(String url) {
    final videoId = extractVideoId(url);
    if (videoId == null) return null;
    
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  /// Get YouTube mobile app URL (youtube:// protocol)
  static String? getAppUrl(String url) {
    final videoId = extractVideoId(url);
    if (videoId == null) return null;
    
    return 'youtube://watch?v=$videoId';
  }
}

