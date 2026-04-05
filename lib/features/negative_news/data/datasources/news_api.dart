import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_model.dart';

class NewsApiDataSource {
  static const String baseUrl = 'http://localhost:8000';

  final http.Client _client;
  NewsApiDataSource({http.Client? client}) : _client = client ?? http.Client();

  // ── Fetch live news feed ──────────────────────────────────────────────────
  Future<List<NewsModel>> fetchNewsFeed({
    String? symbol,
    String? signal,
    int hours = 6,
    int limit = 50,
  }) async {
    final queryParams = {
      'hours': hours.toString(),
      'limit': limit.toString(),
      if (symbol != null) 'symbol': symbol,
      if (signal != null) 'signal': signal,
    };

    final uri = Uri.parse('$baseUrl/api/news/feed')
        .replace(queryParameters: queryParams);

    final response = await _client.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['items'] as List<dynamic>;
      return items.map((e) => NewsModel.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch news feed: ${response.statusCode}');
  }

  // ── Analyze a headline on demand ─────────────────────────────────────────
  Future<Map<String, dynamic>> analyzeHeadline({
    required String symbol,
    required String title,
    String description = '',
    String sourceUrl = '',
  }) async {
    final uri = Uri.parse('$baseUrl/api/analysis/analyze');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'symbol': symbol,
        'title': title,
        'description': description,
        'source_url': sourceUrl,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Analysis failed: ${response.statusCode}');
  }

  // ── Fetch watchlist signals ───────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchWatchlistSignals({
    int hours = 6,
  }) async {
    final uri = Uri.parse('$baseUrl/api/signals/watchlist')
        .replace(queryParameters: {'hours': hours.toString()});
    final response = await _client.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['symbols']);
    }
    throw Exception('Failed to fetch watchlist: ${response.statusCode}');
  }

  // ── Fetch sector heatmap ──────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchSectorHeatmap({
    int hours = 6,
  }) async {
    final uri = Uri.parse('$baseUrl/api/signals/heatmap')
        .replace(queryParameters: {'hours': hours.toString()});
    final response = await _client.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    }
    throw Exception('Failed to fetch heatmap: ${response.statusCode}');
  }

  // ── Fetch company signal ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchCompanySignal(String symbol) async {
    final uri = Uri.parse('$baseUrl/api/signals/company/$symbol');
    final response = await _client.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch signal for $symbol');
  }

  // ── Fetch terminal summary ────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchTerminalSummary() async {
    final uri = Uri.parse('$baseUrl/api/terminal/summary');
    final response = await _client.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch terminal summary');
  }
}