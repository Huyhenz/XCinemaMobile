import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/movie.dart';
import '../../models/theater.dart';
import '../../services/database_services.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final DatabaseService _dbService = DatabaseService();

  AdminBloc() : super(AdminState()) {
    on<LoadAdminData>((event, emit) async {
      emit(AdminState(isLoading: true));
      try {
        List<MovieModel> movies = await _dbService.getAllMovies();
        List<TheaterModel> theaters = await _dbService.getAllTheaters();
        emit(AdminState(movies: movies, theaters: theaters));
      } catch (e) {
        emit(AdminState(error: e.toString()));
      }
    });

    on<CreateMovie>((event, emit) async {
      try {
        await _dbService.saveMovie(event.movie);
        add(LoadAdminData()); // Reload sau khi save
      } catch (e) {
        emit(AdminState(error: e.toString()));
      }
    });

    on<UpdateMovie>((event, emit) async {
      try {
        await _dbService.updateMovie(event.movie);
        add(LoadAdminData()); // Reload sau khi update
      } catch (e) {
        emit(AdminState(error: e.toString()));
      }
    });

    on<DeleteMovie>((event, emit) async {
      try {
        await _dbService.deleteMovie(event.movieId);
        add(LoadAdminData()); // Reload sau khi delete
      } catch (e) {
        emit(AdminState(error: e.toString()));
      }
    });

    on<CreateShowtime>((event, emit) async {
      try {
        await _dbService.saveShowtime(event.showtime);
        add(LoadAdminData());
      } catch (e) {
        emit(AdminState(error: e.toString()));
      }
    });

    on<CreateTheater>((event, emit) async {
      try {
        await _dbService.saveTheater(event.theater);
        add(LoadAdminData());
      } catch (e) {
        emit(AdminState(error: e.toString()));
      }
    });
  }
}