import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/market_cubit.dart';

class AiInsightPanel extends StatelessWidget {
  const AiInsightPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketCubit, MarketState>(
      builder: (context, state) {
        if (state is MarketLoading) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF7C3AED), strokeWidth: 2),
            ),
          );
        }
        if (state is MarketError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: _ErrorCard(
              onRetry: () => context.read<MarketCubit>().loadMarketData(),
            ),
          );
        }
        if (state is MarketLoaded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Market bias banner ───────────────────────────────────────
              _MarketBiasBanner(
                bias: state.marketBias,
                summary: state.summary,
              ),
              const SizedBox(height: 16),

              // ── Sector heatmap ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Sector Heatmap',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const Spacer(),
                    _RefreshButton(
                      onTap: () =>
                          context.read<MarketCubit>().loadMarketData(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _SectorHeatmap(sectors: state.sectors),
              const SizedBox(height: 16),

              // ── Top movers ───────────────────────────────────────────────
              _TopMovers(summary: state.summary),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _MarketBiasBanner extends StatelessWidget {
  final String bias;
  final Map<String, dynamic> summary;

  const _MarketBiasBanner({required this.bias, required this.summary});

  @override
  Widget build(BuildContext context) {
    final color = _biasColor(bias);
    final counts = summary['signal_counts'] as Map<String, dynamic>? ?? {};
    final session =
        summary['market_session'] as Map<String, dynamic>? ?? {};
    final isOpen = session['is_open'] == true;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          // Bias icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_biasIcon(bias), color: color, size: 20),
          ),
          const SizedBox(width: 14),

          // Bias label + session
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Market: $bias',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? const Color(0xFF00E676).withOpacity(0.12)
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isOpen ? 'LIVE' : 'CLOSED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isOpen
                              ? const Color(0xFF00E676)
                              : Colors.white.withOpacity(0.3),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'NSE · ${session['trading_hours'] ?? '09:15–15:30 IST'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
              ],
            ),
          ),

          // Signal counts
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _CountPill(
                  label: '${counts['BUY'] ?? 0} BUY',
                  color: const Color(0xFF00E676)),
              const SizedBox(height: 4),
              _CountPill(
                  label: '${counts['SELL'] ?? 0} SELL',
                  color: const Color(0xFFFF5252)),
            ],
          ),
        ],
      ),
    );
  }

  Color _biasColor(String bias) {
    switch (bias) {
      case 'BULLISH':
        return const Color(0xFF00E676);
      case 'BEARISH':
        return const Color(0xFFFF5252);
      default:
        return const Color(0xFFFFAB40);
    }
  }

  IconData _biasIcon(String bias) {
    switch (bias) {
      case 'BULLISH':
        return Icons.trending_up_rounded;
      case 'BEARISH':
        return Icons.trending_down_rounded;
      default:
        return Icons.trending_flat_rounded;
    }
  }
}

class _SectorHeatmap extends StatelessWidget {
  final List<Map<String, dynamic>> sectors;
  const _SectorHeatmap({required this.sectors});

  @override
  Widget build(BuildContext context) {
    if (sectors.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'No sector data yet — collecting...',
          style: TextStyle(
              fontSize: 12, color: Colors.white.withOpacity(0.3)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: sectors.map((s) => _SectorTile(sector: s)).toList(),
      ),
    );
  }
}

class _SectorTile extends StatelessWidget {
  final Map<String, dynamic> sector;
  const _SectorTile({required this.sector});

  @override
  Widget build(BuildContext context) {
    final signal = sector['signal']?.toString() ?? 'NEUTRAL';
    final strength =
        (sector['strength'] as num?)?.toDouble().abs() ?? 0.0;
    final color = _signalColor(signal);
    final sectorName = sector['sector']?.toString() ?? '';
    final companyCount = sector['company_count'] ?? 0;

    return Container(
      width: (MediaQuery.of(context).size.width - 60) / 2,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06 + strength * 0.12),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sectorName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$companyCount stocks',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                signal,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${(strength * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.35),
                ),
              ),
            ],
          ),
        ],
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

class _TopMovers extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _TopMovers({required this.summary});

  @override
  Widget build(BuildContext context) {
    final topBuy = List<Map<String, dynamic>>.from(
        summary['top_buy'] ?? []);
    final topSell = List<Map<String, dynamic>>.from(
        summary['top_sell'] ?? []);

    if (topBuy.isEmpty && topSell.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Movers',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 10),
          if (topBuy.isNotEmpty) ...[
            _MoversList(
                items: topBuy,
                color: const Color(0xFF00E676),
                label: 'Strongest BUY'),
            const SizedBox(height: 8),
          ],
          if (topSell.isNotEmpty)
            _MoversList(
                items: topSell,
                color: const Color(0xFFFF5252),
                label: 'Strongest SELL'),
        ],
      ),
    );
  }
}

class _MoversList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Color color;
  final String label;

  const _MoversList(
      {required this.items, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 28,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item['symbol']?.toString() ?? '',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['headline']?.toString() ?? '',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.35)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${((item['confidence'] as num?)?.toDouble() ?? 0) * 100 ~/ 1}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  final String label;
  final Color color;
  const _CountPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5)),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RefreshButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF252530),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: Colors.white.withOpacity(0.08), width: 1),
        ),
        child: Icon(Icons.refresh_rounded,
            size: 14, color: Colors.white.withOpacity(0.4)),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252530),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: Colors.white.withOpacity(0.3), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Failed to load market data',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.4))),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry',
                style: TextStyle(fontSize: 12, color: Color(0xFF7C3AED))),
          ),
        ],
      ),
    );
  }
}