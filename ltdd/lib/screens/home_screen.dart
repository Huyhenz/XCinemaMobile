import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../blocs/movies/movies_bloc.dart';
import '../blocs/movies/movies_event.dart';
import '../blocs/movies/movies_state.dart';
import '../models/movie.dart';
import '../services/database_services.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_widgets.dart';
import '../widgets/hamburger_menu_button.dart';
import '../widgets/navigation_provider.dart';
import '../models/cinema.dart';
import 'movie_detail_screen.dart';
import 'chatbot_screen.dart';
import 'notification_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HomeScreen extends StatefulWidget {
  final String? selectedCinemaId; // ID của rạp đã chọn
  const HomeScreen({super.key, this.selectedCinemaId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  int _unreadNotificationCount = 0;
  Timer? _notificationRefreshTimer;
  Timer? _movieRefreshTimer; // Timer để refresh phim mỗi 30 giây
  PageController? _carouselController;
  Timer? _carouselTimer;
  int _currentCarouselIndex = 0;
  CinemaModel? _selectedCinema;
  List<CinemaModel> _allCinemas = [];
  bool _moviesLoaded = false;
  bool _cinemasLoaded = false;
  bool _isInitialLoad = true; // Flag để track lần load đầu tiên
  List<MovieModel> _carouselMovies = []; // Danh sách phim cho carousel (đang chiếu + sắp chiếu)
  
  @override
  bool get wantKeepAlive => false; // Không giữ state, rebuild mỗi lần vào tab

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadAllCinemas();
    if (widget.selectedCinemaId != null) {
      _loadSelectedCinema();
    }
    // Load notification count
    _loadNotificationCount();
    // Refresh notification count every 30 seconds
    _notificationRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadNotificationCount();
    });
    
    // Refresh movies every 30 seconds (chỉ khi không đang search)
    _movieRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshMoviesIfNotSearching();
    });
  }

  Future<void> _loadAllCinemas() async {
    try {
      final cinemas = await DatabaseService().getAllCinemas();
      if (mounted) {
        setState(() {
          _allCinemas = cinemas;
          _cinemasLoaded = true;
          // Nếu có selectedCinemaId từ widget, tìm và set
          if (widget.selectedCinemaId != null && _selectedCinema == null) {
            _selectedCinema = cinemas.firstWhere(
              (c) => c.id == widget.selectedCinemaId,
              orElse: () => cinemas.isNotEmpty ? cinemas.first : null!,
            );
          }
        });
      }
    } catch (e) {
      print('Error loading cinemas: $e');
      if (mounted) {
        setState(() {
          _cinemasLoaded = true;
        });
      }
    }
  }

  Future<void> _loadSelectedCinema() async {
    if (widget.selectedCinemaId != null) {
      try {
        final cinema = await DatabaseService().getCinema(widget.selectedCinemaId!);
        if (mounted) {
          setState(() {
            _selectedCinema = cinema;
          });
        }
      } catch (e) {
        print('Error loading cinema: $e');
      }
    }
  }

  void _onCinemaChanged(CinemaModel? cinema) {
    setState(() {
      _selectedCinema = cinema;
      // Không reset _moviesLoaded - vẫn giữ danh sách phim hiện tại
      // Chỉ lưu rạp đã chọn để dùng khi đặt vé
    });
    
    // Không reload movies khi chọn rạp - vẫn hiển thị tất cả phim
    // Rạp chỉ dùng để filter khi đặt vé
  }

  // Carousel initialization is now handled in _buildMovieCarousel()

  void _startCarouselAutoScroll() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_carouselController != null && _carouselController!.hasClients && mounted) {
        try {
          if (_carouselMovies.isNotEmpty) {
            final nextPage = (_currentCarouselIndex + 1) % _carouselMovies.length;
            _carouselController!.animateToPage(
              nextPage,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        } catch (e) {
          // Error, stop timer
          timer.cancel();
        }
      }
    });
  }

  Future<void> _loadNotificationCount() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final notifications = await DatabaseService().getNotificationsByUser(userId);
      final unreadCount = notifications.where((n) => (n['isRead'] as bool?) != true).length;

      if (mounted) {
        setState(() {
          _unreadNotificationCount = unreadCount;
        });
      }
    } catch (e) {
      print('Error loading notification count: $e');
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      String category = '';
      switch (_tabController.index) {
        case 0:
          category = 'nowShowing';
          break;
        case 1:
          category = 'comingSoon';
          break;
        case 2:
          category = 'popular';
          break;
      }
      // Load tất cả phim, không filter theo rạp
      try {
        context.read<MovieBloc>().add(
          FilterMoviesByCategory(category, cinemaId: null), // Luôn null để load tất cả phim
        );
      } catch (e) {
        print('Error accessing MovieBloc in _onTabChanged: $e');
      }
      // Carousel will auto-update via BlocBuilder when movies change
    }
  }

  // Refresh movies mỗi 30 giây, chỉ khi không đang search
  void _refreshMoviesIfNotSearching() {
    if (!mounted) return;
    
    try {
      final movieBloc = context.read<MovieBloc>();
      final currentState = movieBloc.state;
      
      // Chỉ refresh nếu không đang search (searchQuery null hoặc empty)
      if (currentState.searchQuery == null || currentState.searchQuery!.isEmpty) {
        String category = 'nowShowing';
        switch (_tabController.index) {
          case 0:
            category = 'nowShowing';
            break;
          case 1:
            category = 'comingSoon';
            break;
          case 2:
            category = 'popular';
            break;
        }
        
        print('🔄 Auto-refresh movies: category=$category (every 30s)');
        movieBloc.add(
          FilterMoviesByCategory(category, cinemaId: null),
        );
      } else {
        print('⏸️ Skip auto-refresh: user is searching (query: "${currentState.searchQuery}")');
      }
    } catch (e) {
      print('Error in _refreshMoviesIfNotSearching: $e');
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    _notificationRefreshTimer?.cancel();
    _movieRefreshTimer?.cancel();
    _carouselTimer?.cancel();
    _carouselController?.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {}); // Update UI to show/hide clear button
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        if (value.isEmpty || value.trim().isEmpty) {
          // Nếu xóa từ khóa, chuyển về tab "Đang Chiếu" và reload lại phim
          // Reload carousel movies khi xóa search
          _carouselMovies = [];
          // Chuyển về tab "Đang Chiếu" (index 0)
          if (_tabController.index != 0) {
            _tabController.animateTo(0);
          }
          // Gọi FilterMoviesByCategory để reload lại tất cả phim ở tab "Đang Chiếu"
          // Bloc sẽ tự động clear searchQuery và reload phim theo category
          context.read<MovieBloc>().add(
            FilterMoviesByCategory('nowShowing', cinemaId: null),
          );
        } else {
          context.read<MovieBloc>().add(SearchMovies(value));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // Load movies chỉ khi vào trang chủ lần đầu (không reload khi carousel thay đổi)
    if (_isInitialLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isInitialLoad) {
          try {
            // Load với tab hiện tại, không filter theo rạp
            String category = 'nowShowing';
            switch (_tabController.index) {
              case 0:
                category = 'nowShowing';
                break;
              case 1:
                category = 'comingSoon';
                break;
              case 2:
                category = 'popular';
                break;
            }
            context.read<MovieBloc>().add(
              FilterMoviesByCategory(category, cinemaId: null), // Luôn null để load tất cả phim
            );
            _isInitialLoad = false; // Đánh dấu đã load lần đầu
          } catch (e) {
            print('Error accessing MovieBloc: $e');
          }
        }
      });
    }

    return BlocListener<MovieBloc, MovieState>(
      listener: (context, state) {
        // Tự động chuyển tab khi search tìm thấy phim
        // Ưu tiên chuyển sang tab "Sắp Chiếu" nếu có phim ở đó
        if (state.category != null && 
            state.searchQuery != null && 
            state.searchQuery!.isNotEmpty &&
            mounted &&
            !state.isLoading &&
            state.movies.isNotEmpty) {
          int targetIndex = 0;
          if (state.category == 'nowShowing') {
            targetIndex = 0;
          } else if (state.category == 'comingSoon') {
            targetIndex = 1; // Tự động chuyển sang tab "Sắp Chiếu"
          } else if (state.category == 'popular') {
            targetIndex = 2;
          }
          
          // Chỉ chuyển tab nếu index khác với index hiện tại và không đang trong quá trình chuyển tab
          if (_tabController.index != targetIndex && !_tabController.indexIsChanging) {
            print('🔄 Auto-switching tab: ${_tabController.index} -> $targetIndex (category: ${state.category}, search: "${state.searchQuery}")');
            print('🔍 Found ${state.movies.length} movies, first movie: ${state.movies.isNotEmpty ? state.movies.first.title : "N/A"}');
            _tabController.animateTo(targetIndex);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: SafeArea(
          bottom: false, // Let bottom padding be handled by SliverPadding
          child: CustomScrollView(
            slivers: [
              _buildHeader(),
              _buildSearchBar(),
              _buildMovieCarousel(),
              _buildTabBar(),
              _buildMovieGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    // Navigate về HomeScreen (index 0) nếu đang ở screen khác trong MainWrapper
                    final navigationProvider = NavigationProvider.of(context);
                    if (navigationProvider != null && navigationProvider.currentIndex != 0) {
                      navigationProvider.navigateTo(0);
                    } else {
                      // Nếu đang ở screen được push lên stack, pop về HomeScreen
                      // Chỉ pop nếu có thể (nếu đang ở HomeScreen thì không làm gì)
                      if (Navigator.canPop(context)) {
                        Navigator.popUntil(context, (route) {
                          // Pop đến khi gặp MainWrapper hoặc root
                          return route.isFirst || route.settings.name == '/';
                        });
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE50914), Color(0xFFB20710), Color(0xFF8B0000)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE50914).withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.movie_filter,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, Color(0xFFFFD700)],
                          ).createShader(bounds),
                          child: const Text(
                            'CINEMA',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                // Chatbot button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatBotScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE50914).withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE50914).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Color(0xFFE50914),
                      size: 22,
                    ),
                  ),
                ),
                // Notification button - chỉ hiển thị nếu đã đăng nhập
                if (FirebaseAuth.instance.currentUser != null)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationScreen()),
                      ).then((_) {
                        _loadNotificationCount();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF4A90E2).withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4A90E2).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.notifications_outlined,
                            color: Color(0xFF4A90E2),
                            size: 22,
                          ),
                          if (_unreadNotificationCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE50914), Color(0xFFB20710)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE50914).withOpacity(0.5),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                _unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Hamburger menu button
                  const HamburgerMenuButton(),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Cinema selector dropdown
            _buildCinemaSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildCinemaSelector() {
    if (!_cinemasLoaded) {
      return const SizedBox.shrink();
    }

    if (_allCinemas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          children: [
            const Icon(Icons.theaters_outlined, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Chưa có rạp chiếu',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE50914).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CinemaModel?>(
          value: _selectedCinema,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFE50914)),
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          hint: Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFE50914), size: 20),
              const SizedBox(width: 8),
              Text(
                'Tất cả rạp',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
          items: [
            // Option "Tất cả rạp"
            DropdownMenuItem<CinemaModel?>(
              value: null,
              child: Row(
                children: [
                  const Icon(Icons.theaters, color: Color(0xFFE50914), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tất cả rạp',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
            // Các rạp
            ..._allCinemas.map((cinema) {
              return DropdownMenuItem<CinemaModel?>(
                value: cinema,
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFFE50914), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cinema.name,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
          onChanged: _onCinemaChanged,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2A2A2A),
                const Color(0xFF1A1A1A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFE50914).withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE50914).withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên phim hoặc thể loại...',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              prefixIcon: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFE50914),
                  size: 24,
                ),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE50914).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Color(0xFFE50914), size: 18),
                      ),
                      tooltip: 'Xóa tìm kiếm',
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                        // Khi xóa từ khóa, chuyển về tab "Đang Chiếu" và reload lại phim
                        // Reload carousel movies khi xóa search
                        _carouselMovies = [];
                        // Chuyển về tab "Đang Chiếu" (index 0)
                        if (_tabController.index != 0) {
                          _tabController.animateTo(0);
                        }
                        // Gọi FilterMoviesByCategory để reload lại tất cả phim ở tab "Đang Chiếu"
                        // Bloc sẽ tự động clear searchQuery và reload phim theo category
                        context.read<MovieBloc>().add(
                          FilterMoviesByCategory('nowShowing', cinemaId: null),
                        );
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2A2A2A),
              const Color(0xFF1A1A1A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFF2A2A2A).withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE50914), Color(0xFFB20710), Color(0xFF8B0000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE50914).withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_outline, size: 16),
                  SizedBox(width: 4),
                  Text('Đang Chiếu', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 16),
                  SizedBox(width: 4),
                  Text('Sắp Chiếu', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up, size: 16),
                  SizedBox(width: 4),
                  Text('Phổ Biến', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieGrid() {
    return BlocBuilder<MovieBloc, MovieState>(
      builder: (context, state) {
        // Loading state
        if (state.isLoading) {
          return SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: const ShimmerMovieGrid(itemCount: 6),
            ),
          );
        }

        // Empty state
        if (state.movies.isEmpty) {
          String emptyTitle = 'Chưa có phim';
          String emptySubtitle = 'Hãy quay lại sau';
          
          if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
            emptyTitle = 'Không tìm thấy phim';
            emptySubtitle = 'Không có phim nào phù hợp với từ khóa "${state.searchQuery}"';
          } else if (state.category == 'nowShowing') {
            emptyTitle = 'Chưa có phim hôm nay';
            emptySubtitle = 'Không có phim nào có lịch chiếu hôm nay';
          } else if (state.category == 'comingSoon') {
            emptyTitle = 'Chưa có phim sắp chiếu';
            emptySubtitle = 'Không có phim nào sắp chiếu';
          } else if (state.category == 'popular') {
            emptyTitle = 'Chưa có phim phổ biến';
            emptySubtitle = 'Không có phim nào được đặt trên 5 lần';
          }
          
          return SliverFillRemaining(
            hasScrollBody: false, // Prevent overflow
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: EmptyState(
                icon: state.searchQuery != null ? Icons.search_off : Icons.movie_outlined,
                title: emptyTitle,
                subtitle: emptySubtitle,
              ),
            ),
          );
        }

        // Movie grid
        // Get bottom padding for safe area
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding + 20), // Dynamic bottom padding for safe area
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  columnCount: 2,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: _buildMovieCard(state.movies[index]),
                    ),
                  ),
                );
              },
              childCount: state.movies.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMovieCard(MovieModel movie) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailScreen(
              movieId: movie.id,
              cinemaId: _selectedCinema?.id,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE50914).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: movie.posterUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => ShimmerLoadingCard(
                  height: double.infinity,
                  borderRadius: BorderRadius.circular(16),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.movie, size: 50, color: Colors.grey),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
              if (movie.ageRating != null && movie.ageRating!.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE50914), Color(0xFFB20710)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE50914).withOpacity(0.6),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          movie.ageRating!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        movie.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE50914).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFE50914).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          movie.genre,
                          style: const TextStyle(
                            color: Color(0xFFE50914),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.access_time, color: Colors.white70, size: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${movie.duration} phút',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMovieCarousel() {
    return BlocBuilder<MovieBloc, MovieState>(
      builder: (context, state) {
        // Chỉ hiển thị carousel khi không có search query
        if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        // Load carousel movies (đang chiếu + sắp chiếu) nếu chưa có
        if (_carouselMovies.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (mounted) {
              try {
                // Load cả phim đang chiếu và sắp chiếu
                final nowShowing = await DatabaseService().getMoviesShowingToday(cinemaId: null);
                final comingSoon = await DatabaseService().getMoviesComingSoon(cinemaId: null);
                
                // Kết hợp và loại bỏ trùng lặp
                final allCarouselMovies = <MovieModel>[];
                final seenIds = <String>{};
                
                for (var movie in nowShowing) {
                  if (!seenIds.contains(movie.id)) {
                    allCarouselMovies.add(movie);
                    seenIds.add(movie.id);
                  }
                }
                
                for (var movie in comingSoon) {
                  if (!seenIds.contains(movie.id)) {
                    allCarouselMovies.add(movie);
                    seenIds.add(movie.id);
                  }
                }
                
                // Lấy top 5 phim đầu tiên
                if (mounted) {
                  setState(() {
                    _carouselMovies = allCarouselMovies.take(5).toList();
                  });
                  
                  // Initialize carousel controller nếu chưa có
                  if (_carouselMovies.isNotEmpty && _carouselController == null) {
                    setState(() {
                      _carouselController = PageController(initialPage: 0);
                    });
                    _startCarouselAutoScroll();
                  }
                }
              } catch (e) {
                print('Error loading carousel movies: $e');
              }
            }
          });
        }

        // Initialize carousel controller nếu chưa có
        if (_carouselMovies.isNotEmpty && _carouselController == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _carouselController = PageController(initialPage: 0);
              });
              _startCarouselAutoScroll();
            }
          });
        }

        if (_carouselMovies.isEmpty || _carouselController == null) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(
                height: 350,
                child: PageView.builder(
                  controller: _carouselController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentCarouselIndex = index;
                    });
                  },
                  itemCount: _carouselMovies.length,
                  itemBuilder: (context, index) {
                    final movie = _carouselMovies[index];
                    return _buildCarouselItem(movie);
                  },
                ),
              ),
              const SizedBox(height: 12),
              SmoothPageIndicator(
                controller: _carouselController!,
                count: _carouselMovies.length,
                effect: const WormEffect(
                  activeDotColor: Color(0xFFE50914),
                  dotColor: Color(0xFF2A2A2A),
                  dotHeight: 8,
                  dotWidth: 8,
                  spacing: 8,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCarouselItem(MovieModel movie) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailScreen(
              movieId: movie.id,
              cinemaId: _selectedCinema?.id,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: movie.posterUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.movie, size: 50, color: Colors.grey),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (movie.ageRating != null && movie.ageRating!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE50914), Color(0xFFB20710)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE50914).withOpacity(0.6),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_user,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    movie.ageRating!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (movie.ageRating != null && movie.ageRating!.isNotEmpty)
                            const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.access_time, color: Colors.white70, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${movie.duration} phút',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



}