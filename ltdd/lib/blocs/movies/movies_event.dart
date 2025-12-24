abstract class MovieEvent {}
class LoadMovies extends MovieEvent {}
class SearchMovies extends MovieEvent {
  final String query;
  SearchMovies(this.query);
}
class FilterMoviesByCategory extends MovieEvent {
  final String category; // 'nowShowing', 'comingSoon', 'popular'
  FilterMoviesByCategory(this.category);
}