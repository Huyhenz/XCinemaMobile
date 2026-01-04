import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/showtime.dart';
import '../models/cinema.dart';
import '../services/database_services.dart';
import '../utils/dialog_helper.dart';
import '../widgets/auth_guard.dart';
import 'booking_screen.dart';

class ShowtimesScreen extends StatefulWidget {
  final String movieId;
  final String? cinemaId; // ID của rạp (để filter showtimes)
  const ShowtimesScreen({super.key, required this.movieId, this.cinemaId});

  @override
  State<ShowtimesScreen> createState() => _ShowtimesScreenState();
}

class _ShowtimesScreenState extends State<ShowtimesScreen> {
  List<ShowtimeModel> _allShowtimes = []; // Tất cả showtimes
  List<ShowtimeModel> _filteredShowtimes = []; // Showtimes đã filter theo ngày
  int _selectedDateIndex = 0;
  List<DateTime> _dates = [];
  CinemaModel? _cinema;
  List<CinemaModel> _allCinemas = [];

  @override
  void initState() {
    super.initState();
    _generateDates();
    _loadCinema();
    _loadAllCinemas();
    _loadShowtimes();
  }

  Future<void> _loadCinema() async {
    if (widget.cinemaId != null && widget.cinemaId!.isNotEmpty) {
      try {
        final cinema = await DatabaseService().getCinema(widget.cinemaId!);
        setState(() {
          _cinema = cinema;
        });
      } catch (e) {
        print('❌ Error loading cinema: $e');
      }
    }
  }

  Future<void> _loadAllCinemas() async {
    try {
      final cinemas = await DatabaseService().getAllCinemas();
      setState(() {
        _allCinemas = cinemas;
      });
    } catch (e) {
      print('❌ Error loading all cinemas: $e');
    }
  }

