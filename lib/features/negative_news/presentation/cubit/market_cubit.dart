import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/news_repository.dart';

// ── States ────────────────────────────────────────────────────────────────────
abstract class MarketState {}

class MarketInitial extends MarketState {}

class MarketLoading extends MarketState {}

class MarketLoaded extends MarketState {
  final List<Map<String, dynamic>> sectors;
  final Map<String, dynamic> summary;
  final String marketBias;

  MarketLoaded({
    required this.sectors,
    required this.summary,
    required this.marketBias,
  });
}

class MarketError extends MarketState {
  final String message;
  MarketError(this.message);
}

// ── Cubit ─────────────────────────────────────────────────────────────────────
class MarketCubit extends Cubit<MarketState> {
  final NewsRepository _repository;

  MarketCubit({NewsRepository? repository})
      : _repository = repository ?? NewsRepository(),
        super(MarketInitial());

  Future<void> loadMarketData() async {
    emit(MarketLoading());
    try {
      final results = await Future.wait([
        _repository.getSectorHeatmap(),
        _repository.getTerminalSummary(),
      ]);

      final sectors = results[0] as List<Map<String, dynamic>>;
      final summary = results[1] as Map<String, dynamic>;
      final bias = summary['market_bias']?.toString() ?? 'MIXED';

      emit(MarketLoaded(
        sectors: sectors,
        summary: summary,
        marketBias: bias,
      ));
    } catch (e) {
      emit(MarketError(e.toString()));
    }
  }

  void refresh() => loadMarketData();
}