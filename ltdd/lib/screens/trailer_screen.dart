import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../utils/youtube_utils.dart';

class TrailerScreen extends StatefulWidget {
  final String trailerUrl;
  
  const TrailerScreen({super.key, required this.trailerUrl});

  @override
  State<TrailerScreen> createState() => _TrailerScreenState();
}

class _TrailerScreenState extends State<TrailerScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final embedUrl = YoutubeUtils.getEmbedUrl(widget.trailerUrl);
    
    if (embedUrl == null) {
      setState(() {
        _errorMessage = 'URL trailer không hợp lệ';
        _isLoading = false;
      });
      return;
    }

    print('🎬 Loading YouTube embed URL: $embedUrl');

    try {
      // Tạo HTML đơn giản với iframe
      final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; }
    html, body { width: 100%; height: 100%; overflow: hidden; background: #000; }
    iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0; }
  </style>
</head>
<body>
  <iframe src="$embedUrl" allowfullscreen></iframe>
</body>
</html>
''';

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..enableZoom(false);

      // Cấu hình platform-specific để tránh error 153
      if (_controller!.platform is AndroidWebViewController) {
        AndroidWebViewController.enableDebugging(false);
        (_controller!.platform as AndroidWebViewController)
          ..setMediaPlaybackRequiresUserGesture(false)
          ..setOnShowFileSelector((params) async {
            return [];
          });
      } else if (_controller!.platform is WebKitWebViewController) {
        (_controller!.platform as WebKitWebViewController)
          ..setAllowsBackForwardNavigationGestures(false);
      }

      _controller!
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              print('📄 Page started loading: $url');
              setState(() {
                _isLoading = true;
              });
            },
            onPageFinished: (String url) {
              print('✅ Page finished loading: $url');
              setState(() {
                _isLoading = false;
              });
            },
            onWebResourceError: (WebResourceError error) {
              print('❌ WebView error: ${error.description} (code: ${error.errorCode})');
              if (error.errorCode == 153 || error.description.contains('153')) {
                // YouTube embed error - có thể video không cho phép embed
                if (mounted) {
                  setState(() {
                    _errorMessage = 'Video này không thể phát trong ứng dụng. Vui lòng xem trên YouTube.';
                  });
                }
              }
            },
          ),
        )
        ..loadHtmlString(htmlContent, baseUrl: 'https://www.youtube.com');

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error initializing WebView: $e');
      setState(() {
        _errorMessage = 'Không thể khởi tạo WebView: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Trailer',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFE50914),
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Quay lại',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE50914),
        ),
      );
    }

    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: WebViewWidget(controller: _controller!),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE50914),
              ),
            ),
          ),
      ],
    );
  }
}
