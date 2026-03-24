import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/retro_ui.dart';
import '../services/supabase_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  AnalyticsScreenState createState() => AnalyticsScreenState();
}

class AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // 일별 데이터
  int _todayFocusSeconds = 0;
  int _todayDistractionCount = 0;
  int _todaySessionCount = 0;

  // 주간 데이터 (최근 7일)
  List<DayStat> _weeklyStats = [];

  // 월간 데이터 (최근 30일)
  List<DayStat> _monthlyStats = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> reload() => _fetchAll();

  Future<void> _fetchAll() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getTodayStats(userId: userId),
        ApiService.getWeeklyStats(userId: userId),
        ApiService.getMonthlyStats(userId: userId),
      ]);
      if (mounted) {
        final today = results[0] as Map<String, dynamic>;
        setState(() {
          _todayFocusSeconds = (today['totalFocusTime'] as num?)?.toInt() ?? 0;
          _todayDistractionCount = (today['totalDistractionCount'] as num?)?.toInt() ?? 0;
          _todaySessionCount = (today['sessionCount'] as num?)?.toInt() ?? 0;
          _weeklyStats = results[1] as List<DayStat>;
          _monthlyStats = results[2] as List<DayStat>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fmt(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) return '$h시간 $m분 $sec초';
    if (m > 0) return '$m분 $sec초';
    return '$sec초';
  }

  String _fmtShort(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h${m > 0 ? ' ${m}m' : ''}';
    if (m > 0) return '${m}m';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('분석'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '일별'),
            Tab(text: '주별'),
            Tab(text: '월별'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDailyTab(),
                _buildWeeklyTab(),
                _buildMonthlyTab(),
              ],
            ),
    );
  }

  // ── 일별 탭 ──────────────────────────────────────────────────────────────
  Widget _buildDailyTab() {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('오늘의 학습 통계',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _StatCard(
            icon: Icons.timer,
            label: '총 집중 시간',
            value: _fmt(_todayFocusSeconds),
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          _StatCard(
            icon: Icons.play_circle_outline,
            label: '세션 수',
            value: '$_todaySessionCount회',
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(height: 12),
          _StatCard(
            icon: Icons.warning_amber_rounded,
            label: '산만 횟수',
            value: '$_todayDistractionCount회',
            color: AppTheme.drowsyAccent,
          ),
        ],
      ),
    );
  }

  // ── 주별 탭 ──────────────────────────────────────────────────────────────
  Widget _buildWeeklyTab() {
    final theme = Theme.of(context);
    final maxFocus = _weeklyStats.isEmpty
        ? 1
        : _weeklyStats.map((d) => d.focusTime).reduce((a, b) => a > b ? a : b);
    final totalWeek = _weeklyStats.fold<int>(0, (s, d) => s + d.focusTime);

    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('최근 7일',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('총 ${_fmt(totalWeek)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 24),

          // 바 차트
          ..._weeklyStats.map((day) {
            final frac = maxFocus > 0 ? day.focusTime / maxFocus : 0.0;
            final label = _dayLabel(day.date);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(label,
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: reelyRadius(context, 6),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: frac.clamp(0.0, 1.0),
                          child: Container(
                            height: 28,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: reelyRadius(context, 6),
                            ),
                          ),
                        ),
                        if (day.focusTime > 0)
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  _fmtShort(day.focusTime),
                                  style: TextStyle(
                                    color: frac > 0.3 ? Colors.white : null,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 월별 탭 ──────────────────────────────────────────────────────────────
  Widget _buildMonthlyTab() {
    final theme = Theme.of(context);
    final totalMonth = _monthlyStats.fold<int>(0, (s, d) => s + d.focusTime);
    final maxFocus = _monthlyStats.isEmpty
        ? 1
        : _monthlyStats.map((d) => d.focusTime).reduce((a, b) => a > b ? a : b);

    // 주별로 묶기 (7일씩)
    final weeks = <List<DayStat>>[];
    for (int i = 0; i < _monthlyStats.length; i += 7) {
      weeks.add(_monthlyStats.sublist(
          i, i + 7 > _monthlyStats.length ? _monthlyStats.length : i + 7));
    }

    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('최근 30일',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('총 ${_fmt(totalMonth)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 24),

          // 주별 요약 카드
          ...weeks.asMap().entries.map((entry) {
            final weekIndex = entry.key + 1;
            final days = entry.value;
            final weekTotal = days.fold<int>(0, (s, d) => s + d.focusTime);
            final studiedDays = days.where((d) => d.focusTime > 0).length;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${weekIndex}주차',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          '${_fmtShort(weekTotal)} · ${studiedDays}일 공부',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: days.map((day) {
                        final frac = maxFocus > 0 ? day.focusTime / maxFocus : 0.0;
                        final hasStudy = day.focusTime > 0;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              children: [
                                Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: hasStudy
                                        ? theme.colorScheme.primary
                                            .withAlpha((frac * 200 + 55).toInt())
                                        : theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: reelyRadius(context, 4),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _dayLabel(day.date),
                                  style: const TextStyle(fontSize: 9),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _dayLabel(String dateStr) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    try {
      final d = DateTime.parse(dateStr);
      return days[d.weekday - 1];
    } catch (_) {
      return '';
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(value,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
