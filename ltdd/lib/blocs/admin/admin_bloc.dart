import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/movie.dart';
import '../../models/showtime.dart';
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
        List<ShowtimeModel> showtimes = await _dbService.getAllShowtimes();
        emit(AdminState(movies: movies, theaters: theaters, showtimes: showtimes));
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

    on<UpdateShowtime>((event, emit) async {
      try {
        await _dbService.updateShowtime(event.showtime);
        add(LoadAdminData());
      } catch (e) {
        emit(AdminState(error: e.toString()));
      }
    });

    on<DeleteShowtime>((event, emit) async {
      try {
        await _dbService.deleteShowtime(event.showtimeId);
        add(LoadAdminData());
      } catch (e) {
        emit(AdminState(error: e.toString()));
      }
    });

    on<UpdateTheater>((event, emit) async {
      try {
        await _dbService.updateTheater(event.theater);
        add(LoadAdminData());
      } catch (e) {
        emit(AdminState(error: e.toString()));
      }
    });

    on<DeleteTheater>((event, emit) async {
      try {
        await _dbService.deleteTheater(event.theaterId);
        add(LoadAdminData());
      } catch (e) {
        emit(AdminState(error: e.toString()));
      }
    });
  }
}