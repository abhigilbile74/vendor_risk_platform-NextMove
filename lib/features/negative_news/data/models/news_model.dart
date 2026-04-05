class NewsModel {
  final String id;
  final String title;
  final String description;
  final String url;
  final String source;
  final String symbol;
  final DateTime publishedAt;
  final DateTime collectedAt;
  final double credibilityScore;
  final SentimentData sentiment;
  final bool labeled;
  final String? label;

  const NewsModel({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.source,
    required this.symbol,
    required this.publishedAt,
    required this.collectedAt,
    required this.credibilityScore,
    required this.sentiment,
    this.labeled = false,
    this.label,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['_id']?.toString() ?? json['article_hash'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      source: json['source'] ?? '',
      symbol: json['symbol'] ?? '',
      publishedAt: _parseDate(json['published_at']),
      collectedAt: _parseDate(json['collected_at']),
      credibilityScore: (json['credibility_score'] as num?)?.toDouble() ?? 0.5,
      sentiment: SentimentData.fromJson(
          json['sentiment'] as Map<String, dynamic>? ?? {}),
      labeled: json['labeled'] ?? false,
      label: json['label'],
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  // Derived helpers used by UI
  String get signalLabel {
    final score = sentiment.score;
    if (score >= 0.15) return 'BUY';
    if (score <= -0.15) return 'SELL';
    return 'NEUTRAL';
  }

  bool get isNegative => sentiment.label == 'NEGATIVE';
  bool get isFakeRisk => sentiment.fakeRiskScore > 0.5;

  String get timeAgo {
    final diff = DateTime.now().difference(collectedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class SentimentData {
  final double score;
  final String label;
  final String strength;
  final double vaderCompound;
  final List<String> bullishHits;
  final List<String> bearishHits;
  final double fakeRiskScore;

  const SentimentData({
    required this.score,
    required this.label,
    required this.strength,
    required this.vaderCompound,
    required this.bullishHits,
    required this.bearishHits,
    required this.fakeRiskScore,
  });

  factory SentimentData.fromJson(Map<String, dynamic> json) {
    return SentimentData(
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      label: json['label'] ?? 'NEUTRAL',
      strength: json['strength'] ?? 'WEAK',
      vaderCompound: (json['vader_compound'] as num?)?.toDouble() ?? 0.0,
      bullishHits: List<String>.from(json['bullish_hits'] ?? []),
      bearishHits: List<String>.from(json['bearish_hits'] ?? []),
      fakeRiskScore: (json['fake_risk_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}