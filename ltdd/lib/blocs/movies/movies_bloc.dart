import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/movie.dart';
import '../../services/database_services.dart';
import 'movies_event.dart';
import 'movies_state.dart';


class MovieBloc extends Bloc<MovieEvent, MovieState> {
  final DatabaseService _dbService = DatabaseService();

  MovieBloc() : super(MovieState([])) {
    on<LoadMovies>((event, emit) async {
      List<MovieModel> movies = await _dbService.getAllMovies();
      emit(MovieState(movies));
    });
  }
}