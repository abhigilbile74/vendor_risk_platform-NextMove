import 'package:flutter/material.dart';
import '../../data/models/news_model.dart';

class NewsCard extends StatelessWidget {
  final NewsModel news;
  final VoidCallback? onTap;

  const NewsCard({super.key, required this.news, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF252530),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _signalColor(news.signalLabel).withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: symbol + signal badge + time ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  _SymbolChip(symbol: news.symbol),
                  const SizedBox(width: 8),
                  _SignalBadge(signal: news.signalLabel),
                  if (news.isFakeRisk) ...[
                    const SizedBox(width: 6),
                    _FakeRiskBadge(score: news.sentiment.fakeRiskScore),
                  ],
                  const Spacer(),
                  Text(
                    news.timeAgo,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.35),
                    ),
                  ),
                ],
              ),
            ),

            // ── Headline ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(
                news.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),

            // ── Description ────────────────────────────────────────────────
            if (news.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Text(
                  news.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.45),
                    height: 1.5,
                  ),
                ),
              ),

            // ── Bottom row: source + sentiment score ───────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  Icon(Icons.newspaper_rounded,
                      size: 13, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(width: 4),
                  Text(
                    news.source,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.35),
                    ),
                  ),
                  const Spacer(),
                  _SentimentBar(score: news.sentiment.score),
                  const SizedBox(width: 8),
                  _CredibilityDot(score: news.credibilityScore),
                ],
              ),
            ),

            // ── Keyword chips if any ───────────────────────────────────────
            if (news.sentiment.bearishHits.isNotEmpty ||
                news.sentiment.bullishHits.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ...news.sentiment.bullishHits.take(2).map((k) =>
                        _KeywordChip(text: k, positive: true)),
                    ...news.sentiment.bearishHits.take(2).map((k) =>
                        _KeywordChip(text: k, positive: false)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _signalColor(String signal) {
    switch (signal) {
      case 'BUY':
        return const Color(0xFF00E676);
      case 'SELL':
        return const Color(0xFFFF5252);
      default:
        return const Color(0xFFFFAB40);
    }
  }
}

class _SymbolChip extends StatelessWidget {
  final String symbol;
  const _SymbolChip({required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: const Color(0xFF7C3AED).withOpacity(0.4), width: 1),
      ),
      child: Text(
        symbol,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFFB57BFF),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SignalBadge extends StatelessWidget {
  final String signal;
  const _SignalBadge({required this.signal});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    switch (signal) {
      case 'BUY':
        bg = const Color(0xFF00E676).withOpacity(0.12);
        text = const Color(0xFF00E676);
        break;
      case 'SELL':
        bg = const Color(0xFFFF5252).withOpacity(0.12);
        text = const Color(0xFFFF5252);
        break;
      default:
        bg = const Color(0xFFFFAB40).withOpacity(0.12);
        text = const Color(0xFFFFAB40);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        signal,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _FakeRiskBadge extends StatelessWidget {
  final double score;
  const _FakeRiskBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6D00).withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 10, color: Color(0xFFFF6D00)),
          const SizedBox(width: 3),
          Text(
            'FAKE ${(score * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF6D00),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SentimentBar extends StatelessWidget {
  final double score;
  const _SentimentBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 0.15
        ? const Color(0xFF00E676)
        : score <= -0.15
            ? const Color(0xFFFF5252)
            : const Color(0xFFFFAB40);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Sentiment',
          style: TextStyle(
              fontSize: 10, color: Colors.white.withOpacity(0.3)),
        ),
        const SizedBox(width: 4),
        Text(
          '${score >= 0 ? '+' : ''}${score.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CredibilityDot extends StatelessWidget {
  final double score;
  const _CredibilityDot({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 0.8
        ? const Color(0xFF00E676)
        : score >= 0.6
            ? const Color(0xFFFFAB40)
            : const Color(0xFFFF5252);
    return Tooltip(
      message: 'Source credibility: ${(score * 100).toInt()}%',
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _KeywordChip extends StatelessWidget {
  final String text;
  final bool positive;
  const _KeywordChip({required this.text, required this.positive});

  @override
  Widget build(BuildContext context) {
    final color =
        positive ? const Color(0xFF00E676) : const Color(0xFFFF5252);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
      ),
    );
  }
}