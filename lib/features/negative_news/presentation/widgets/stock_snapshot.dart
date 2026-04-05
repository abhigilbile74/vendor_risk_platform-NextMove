import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/stock_cubit.dart';

class StockSnapshotGrid extends StatelessWidget {
  const StockSnapshotGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockCubit, StockState>(
      builder: (context, state) {
        if (state is StockLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF7C3AED),
              strokeWidth: 2,
            ),
          );
        }
        if (state is StockError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<StockCubit>().loadWatchlist(),
          );
        }
        if (state is StockLoaded) {
          if (state.watchlist.isEmpty) {
            return const _EmptyView();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Text(
                      'Watchlist Signals',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const Spacer(),
                    _RefreshButton(
                      onTap: () =>
                          context.read<StockCubit>().loadWatchlist(),
                    ),
                  ],
                ),
              ),
              GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.4,
                ),
                itemCount: state.watchlist.length,
                itemBuilder: (context, i) {
                  final stock = state.watchlist[i];
                  return StockSnapshotCard(
                    stock: stock,
                    isSelected:
                        state.selectedSymbol == stock['symbol'],
                    onTap: () => context
                        .read<StockCubit>()
                        .selectCompany(stock['symbol']),
                  );
                },
              ),
              // ── Company detail panel ─────────────────────────────────────
              if (state.selectedCompany != null)
                _CompanyDetailPanel(
                  data: state.selectedCompany!,
                  onClose: () =>
                      context.read<StockCubit>().clearSelection(),
                ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class StockSnapshotCard extends StatelessWidget {
  final Map<String, dynamic> stock;
  final bool isSelected;
  final VoidCallback onTap;

  const StockSnapshotCard({
    super.key,
    required this.stock,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final signal = stock['signal']?.toString() ?? 'NEUTRAL';
    final confidence = (stock['confidence'] as num?)?.toDouble() ?? 0.0;
    final score =
        (stock['sentiment_score'] as num?)?.toDouble() ?? 0.0;
    final color = _signalColor(signal);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.12)
              : const Color(0xFF252530),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? color.withOpacity(0.5)
                : Colors.white.withOpacity(0.07),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Signal indicator
            Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    stock['symbol']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    signal,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(confidence * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  '${score >= 0 ? '+' : ''}${score.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
              ],
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

class _CompanyDetailPanel extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onClose;

  const _CompanyDetailPanel({required this.data, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final signal = data['latest_signal'];
    final headlines =
        List<Map<String, dynamic>>.from(data['recent_headlines'] ?? []);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252530),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                data['symbol']?.toString() ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              if (signal != null)
                _SignalPill(
                    signal: signal['signal']?.toString() ?? 'NEUTRAL'),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                child: Icon(Icons.close_rounded,
                    size: 18, color: Colors.white.withOpacity(0.4)),
              ),
            ],
          ),
          if (signal != null) ...[
            const SizedBox(height: 12),
            _ReasoningSection(
                reasoning: List<String>.from(
                    signal['reasoning'] ?? [])),
          ],
          if (headlines.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Recent Headlines',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.35),
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            ...headlines.take(3).map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• ${h['title'] ?? ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _ReasoningSection extends StatelessWidget {
  final List<String> reasoning;
  const _ReasoningSection({required this.reasoning});

  @override
  Widget build(BuildContext context) {
    if (reasoning.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis',
          style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.35),
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        ...reasoning.take(3).map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7C3AED),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.55),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _SignalPill extends StatelessWidget {
  final String signal;
  const _SignalPill({required this.signal});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (signal) {
      case 'BUY':
        color = const Color(0xFF00E676);
        break;
      case 'SELL':
        color = const Color(0xFFFF5252);
        break;
      default:
        color = const Color(0xFFFFAB40);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(signal,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.8)),
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 32, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 8),
          Text('Failed to load',
              style: TextStyle(
                  fontSize: 13, color: Colors.white.withOpacity(0.35))),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No signals yet — collection running...',
        style: TextStyle(
            fontSize: 13, color: Colors.white.withOpacity(0.3)),
      ),
    );
  }
}