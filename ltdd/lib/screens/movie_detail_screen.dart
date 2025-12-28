import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/movie.dart';
import '../models/movie_rating.dart';
import '../models/movie_comment.dart';
import '../models/user.dart';
import '../services/database_services.dart';
import '../utils/age_utils.dart';
import '../widgets/age_restriction_dialog.dart';
import '../widgets/auth_guard.dart';
import 'showtimes_screen.dart';

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
        onTap: () async {
          final uri = Uri.parse(_movie!.trailerUrl!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Không thể mở trailer'),
                  backgroundColor: Color(0xFFE50914),
                ),
              );
            }
          }
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
                    final movieRating = MovieRating(
                      id: '',
                      movieId: widget.movieId,
                      userId: _userId!,
                      rating: rating,
                      createdAt: DateTime.now().millisecondsSinceEpoch,
                    );
                    await DatabaseService().saveMovieRating(movieRating);
                    await _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã lưu đánh giá của bạn'),
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
          ? () async {
              final uri = Uri.parse(_movie!.trailerUrl!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
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
    final isAuthenticated = await AuthGuard.requireAuth(context);
    if (!isAuthenticated || !mounted) return;

    // Kiểm tra độ tuổi nếu phim có age rating
    if (_movie?.ageRating != null && _movie!.ageRating!.isNotEmpty) {
      final requiredAge = AgeUtils.parseAgeRating(_movie!.ageRating);
      
      // Nếu có yêu cầu tuổi (không phải P - Phổ thông)
      if (requiredAge != null && requiredAge > 0) {
        // Lấy tuổi của user
        int? userAge;
        if (_user?.dateOfBirth != null) {
          userAge = AgeUtils.calculateAge(_user!.dateOfBirth);
        }
        
        // Kiểm tra nếu user không đủ tuổi
        if (userAge == null) {
          // User chưa có ngày sinh, hiển thị thông báo yêu cầu cập nhật thông tin
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vui lòng cập nhật ngày sinh trong thông tin cá nhân để đặt vé phim có độ tuổi xem'),
                backgroundColor: Color(0xFFE50914),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
        
        if (userAge < requiredAge) {
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
    
    // Điều hướng đến màn hình chọn lịch chiếu
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShowtimesScreen(
            movieId: widget.movieId,
            cinemaId: widget.cinemaId,
          ),
        ),
      );
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