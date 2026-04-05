import '../datasources/news_api.dart';
import '../models/news_model.dart';

class NewsRepository {
  final NewsApiDataSource _dataSource;

  NewsRepository({NewsApiDataSource? dataSource})
      : _dataSource = dataSource ?? NewsApiDataSource();

  // ── News Feed ─────────────────────────────────────────────────────────────
  Future<List<NewsModel>> getNewsFeed({
    String? symbol,
    String? signal,
    int hours = 6,
    int limit = 50,
  }) async {
    return _dataSource.fetchNewsFeed(
      symbol: symbol,
      signal: signal,
      hours: hours,
      limit: limit,
    );
  }

  // ── Negative news only ────────────────────────────────────────────────────
  Future<List<NewsModel>> getNegativeNews({int hours = 24}) async {
    final all = await _dataSource.fetchNewsFeed(hours: hours, limit: 100);
    return all.where((n) => n.isNegative || n.isFakeRisk).toList();
  }

  // ── On-demand analysis ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> analyzeHeadline({
    required String symbol,
    required String title,
    String description = '',
    String sourceUrl = '',
  }) {
    return _dataSource.analyzeHeadline(
      symbol: symbol,
      title: title,
      description: description,
      sourceUrl: sourceUrl,
    );
  }

  // ── Watchlist signals ─────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getWatchlistSignals() {
    return _dataSource.fetchWatchlistSignals();
  }

  // ── Sector heatmap ────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getSectorHeatmap() {
    return _dataSource.fetchSectorHeatmap();
  }

  // ── Company detail ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getCompanySignal(String symbol) {
    return _dataSource.fetchCompanySignal(symbol);
  }

  // ── Terminal summary ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getTerminalSummary() {
    return _dataSource.fetchTerminalSummary();
  }
}