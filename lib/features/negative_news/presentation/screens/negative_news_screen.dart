import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/news_cubit.dart';
import '../cubit/market_cubit.dart';
import '../cubit/stock_cubit.dart';
import '../cubit/filter_cubit.dart';
import '../../data/repositories/news_repository.dart';
import '../widgets/news_card.dart';
import '../widgets/filter_chip.dart';
import '../widgets/stock_snapshot.dart';
import '../widgets/ai_insight.dart';

class NegativeNewsScreen extends StatelessWidget {
  const NegativeNewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => NewsRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
              create: (ctx) => NewsCubit(
                    repository: ctx.read<NewsRepository>(),
                  )..loadNewsFeed()),
          BlocProvider(
              create: (ctx) => MarketCubit(
                    repository: ctx.read<NewsRepository>(),
                  )..loadMarketData()),
          BlocProvider(
              create: (ctx) => StockCubit(
                    repository: ctx.read<NewsRepository>(),
                  )..loadWatchlist()),
          BlocProvider(create: (_) => FilterCubit()),
        ],
        child: const _NegativeNewsView(),
      ),
    );
  }
}

class _NegativeNewsView extends StatefulWidget {
  const _NegativeNewsView();

  @override
  State<_NegativeNewsView> createState() => _NegativeNewsViewState();
}

class _NegativeNewsViewState extends State<_NegativeNewsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF16161E),
      body: Column(
        children: [
          // ── Page header ──────────────────────────────────────────────────
          _PageHeader(tabController: _tabController),

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: isDesktop
                ? _DesktopLayout(tabController: _tabController)
                : _MobileLayout(tabController: _tabController),
          ),
        ],
      ),
    );
  }
}

// ── Page Header ───────────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  final TabController tabController;
  const _PageHeader({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E26),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Title
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'News Intelligence',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Real-time sentiment · NSE market signals',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.35),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Live indicator
              _LiveIndicator(),
              const SizedBox(width: 10),
              // Refresh all button
              _HeaderRefreshButton(),
            ],
          ),
          const SizedBox(height: 14),

          // Tab bar
          TabBar(
            controller: tabController,
            isScrollable: false,
            indicatorColor: const Color(0xFF7C3AED),
            indicatorWeight: 2,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w400),
            tabs: const [
              Tab(text: 'News Feed'),
              Tab(text: 'Signals'),
              Tab(text: 'Market'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Desktop layout: sidebar + main content ────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final TabController tabController;
  const _DesktopLayout({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel: filters + stock grid
        SizedBox(
          width: 320,
          child: Container(
            color: const Color(0xFF1A1A22),
            child: ListView(
              children: const [
                NewsFilterBar(),
                SizedBox(height: 8),
                StockSnapshotGrid(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
        // Divider
        VerticalDivider(
            width: 1,
            color: Colors.white.withOpacity(0.06)),

        // Main panel
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: const [
              _NewsFeedTab(),
              _SignalsTab(),
              _MarketTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Mobile layout ─────────────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final TabController tabController;
  const _MobileLayout({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: [
        // Tab 1: News + filters
        Column(
          children: [
            const NewsFilterBar(),
            const Expanded(child: _NewsFeedTab()),
          ],
        ),
        // Tab 2: Signals (stock grid)
        ListView(
          children: const [
            StockSnapshotGrid(),
            SizedBox(height: 20),
          ],
        ),
        // Tab 3: Market
        const SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: _MarketTab(),
          ),
        ),
      ],
    );
  }
}

// ── News Feed Tab ─────────────────────────────────────────────────────────────
class _NewsFeedTab extends StatelessWidget {
  const _NewsFeedTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewsCubit, NewsState>(
      builder: (context, state) {
        if (state is NewsLoading) {
          return const Center(
            child: CircularProgressIndicator(
                color: Color(0xFF7C3AED), strokeWidth: 2),
          );
        }
        if (state is NewsError) {
          return _FullPageError(
            message: state.message,
            onRetry: () => context.read<NewsCubit>().loadNewsFeed(),
          );
        }
        if (state is NewsLoaded) {
          // Apply search filter client-side
          final query = context.read<FilterCubit>().state.searchQuery.toLowerCase();
          final items = query.isEmpty
              ? state.items
              : state.items
                  .where((n) =>
                      n.title.toLowerCase().contains(query) ||
                      n.symbol.toLowerCase().contains(query))
                  .toList();

          if (items.isEmpty) {
            return _EmptyFeed(
              onRefresh: () => context.read<NewsCubit>().loadNewsFeed(),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF7C3AED),
            backgroundColor: const Color(0xFF252530),
            onRefresh: () async =>
                context.read<NewsCubit>().loadNewsFeed(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              itemCount: items.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${items.length} articles',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  );
                }
                return NewsCard(
                  news: items[i - 1],
                  onTap: () => _showArticleDetail(
                      context, items[i - 1]),
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showArticleDetail(BuildContext context, dynamic news) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => _ArticleDetailSheet(
            news: news, scrollController: controller),
      ),
    );
  }
}

// ── Signals Tab ───────────────────────────────────────────────────────────────
class _SignalsTab extends StatelessWidget {
  const _SignalsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: const [
        StockSnapshotGrid(),
      ],
    );
  }
}

// ── Market Tab ────────────────────────────────────────────────────────────────
class _MarketTab extends StatelessWidget {
  const _MarketTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 20),
      children: const [
        AiInsightPanel(),
      ],
    );
  }
}

// ── Article Detail Bottom Sheet ───────────────────────────────────────────────
class _ArticleDetailSheet extends StatelessWidget {
  final dynamic news;
  final ScrollController scrollController;

  const _ArticleDetailSheet(
      {required this.news, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Symbol + signal
        Row(
          children: [
            _SheetSymbolChip(symbol: news.symbol),
            const SizedBox(width: 8),
            _SheetSignalBadge(signal: news.signalLabel),
            const Spacer(),
            Text(news.timeAgo,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.35))),
          ],
        ),
        const SizedBox(height: 14),

        // Title
        Text(
          news.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),

        // Description
        if (news.description.isNotEmpty)
          Text(
            news.description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.55),
              height: 1.6,
            ),
          ),
        const SizedBox(height: 20),

        // Sentiment breakdown
        _SentimentBreakdown(sentiment: news.sentiment),
        const SizedBox(height: 16),

        // Source
        Row(
          children: [
            Icon(Icons.link_rounded,
                size: 13, color: Colors.white.withOpacity(0.3)),
            const SizedBox(width: 6),
            Text(
              news.source,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.4)),
            ),
            const SizedBox(width: 6),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: news.credibilityScore >= 0.8
                    ? const Color(0xFF00E676)
                    : const Color(0xFFFFAB40),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Credibility: ${(news.credibilityScore * 100).toInt()}%',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.3)),
            ),
          ],
        ),
      ],
    );
  }
}

