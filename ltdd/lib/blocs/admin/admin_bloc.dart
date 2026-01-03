import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/movie.dart';
import '../../models/showtime.dart';
import '../../models/theater.dart';
import '../../models/voucher.dart';
import '../../models/cinema.dart';
import '../../services/database_services.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final DatabaseService _dbService = DatabaseService();

  AdminBloc() : super(AdminState()) {
    on<LoadAdminData>((event, emit) async {
      emit(AdminState(isLoading: true));
      try {
        // Use getAllMoviesForAdmin to show all movies including expired ones
        List<MovieModel> movies = await _dbService.getAllMoviesForAdmin();
        List<CinemaModel> cinemas = await _dbService.getAllCinemas();
        List<TheaterModel> theaters = await _dbService.getAllTheaters();
        List<ShowtimeModel> showtimes = await _dbService.getAllShowtimes();
        List<VoucherModel> vouchers = await _dbService.getAllVouchers();
        emit(AdminState(movies: movies, cinemas: cinemas, theaters: theaters, showtimes: showtimes, vouchers: vouchers));
      } catch (e) {
        emit(AdminState(error: e.toString()));
      }
    });

    on<CreateCinema>((event, emit) async {
      try {
        await _dbService.saveCinema(event.cinema);
        add(LoadAdminData());
      } catch (e) {
        emit(AdminState(error: e.toString()));
      }
    });

    on<UpdateCinema>((event, emit) async {
      try {
        await _dbService.updateCinema(event.cinema);
        add(LoadAdminData());
      } catch (e) {
        emit(AdminState(error: e.toString()));
      }
    });

    on<DeleteCinema>((event, emit) async {
      try {
        await _dbService.deleteCinema(event.cinemaId);
        add(LoadAdminData());
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

    on<DeleteAllMovies>((event, emit) async {
      try {
        await _dbService.deleteAllMovies();
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

    on<DeleteAllShowtimes>((event, emit) async {
      try {
        await _dbService.deleteAllShowtimes();
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

    on<DeleteAllTheaters>((event, emit) async {
      try {
        await _dbService.deleteAllTheaters();
        add(LoadAdminData());
      } catch (e) {
        emit(AdminState(error: e.toString()));
      }
    });

    on<CreateVoucher>((event, emit) async {
      try {
        await _dbService.saveVoucher(event.voucher);
        add(LoadAdminData());
      } catch (e) {
        emit(AdminState(error: e.toString()));
      }
    });

    on<UpdateVoucher>((event, emit) async {
      try {
        await _dbService.updateVoucher(event.voucher);
        add(LoadAdminData());
      } catch (e) {
        emit(AdminState(error: e.toString()));
      }
    });

    on<DeleteVoucher>((event, emit) async {
      try {
        await _dbService.deleteVoucher(event.voucherId);
        add(LoadAdminData());
      } catch (e) {
        emit(AdminState(error: e.toString()));
      }
    });
  }
}