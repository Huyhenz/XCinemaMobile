import '../../models/movie.dart';
import '../../models/showtime.dart';
import '../../models/theater.dart';
import '../../models/voucher.dart';
import '../../models/cinema.dart';

abstract class AdminEvent {}
class LoadAdminData extends AdminEvent {} // Load movies, theaters
class CreateCinema extends AdminEvent {
  final CinemaModel cinema;
  CreateCinema(this.cinema);
}
class UpdateCinema extends AdminEvent {
  final CinemaModel cinema;
  UpdateCinema(this.cinema);
}
class DeleteCinema extends AdminEvent {
  final String cinemaId;
  DeleteCinema(this.cinemaId);
}
class CreateMovie extends AdminEvent {
  final MovieModel movie;
  CreateMovie(this.movie);
}
class UpdateMovie extends AdminEvent {
  final MovieModel movie;
  UpdateMovie(this.movie);
}
class DeleteMovie extends AdminEvent {
  final String movieId;
  DeleteMovie(this.movieId);
}
class DeleteAllMovies extends AdminEvent {}
class CreateShowtime extends AdminEvent {
  final ShowtimeModel showtime;
  CreateShowtime(this.showtime);
}
class CreateTheater extends AdminEvent {
  final TheaterModel theater;
  CreateTheater(this.theater);
}
class UpdateShowtime extends AdminEvent {
  final ShowtimeModel showtime;
  UpdateShowtime(this.showtime);
}
class DeleteShowtime extends AdminEvent {
  final String showtimeId;
  DeleteShowtime(this.showtimeId);
}
class DeleteAllShowtimes extends AdminEvent {}
class UpdateTheater extends AdminEvent {
  final TheaterModel theater;
  UpdateTheater(this.theater);
}
class DeleteTheater extends AdminEvent {
  final String theaterId;
  DeleteTheater(this.theaterId);
}
class DeleteAllTheaters extends AdminEvent {}
class CreateVoucher extends AdminEvent {
  final VoucherModel voucher;
  CreateVoucher(this.voucher);
}
class UpdateVoucher extends AdminEvent {
  final VoucherModel voucher;
  UpdateVoucher(this.voucher);
}
class DeleteVoucher extends AdminEvent {
  final String voucherId;
  DeleteVoucher(this.voucherId);
}