class _SentimentBreakdown extends StatelessWidget {
  final dynamic sentiment;
  const _SentimentBreakdown({required this.sentiment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF252530),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sentiment Breakdown',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.6))),
          const SizedBox(height: 12),
          _SentimentRow(
              label: 'Overall Score',
              value:
                  '${sentiment.score >= 0 ? '+' : ''}${sentiment.score.toStringAsFixed(3)}',
              color: sentiment.score >= 0.15
                  ? const Color(0xFF00E676)
                  : sentiment.score <= -0.15
                      ? const Color(0xFFFF5252)
                      : const Color(0xFFFFAB40)),
          _SentimentRow(
              label: 'VADER Compound',
              value:
                  '${sentiment.vaderCompound >= 0 ? '+' : ''}${sentiment.vaderCompound.toStringAsFixed(3)}',
              color: Colors.white54),
          _SentimentRow(
              label: 'Strength',
              value: sentiment.strength,
              color: Colors.white54),
          _SentimentRow(
              label: 'Fake Risk',
              value:
                  '${(sentiment.fakeRiskScore * 100).toInt()}%',
              color: sentiment.fakeRiskScore > 0.5
                  ? const Color(0xFFFF6D00)
                  : Colors.white38),
          if (sentiment.bullishHits.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Bullish keywords',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.3))),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: (sentiment.bullishHits as List)
                  .take(5)
                  .map((k) => _KwChip(
                      text: k.toString(),
                      color: const Color(0xFF00E676)))
                  .toList(),
            ),
          ],
          if (sentiment.bearishHits.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Bearish keywords',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.3))),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: (sentiment.bearishHits as List)
                  .take(5)
                  .map((k) => _KwChip(
                      text: k.toString(),
                      color: const Color(0xFFFF5252)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SentimentRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SentimentRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.4))),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}

class _KwChip extends StatelessWidget {
  final String text;
  final Color color;
  const _KwChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8))),
    );
  }
}

class _SheetSymbolChip extends StatelessWidget {
  final String symbol;
  const _SheetSymbolChip({required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: const Color(0xFF7C3AED).withOpacity(0.4), width: 1),
      ),
      child: Text(symbol,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB57BFF))),
    );
  }
}

class _SheetSignalBadge extends StatelessWidget {
  final String signal;
  const _SheetSignalBadge({required this.signal});

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(signal,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.8)),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────
class _LiveIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFF00E676),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'LIVE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF00E676).withOpacity(0.8),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _HeaderRefreshButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<NewsCubit>().loadNewsFeed();
        context.read<MarketCubit>().loadMarketData();
        context.read<StockCubit>().loadWatchlist();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: const Color(0xFF7C3AED).withOpacity(0.35),
              width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded,
                size: 14,
                color: const Color(0xFF7C3AED).withOpacity(0.9)),
            const SizedBox(width: 5),
            const Text(
              'Refresh',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB57BFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullPageError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _FullPageError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 40, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 12),
          Text(
            'Could not connect to backend',
            style: TextStyle(
                fontSize: 14, color: Colors.white.withOpacity(0.4)),
          ),
          const SizedBox(height: 4),
          Text(
            'Make sure the server is running on :8000',
            style: TextStyle(
                fontSize: 11, color: Colors.white.withOpacity(0.25)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyFeed({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.newspaper_rounded,
              size: 40, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 12),
          Text('No news yet',
              style: TextStyle(
                  fontSize: 14, color: Colors.white.withOpacity(0.35))),
          const SizedBox(height: 4),
          Text('Collection runs every 30 minutes',
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withOpacity(0.2))),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRefresh,
            child: const Text('Refresh',
                style: TextStyle(color: Color(0xFF7C3AED))),
          ),
        ],
      ),
    );
  }
}