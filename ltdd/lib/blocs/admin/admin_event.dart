import '../../models/movie.dart';
import '../../models/showtime.dart';
import '../../models/theater.dart';

abstract class AdminEvent {}
class LoadAdminData extends AdminEvent {} // Load movies, theaters
class CreateMovie extends AdminEvent {
  final MovieModel movie;
  CreateMovie(this.movie);
}
class CreateShowtime extends AdminEvent {
  final ShowtimeModel showtime;
  CreateShowtime(this.showtime);
}
class CreateTheater extends AdminEvent {
  final TheaterModel theater;
  CreateTheater(this.theater);
}