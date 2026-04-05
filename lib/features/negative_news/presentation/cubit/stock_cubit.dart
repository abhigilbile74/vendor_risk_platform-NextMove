import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/news_repository.dart';

// ── States ────────────────────────────────────────────────────────────────────
abstract class StockState {}

class StockInitial extends StockState {}

class StockLoading extends StockState {}

class StockLoaded extends StockState {
  final List<Map<String, dynamic>> watchlist;
  final Map<String, dynamic>? selectedCompany;
  final String? selectedSymbol;

  StockLoaded({
    required this.watchlist,
    this.selectedCompany,
    this.selectedSymbol,
  });
}

class StockError extends StockState {
  final String message;
  StockError(this.message);
}

// ── Cubit ─────────────────────────────────────────────────────────────────────
class StockCubit extends Cubit<StockState> {
  final NewsRepository _repository;

  StockCubit({NewsRepository? repository})
      : _repository = repository ?? NewsRepository(),
        super(StockInitial());

  Future<void> loadWatchlist() async {
    emit(StockLoading());
    try {
      final watchlist = await _repository.getWatchlistSignals();
      emit(StockLoaded(watchlist: watchlist));
    } catch (e) {
      emit(StockError(e.toString()));
    }
  }

  Future<void> selectCompany(String symbol) async {
    final current = state;
    if (current is StockLoaded) {
      try {
        final detail = await _repository.getCompanySignal(symbol);
        emit(StockLoaded(
          watchlist: current.watchlist,
          selectedCompany: detail,
          selectedSymbol: symbol,
        ));
      } catch (e) {
        // keep existing state, just log
      }
    }
  }

  void clearSelection() {
    final current = state;
    if (current is StockLoaded) {
      emit(StockLoaded(watchlist: current.watchlist));
    }
  }
}