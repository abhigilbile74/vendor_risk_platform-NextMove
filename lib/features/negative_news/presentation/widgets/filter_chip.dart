import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/filter_cubit.dart';
import '../cubit/news_cubit.dart';

class NewsFilterBar extends StatelessWidget {
  const NewsFilterBar({super.key});

  static const _signals = ['BUY', 'SELL', 'NEUTRAL'];
  static const _hours = [3, 6, 12, 24, 48];
  static const _symbols = [
    'TCS', 'INFY', 'WIPRO', 'HCLTECH', 'RELIANCE',
    'HDFC', 'ICICIBANK', 'AXISBANK', 'SBIN', 'ONGC',
    'NTPC', 'MARUTI', 'TATAMOTORS', 'BAJFINANCE', 'KOTAKBANK',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterCubit, FilterState>(
      builder: (context, filter) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E26),
            border: Border(
              bottom: BorderSide(
                  color: Colors.white.withOpacity(0.06), width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search bar ───────────────────────────────────────────────
              _SearchBar(
                onChanged: (q) =>
                    context.read<FilterCubit>().setSearchQuery(q),
              ),
              const SizedBox(height: 12),

              // ── Signal filter ────────────────────────────────────────────
              _FilterRow(
                label: 'Signal',
                children: _signals.map((s) {
                  final isSelected = filter.selectedSignal == s;
                  return _FilterChip(
                    label: s,
                    selected: isSelected,
                    color: _signalColor(s),
                    onTap: () {
                      context.read<FilterCubit>().setSignal(
                            isSelected ? null : s,
                          );
                      _applyFilters(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              // ── Time filter ──────────────────────────────────────────────
              _FilterRow(
                label: 'Time',
                children: _hours.map((h) {
                  final isSelected = filter.selectedHours == h;
                  return _FilterChip(
                    label: '${h}h',
                    selected: isSelected,
                    color: const Color(0xFF7C3AED),
                    onTap: () {
                      context.read<FilterCubit>().setHours(h);
                      _applyFilters(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              // ── Symbol filter ────────────────────────────────────────────
              _FilterRow(
                label: 'Symbol',
                scrollable: true,
                children: _symbols.map((s) {
                  final isSelected = filter.selectedSymbol == s;
                  return _FilterChip(
                    label: s,
                    selected: isSelected,
                    color: const Color(0xFF0EA5E9),
                    onTap: () {
                      context.read<FilterCubit>().setSymbol(
                            isSelected ? null : s,
                          );
                      _applyFilters(context);
                    },
                  );
                }).toList(),
              ),

              // ── Clear all ────────────────────────────────────────────────
              if (filter.selectedSignal != null ||
                  filter.selectedSymbol != null ||
                  filter.selectedHours != 6)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: GestureDetector(
                    onTap: () {
                      context.read<FilterCubit>().clearAll();
                      context.read<NewsCubit>().loadNewsFeed();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close_rounded,
                            size: 13,
                            color: Colors.white.withOpacity(0.4)),
                        const SizedBox(width: 4),
                        Text(
                          'Clear filters',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _applyFilters(BuildContext context) {
    final filter = context.read<FilterCubit>().state;
    context.read<NewsCubit>().loadNewsFeed(
          symbol: filter.selectedSymbol,
          signal: filter.selectedSignal,
          hours: filter.selectedHours,
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

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF252530),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search headlines...',
          hintStyle:
              TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.25)),
          prefixIcon: Icon(Icons.search_rounded,
              size: 16, color: Colors.white.withOpacity(0.3)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String label;
  final List<Widget> children;
  final bool scrollable;

  const _FilterRow({
    required this.label,
    required this.children,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.3),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: scrollable
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: children),
                )
              : Wrap(spacing: 6, children: children),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : const Color(0xFF252530),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? color.withOpacity(0.6) : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? color : Colors.white.withOpacity(0.45),
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}