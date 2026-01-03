import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/youtube_utils.dart';
import '../utils/dialog_helper.dart';

class TrailerScreen extends StatefulWidget {
  final String trailerUrl;
  
  const TrailerScreen({super.key, required this.trailerUrl});

  @override
  State<TrailerScreen> createState() => _TrailerScreenState();
}

class _TrailerScreenState extends State<TrailerScreen> {
  YoutubePlayerController? _youtubeController;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();
    _checkInternetAndInitialize();
  }

  Future<void> _checkInternetAndInitialize() async {
    // Kiểm tra kết nối internet
    final connectivityResult = await Connectivity().checkConnectivity();
    _hasInternet = !connectivityResult.contains(ConnectivityResult.none);
    
    if (!_hasInternet) {
      setState(() {
        _errorMessage = 'Không có kết nối internet. Vui lòng kiểm tra kết nối mạng của máy ảo.';
        _isLoading = false;
      });
      return;
    }

    _initializePlayer();
  }

  void _initializePlayer() {
    // Extract video ID from YouTube URL
    final videoId = YoutubeUtils.extractVideoId(widget.trailerUrl);
    
    if (videoId == null) {
      setState(() {
        _errorMessage = 'URL trailer không hợp lệ. Vui lòng kiểm tra lại URL YouTube.';
        _isLoading = false;
      });
      return;
    }

    print('🎬 Initializing YouTube player with video ID: $videoId');

    try {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true, // Tự động phát khi mở
          mute: false, // Không tắt tiếng
          enableCaption: true, // Bật phụ đề nếu có
          loop: false, // Không lặp lại
          isLive: false,
          forceHD: false, // Không force HD để tránh lỗi trên máy ảo
          controlsVisibleAtStart: true, // Hiển thị controls ngay từ đầu
        ),
      );

      // Listen to player state changes
      _youtubeController!.addListener(_playerListener);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error initializing YouTube player: $e');
      setState(() {
        _errorMessage = 'Không thể khởi tạo player. Vui lòng kiểm tra kết nối internet.';
        _isLoading = false;
      });
    }
  }

  void _playerListener() {
    if (_youtubeController!.value.hasError) {
      final error = _youtubeController!.value.errorCode;
      print('❌ YouTube player error: $error');
      setState(() {
        // Kiểm tra loại lỗi dựa trên error code
        // Error code thường là string mô tả lỗi
        final errorString = error?.toString().toLowerCase() ?? '';
        if (errorString.contains('network') || 
            errorString.contains('internet') ||
            errorString.contains('connection') ||
            errorString.contains('timeout')) {
          _errorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra internet của máy ảo.';
        } else {
          _errorMessage = 'Lỗi phát video: ${error ?? "Không xác định"}';
        }
      });
    }
  }

  @override
  void dispose() {
    _youtubeController?.removeListener(_playerListener);
    _youtubeController?.dispose();
    super.dispose();
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
        actions: [
          if (_youtubeController != null)
            IconButton(
              icon: const Icon(Icons.fullscreen, color: Colors.white),
              onPressed: () {
                _youtubeController!.toggleFullScreenMode();
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE50914),
        ),
      );
    }

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
                onPressed: () async {
                  // Retry initialization
                  await _checkInternetAndInitialize();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              // Nút mở trong trình duyệt nếu không có internet hoặc lỗi
              if (YoutubeUtils.isValidYoutubeUrl(widget.trailerUrl))
                ElevatedButton.icon(
                  onPressed: () async {
                    final watchUrl = YoutubeUtils.getWatchUrl(widget.trailerUrl);
                    if (watchUrl != null) {
                      try {
                        final uri = Uri.parse(watchUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          await DialogHelper.showError(context, 'Không thể mở: $e');
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  icon: const Icon(Icons.open_in_new, color: Colors.white),
                  label: const Text(
                    'Mở trên trình duyệt',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Quay lại',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_youtubeController == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE50914),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Center(
        child: YoutubePlayerBuilder(
          onExitFullScreen: () {
            // Handle exit fullscreen if needed
          },
          player: YoutubePlayer(
            controller: _youtubeController!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: const Color(0xFFE50914),
            progressColors: const ProgressBarColors(
              playedColor: Color(0xFFE50914),
              handleColor: Color(0xFFE50914),
              bufferedColor: Colors.grey,
              backgroundColor: Colors.grey,
            ),
            onReady: () {
              print('✅ YouTube player is ready');
            },
            onEnded: (metadata) {
              print('✅ Video ended');
              // Có thể tự động quay lại hoặc hiển thị thông báo
            },
          ),
          builder: (context, player) {
            return Column(
              children: [
                // Video player với aspect ratio 16:9
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: player,
                      ),
                    ),
                  ),
                ),
                // Thông tin bổ sung (nếu cần)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF1A1A1A),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Vuốt lên/xuống để điều chỉnh âm lượng và độ sáng',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
