import '../../models/movie.dart';
import '../../models/showtime.dart';
import '../../models/theater.dart';

abstract class AdminEvent {}
class LoadAdminData extends AdminEvent {} // Load movies, theaters
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
class UpdateTheater extends AdminEvent {
  final TheaterModel theater;
  UpdateTheater(this.theater);
}
class DeleteTheater extends AdminEvent {
  final String theaterId;
  DeleteTheater(this.theaterId);
}