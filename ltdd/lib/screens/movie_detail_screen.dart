import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/movie.dart';
import '../models/movie_rating.dart';
import '../models/movie_comment.dart';
import '../models/user.dart';
import '../models/cinema.dart';
import '../services/database_services.dart';
import '../services/points_service.dart';
import '../utils/age_utils.dart';
import '../widgets/age_restriction_dialog.dart';
import '../widgets/auth_guard.dart';
import 'showtimes_screen.dart';
import '../widgets/trailer_dialog.dart';
import 'user_info_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final String movieId;
  final String? cinemaId; // ID của rạp đã chọn
  const MovieDetailScreen({super.key, required this.movieId, this.cinemaId});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  MovieModel? _movie;
  bool _isExpanded = false;
  double _averageRating = 0.0;
  int _ratingCount = 0;
  double? _userRating;
  List<MovieComment> _comments = [];
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = true;
  String? _userId;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _loadData();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    if (_userId != null) {
      try {
        _user = await DatabaseService().getUser(_userId!);
        setState(() {});
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _movie = await DatabaseService().getMovie(widget.movieId);
      if (_userId != null) {
        _user = await DatabaseService().getUser(_userId!);
        final userRatings = await DatabaseService().getRatingsByMovieAndUser(widget.movieId, _userId!);
        if (userRatings.isNotEmpty) {
          _userRating = userRatings.first.rating;
        }
      }
      final ratings = await DatabaseService().getRatingsByMovie(widget.movieId);
      _ratingCount = ratings.length;
      if (ratings.isNotEmpty) {
        _averageRating = ratings.fold(0.0, (sum, r) => sum + r.rating) / ratings.length;
      }
      _comments = await DatabaseService().getCommentsByMovie(widget.movieId);
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_movie == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE50914)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildMovieInfo(),
                _buildTrailerSection(),
                _buildUserRatingSection(),
                _buildDescription(),
                _buildCommentsSection(),
                _buildBookButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 500,
      pinned: true,
      backgroundColor: const Color(0xFF0F0F0F),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {},
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {},
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: _movie!.posterUrl,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0F0F0F).withOpacity(0.7),
                    const Color(0xFF0F0F0F),
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _movie!.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE50914),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _movie!.genre.split(',').first.trim(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${_movie!.duration} phút',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(Icons.calendar_today, 'Năm',
              DateTime.fromMillisecondsSinceEpoch(_movie!.releaseDate ?? 0).year.toString()),
          _buildInfoItem(Icons.play_circle_outline, 'Trailer', _movie!.trailerUrl != null ? 'Xem' : 'N/A'),
          _buildInfoItem(Icons.hd, 'Chất lượng', 'HD'),
        ],
      ),
    );
  }

  Widget _buildTrailerSection() {
    if (_movie?.trailerUrl == null || _movie!.trailerUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: InkWell(
        onTap: () {
          TrailerDialog.show(context, _movie!.trailerUrl!);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xem Trailer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Xem trailer trước khi đặt vé',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserRatingSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        children: [
          // Average rating display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  RatingBarIndicator(
                    rating: _averageRating,
                    itemBuilder: (context, index) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    itemCount: 5,
                    itemSize: 24.0,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _averageRating > 0 ? '${_averageRating.toStringAsFixed(1)}/5.0' : 'Chưa có đánh giá',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                height: 50,
                width: 1,
                color: const Color(0xFF2A2A2A),
              ),
              Column(
                children: [
                  const Icon(Icons.people, color: Color(0xFFE50914), size: 30),
                  const SizedBox(height: 8),
                  Text(
                    '$_ratingCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Đánh giá',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFF2A2A2A)),
          const SizedBox(height: 16),
          // User rating input
          if (_userId != null) ...[
            Text(
              _userRating != null ? 'Đánh giá của bạn' : 'Đánh giá phim này',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            RatingBar.builder(
              initialRating: _userRating ?? 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) async {
                if (_userId != null) {
                  try {
                    // Kiểm tra xem đã đánh giá chưa
                    final existingRatings = await DatabaseService().getRatingsByMovieAndUser(widget.movieId, _userId!);
                    final isNewRating = existingRatings.isEmpty;
                    
                    final movieRating = MovieRating(
                      id: '',
                      movieId: widget.movieId,
                      userId: _userId!,
                      rating: rating,
                      createdAt: DateTime.now().millisecondsSinceEpoch,
                    );
                    await DatabaseService().saveMovieRating(movieRating);
                    
                    // Tích điểm khi đánh giá phim lần đầu (1-2 điểm ngẫu nhiên)
                    if (isNewRating) {
                      try {
                        await PointsService().addPointsForRating(_userId!);
                      } catch (e) {
                        print('⚠️ Error adding points for rating: $e');
                      }
                    }
                    
                    await _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isNewRating ? 'Đã lưu đánh giá và nhận điểm thưởng!' : 'Đã cập nhật đánh giá của bạn'),
                          backgroundColor: const Color(0xFF4CAF50),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi: $e'),
                          backgroundColor: const Color(0xFFE50914),
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ] else
            const Text(
              'Đăng nhập để đánh giá phim',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    final isTrailer = label == 'Trailer' && value == 'Xem';
    return InkWell(
      onTap: isTrailer && _movie?.trailerUrl != null
          ? () {
              TrailerDialog.show(context, _movie!.trailerUrl!);
            }
          : null,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFE50914), size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTrailer ? const Color(0xFFE50914) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              decoration: isTrailer ? TextDecoration.underline : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bình Luận',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Comment input
          if (_userId != null) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Viết bình luận...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _commentController.text.trim().isEmpty ? null : _submitComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914),
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          // Comments list
          if (_comments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'Chưa có bình luận nào',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final comment = _comments[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFE50914),
                            radius: 20,
                            child: Text(
                              comment.userName.isNotEmpty
                                  ? comment.userName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment.userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _formatDate(comment.createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_userId == comment.userId)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _deleteComment(comment.id),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        comment.content,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} năm trước';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} tháng trước';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  Future<void> _submitComment() async {
    if (_userId == null || _user == null) return;
    if (_commentController.text.trim().isEmpty) return;

    try {
      final comment = MovieComment(
        id: '',
        movieId: widget.movieId,
        userId: _userId!,
        userName: _user!.name,
        content: _commentController.text.trim(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await DatabaseService().saveMovieComment(comment);
      _commentController.clear();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm bình luận'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: const Color(0xFFE50914),
          ),
        );
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await DatabaseService().deleteMovieComment(commentId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa bình luận'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: const Color(0xFFE50914),
          ),
        );
      }
    }
  }

  Widget _buildDescription() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mô Tả',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            firstChild: Text(
              _movie!.description,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            secondChild: Text(
              _movie!.description,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
          TextButton(
            onPressed: () {
              setState(() => _isExpanded = !_isExpanded);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isExpanded ? 'Thu gọn' : 'Xem thêm',
                  style: const TextStyle(color: Color(0xFFE50914)),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xFFE50914),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBookButton() async {
    // Kiểm tra authentication trước
    final user = FirebaseAuth.instance.currentUser;
    
    // Nếu chưa đăng nhập, yêu cầu đăng nhập và quay lại trang phim này
    if (user == null) {
      // Tạo returnPath để quay lại MovieDetailScreen sau khi đăng nhập
      String returnPath = 'movie:${widget.movieId}';
      if (widget.cinemaId != null && widget.cinemaId!.isNotEmpty) {
        returnPath += ':${widget.cinemaId}';
      }
      
      final isAuthenticated = await AuthGuard.requireAuth(
        context,
        returnPath: returnPath,
      );
      if (!isAuthenticated || !mounted) return;
      
      // Sau khi đăng nhập, reload user data và tiếp tục
      _userId = FirebaseAuth.instance.currentUser?.uid;
      if (_userId != null) {
        try {
          _user = await DatabaseService().getUser(_userId!);
        } catch (e) {
          print('Error loading user after login: $e');
        }
      }
    }
    
    // Từ đây, user đã đăng nhập, tiếp tục logic đặt vé
    
    // Bước 1: Kiểm tra xem đã chọn rạp chưa
    String? selectedCinemaId = widget.cinemaId;
    
    // Nếu chưa chọn rạp, hiển thị dialog chọn rạp
    if (selectedCinemaId == null || selectedCinemaId.isEmpty) {
      selectedCinemaId = await _showCinemaSelectionDialog();
      if (selectedCinemaId == null || !mounted) {
        // User đã hủy chọn rạp
        return;
      }
    }
    
    // Bước 2: Kiểm tra ngày sinh của user (bắt buộc để đặt vé)
    if (_user?.dateOfBirth == null) {
      // User chưa có ngày sinh, hiển thị dialog yêu cầu cập nhật
      final shouldProceed = await _showDateOfBirthDialog();
      if (!shouldProceed) {
        return; // Người dùng hủy hoặc chọn để sau
      }
      // Sau khi cập nhật, reload user data
      if (_userId != null && mounted) {
        try {
          _user = await DatabaseService().getUser(_userId!);
          if (_user?.dateOfBirth == null) {
            // Vẫn chưa có ngày sinh sau khi quay lại
            return;
          }
        } catch (e) {
          print('Error reloading user data: $e');
          return;
        }
      } else {
        return;
      }
    }
    
    // Bước 3: Kiểm tra độ tuổi nếu phim có age rating (sau khi đã có ngày sinh)
    if (_movie?.ageRating != null && _movie!.ageRating!.isNotEmpty) {
      final requiredAge = AgeUtils.parseAgeRating(_movie!.ageRating);
      
      // Nếu có yêu cầu tuổi (không phải P - Phổ thông)
      if (requiredAge != null && requiredAge > 0) {
        // Lấy tuổi của user (đã đảm bảo có dateOfBirth ở bước trên)
        final userAge = AgeUtils.calculateAge(_user!.dateOfBirth);
        
        if (userAge != null && userAge < requiredAge) {
          // Hiển thị dialog cảnh báo
          final shouldContinue = await AgeRestrictionDialog.show(
            context: context,
            userAge: userAge,
            requiredAge: requiredAge,
          );
          
          // Nếu user chọn "Trở lại", không làm gì
          if (!shouldContinue) {
            return;
          }
          // Nếu user chọn "Tôi vẫn muốn xem", tiếp tục đặt vé
        }
      }
    }
    
    // Bước 4: Điều hướng đến màn hình chọn lịch chiếu
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShowtimesScreen(
            movieId: widget.movieId,
            cinemaId: selectedCinemaId,
          ),
        ),
      );
    }
  }

  Future<bool> _showDateOfBirthDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFFE50914), size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cập nhật thông tin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Vui lòng cập nhật ngày sinh trong thông tin cá nhân để có thể đặt vé phim có độ tuổi xem.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Để sau',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true); // Trả về true để điều hướng
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
            ),
            child: const Text(
              'Cập nhật ngay',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    // Nếu người dùng chọn "Cập nhật ngay", điều hướng đến UserInfoScreen
    if (result == true) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const UserInfoScreen(),
        ),
      );
      
      // Sau khi quay lại, reload user data
      if (_userId != null && mounted) {
        try {
          _user = await DatabaseService().getUser(_userId!);
          setState(() {}); // Update UI
          return _user?.dateOfBirth != null; // Trả về true nếu đã cập nhật
        } catch (e) {
          print('Error reloading user data: $e');
          return false;
        }
      }
    }
    
    return false;
  }

  Future<String?> _showCinemaSelectionDialog() async {
    try {
      // Load danh sách rạp
      final cinemas = await DatabaseService().getAllCinemas();
      
      if (cinemas.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hiện chưa có rạp chiếu nào. Vui lòng thử lại sau.'),
              backgroundColor: Color(0xFFE50914),
            ),
          );
        }
        return null;
      }

      // Hiển thị bottom sheet để chọn rạp
      return await showModalBottomSheet<String>(
        context: context,
        backgroundColor: const Color(0xFF1A1A1A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _CinemaSelectionBottomSheet(cinemas: cinemas),
      );
    } catch (e) {
      print('Error loading cinemas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách rạp: ${e.toString()}'),
            backgroundColor: const Color(0xFFE50914),
          ),
        );
      }
      return null;
    }
  }

  Widget _buildBookButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE50914), Color(0xFFB20710)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE50914).withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _handleBookButton,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_seat, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text(
              'ĐẶT VÉ NGAY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget bottom sheet để chọn rạp
class _CinemaSelectionBottomSheet extends StatelessWidget {
  final List<CinemaModel> cinemas;

  const _CinemaSelectionBottomSheet({required this.cinemas});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn Rạp Chiếu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.grey, height: 1),
          // List cinemas
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: cinemas.length,
              itemBuilder: (context, index) {
                final cinema = cinemas[index];
                return _buildCinemaItem(context, cinema);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCinemaItem(BuildContext context, CinemaModel cinema) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context, cinema.id),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Cinema icon/image
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE50914).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.theaters,
                    color: Color(0xFFE50914),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Cinema info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cinema.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (cinema.address != null && cinema.address!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          cinema.address!,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}