  void _generateDates() {
    DateTime now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      _dates.add(now.add(Duration(days: i)));
    }
  }

  Future<void> _loadShowtimes() async {
    try {
      // Sử dụng _cinema?.id nếu có, nếu không thì dùng widget.cinemaId
      final cinemaIdToUse = _cinema?.id ?? widget.cinemaId;
      
      if (cinemaIdToUse != null && cinemaIdToUse.isNotEmpty) {
        // Load showtimes by movie and cinema
        _allShowtimes = await DatabaseService().getShowtimesByMovieAndCinema(
          widget.movieId,
          cinemaIdToUse,
        );
      } else {
        // Load all showtimes by movie
        _allShowtimes = await DatabaseService().getShowtimesByMovie(widget.movieId);
      }
      _filterShowtimes();
      setState(() {});
    } catch (e) {
      print('❌ Error loading showtimes: $e');
      if (mounted) {
        await DialogHelper.showError(context, 'Lỗi tải lịch chiếu: ${e.toString()}');
      }
      setState(() {
        _allShowtimes = [];
        _filteredShowtimes = [];
      });
    }
  }

  void _filterShowtimes() {
    if (_allShowtimes.isEmpty) {
      _filteredShowtimes = [];
      return;
    }

    final selectedDate = _dates[_selectedDateIndex];
    final selectedDateStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final selectedDateEnd = selectedDateStart.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    final selectedDateStartMillis = selectedDateStart.millisecondsSinceEpoch;
    final selectedDateEndMillis = selectedDateEnd.millisecondsSinceEpoch;

    final now = DateTime.now();

    // Filter showtimes theo ngày được chọn (chỉ showtimes của ngày đó, không hết hạn)
    _filteredShowtimes = _allShowtimes.where((showtime) {
      final showtimeDate = DateTime.fromMillisecondsSinceEpoch(showtime.startTime);
      final showtimeDateStart = DateTime(showtimeDate.year, showtimeDate.month, showtimeDate.day);
      
      // Phải cùng ngày với ngày được chọn (so sánh year, month, day)
      final isOnSelectedDate = showtimeDateStart.year == selectedDate.year &&
                               showtimeDateStart.month == selectedDate.month &&
                               showtimeDateStart.day == selectedDate.day;
      
      // Không hết hạn (chỉ áp dụng cho hôm nay và quá khứ)
      final isNotExpired = showtime.startTime >= now.millisecondsSinceEpoch;
      
      return isOnSelectedDate && isNotExpired;
    }).toList();

    // Sort by time
    _filteredShowtimes.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
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
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Chọn Lịch Chiếu',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          _buildTheaterInfo(),
          Expanded(child: _buildShowtimesList()),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _dates.length,
        itemBuilder: (context, index) {
          DateTime date = _dates[index];
          bool isSelected = _selectedDateIndex == index;
          bool isToday = index == 0;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDateIndex = index;
                _filterShowtimes(); // Filter lại showtimes theo ngày được chọn
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 75,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFE50914), Color(0xFFB20710), Color(0xFF8B0000)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : const Color(0xFFE50914).withOpacity(0.3),
                  width: isSelected ? 1.5 : 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFE50914).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 1,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFFE50914), Color(0xFFB20710)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFFE50914), Color(0xFFB20710)],
                              ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE50914).withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'HÔM NAY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  if (!isToday) const SizedBox(height: 8),
                  if (isToday) const SizedBox(height: 6),
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('dd').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey[500],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTheaterInfo() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showCinemaSelectionDialog,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE50914).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE50914).withOpacity(0.1),
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE50914), Color(0xFFB20710)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE50914).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _cinema?.name ?? 'Chọn rạp chiếu',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE50914).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.swap_horiz, color: Color(0xFFE50914), size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _cinema?.address ?? 'Bấm để đổi rạp',
                      style: TextStyle(
                        color: _cinema != null ? Colors.grey[300] : Colors.grey[500],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCinemaSelectionDialog() async {
    if (_allCinemas.isEmpty) {
      await DialogHelper.showError(context, 'Không có rạp chiếu nào');
      return;
    }

    final selectedCinema = await showModalBottomSheet<CinemaModel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: const Color(0xFFE50914).withOpacity(0.3),
              width: 1.5,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE50914).withOpacity(0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE50914), Color(0xFFB20710)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.theaters, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Chọn Rạp Chiếu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE50914).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _allCinemas.length,
                itemBuilder: (context, index) {
                  final cinema = _allCinemas[index];
                  final isSelected = _cinema?.id == cinema.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFE50914), Color(0xFFB20710)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
                            : const Color(0xFFE50914).withOpacity(0.3),
                        width: isSelected ? 1.5 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFE50914).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.pop(context, cinema);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [Colors.white, Colors.white70],
                                        )
                                      : const LinearGradient(
                                          colors: [Color(0xFFE50914), Color(0xFFB20710)],
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isSelected
                                              ? Colors.white
                                              : const Color(0xFFE50914))
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: isSelected ? const Color(0xFFE50914) : Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cinema.name,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      cinema.address,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white70
                                            : Colors.grey[400],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );

    if (selectedCinema != null && selectedCinema.id != _cinema?.id) {
      setState(() {
        _cinema = selectedCinema;
      });
      // Reload showtimes với rạp mới
      await _loadShowtimes();
    }
  }


  Widget _buildShowtimesList() {
    if (_filteredShowtimes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE50914).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(Icons.event_busy, size: 64, color: Color(0xFFE50914)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Không có lịch chiếu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng chọn ngày khác',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: _filteredShowtimes.length,
      itemBuilder: (context, index) {
        ShowtimeModel showtime = _filteredShowtimes[index];
        DateTime time = DateTime.fromMillisecondsSinceEpoch(showtime.startTime);

        return Container(
          margin: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE50914).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE50914).withOpacity(0.1),
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                // Check authentication before booking, truyền return path
                final isAuthenticated = await AuthGuard.requireAuth(
                  context,
                  returnPath: 'booking:${showtime.id}',
                );
                if (isAuthenticated && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingScreen(showtimeId: showtime.id),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE50914), Color(0xFFB20710), Color(0xFF8B0000)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE50914).withOpacity(0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('HH:mm').format(time),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat('dd/MM').format(time),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: FutureBuilder(
                        future: DatabaseService().getTheater(showtime.theaterId),
                        builder: (context, snapshot) {
                          final theater = snapshot.data;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (theater != null) ...[
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFE50914), Color(0xFFB20710)],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.meeting_room, color: Colors.white, size: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        theater.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF2A2A2A).withOpacity(0.8),
                                      const Color(0xFF1A1A1A).withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFE50914).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.event_seat,
                                      color: Color(0xFFE50914),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${showtime.availableSeats.length} ghế trống',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
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
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF2A2A2A).withOpacity(0.5),
                            const Color(0xFF1A1A1A).withOpacity(0.5),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFFE50914),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
