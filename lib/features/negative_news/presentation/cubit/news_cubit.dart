import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/news_model.dart';
import '../../data/repositories/news_repository.dart';

// ── States ────────────────────────────────────────────────────────────────────
abstract class NewsState {}

class NewsInitial extends NewsState {}

class NewsLoading extends NewsState {}

class NewsLoaded extends NewsState {
  final List<NewsModel> items;
  final int totalCount;
  NewsLoaded({required this.items, required this.totalCount});
}

class NewsError extends NewsState {
  final String message;
  NewsError(this.message);
}

// ── Cubit ─────────────────────────────────────────────────────────────────────
class NewsCubit extends Cubit<NewsState> {
  final NewsRepository _repository;

  NewsCubit({NewsRepository? repository})
      : _repository = repository ?? NewsRepository(),
        super(NewsInitial());

  Future<void> loadNewsFeed({
    String? symbol,
    String? signal,
    int hours = 6,
  }) async {
    emit(NewsLoading());
    try {
      final items = await _repository.getNewsFeed(
        symbol: symbol,
        signal: signal,
        hours: hours,
      );
      emit(NewsLoaded(items: items, totalCount: items.length));
    } catch (e) {
      emit(NewsError(e.toString()));
    }
  }

  Future<void> loadNegativeNews({int hours = 24}) async {
    emit(NewsLoading());
    try {
      final items = await _repository.getNegativeNews(hours: hours);
      emit(NewsLoaded(items: items, totalCount: items.length));
    } catch (e) {
      emit(NewsError(e.toString()));
    }
  }

  void refresh() => loadNewsFeed();
}