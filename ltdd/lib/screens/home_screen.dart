// Updated: lib/screens/home_screen.dart - Cinema Classic Theme
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/movies/movies_bloc.dart';
import '../blocs/movies/movies_event.dart';
import '../blocs/movies/movies_state.dart';
import '../models/movie.dart';
import 'movie_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MovieBloc()..add(LoadMovies()),
      child: Scaffold(
        backgroundColor: Color(0xFF1a1a1a),
        appBar: AppBar(
          backgroundColor: Color(0xFF1a1a1a),
          elevation: 0,
          centerTitle: true,
          title: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.movie_filter, color: Color(0xFFD4AF37), size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Cinema',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontFamily: 'serif',
                    ),
                  ),
                ],
              ),
              Text(
                'Ticket',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(40),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Buy Your Ticket Now',
                style: TextStyle(
                  color: Color(0xFFB8941E),
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            // Film reel borders
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _buildFilmStrip(),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _buildFilmStrip(),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50.0),
              child: BlocBuilder<MovieBloc, MovieState>(
                builder: (context, state) {
                  if (state.movies.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD4AF37),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    itemCount: state.movies.length,
                    itemBuilder: (context, index) {
                      MovieModel movie = state.movies[index];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MovieDetailScreen(movieId: movie.id),
                          ),
                        ),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 30),
                          child: Column(
                            children: [
                              // Movie Poster with ornate frame
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Color(0xFFD4AF37),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFFD4AF37).withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    ClipRect(
                                      child: Image.network(
                                        movie.posterUrl,
                                        height: 400,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    // Gradient overlay at bottom
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 100,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.8),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 15),
                              // Movie Title
                              Text(
                                movie.title,
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  fontFamily: 'serif',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              // Genre and Rating
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    movie.genre,
                                    style: TextStyle(
                                      color: Color(0xFFB8941E),
                                      fontSize: 14,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Color(0xFFD4AF37),
                                        size: 16,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        '${movie.rating}',
                                        style: TextStyle(
                                          color: Color(0xFFD4AF37),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 15),
                              // Decorative dots
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  5,
                                      (i) => Container(
                                    margin: EdgeInsets.symmetric(horizontal: 4),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: i < 3 ? Color(0xFFD4AF37) : Color(0xFF3a3a3a),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        // Bottom Navigation with film theme
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Color(0xFF1a1a1a),
            border: Border(
              top: BorderSide(color: Color(0xFFD4AF37), width: 2),
            ),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            selectedItemColor: Color(0xFFD4AF37),
            unselectedItemColor: Color(0xFF666666),
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.movie),
                label: 'Movies',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.confirmation_number),
                label: 'Tickets',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilmStrip() {
    return Container(
      width: 40,
      color: Color(0xFFD4AF37),
      child: ListView.builder(
        itemCount: 100,
        itemBuilder: (context, index) => Container(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          height: 15,
          decoration: BoxDecoration(
            color: Color(0xFF1a1a1a),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}