import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../theme/retro_ui.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  RecordsScreenState createState() => RecordsScreenState();
}

class RecordsScreenState extends State<RecordsScreen> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<CalendarDay> _records = [];
  bool _isLoading = true;
  CalendarDay? _selectedDay;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  /// 메인 탭 전환 시 목록 갱신
  Future<void> reload() => _fetchRecords();

  Future<void> _fetchRecords() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final records = await ApiService.getCalendarRecords(
        userId: userId,
        year: _focusedMonth.year,
        month: _focusedMonth.month,
      );
      if (mounted) {
        setState(() {
          _records = records;
          _selectedDay = null;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, CalendarDay> get _recordMap {
    return {for (final r in _records) r.date: r};
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
    _fetchRecords();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_focusedMonth.year == now.year && _focusedMonth.month == now.month) return;
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
    _fetchRecords();
  }

  String _fmt(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) return '${h}시간 ${m}분 $sec초';
    if (m > 0) return '${m}분 $sec초';
    return '$sec초';
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('기록')),
      body: Column(
        children: [
          // 월 내비게이션
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevMonth,
                ),
                Text(
                  '${_focusedMonth.year}년 ${_focusedMonth.month}월',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    final now = DateTime.now();
                    if (_focusedMonth.year == now.year && _focusedMonth.month == now.month) return;
                    _nextMonth();
                  },
                ),
              ],
            ),
          ),

          // 요일 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: const ['월', '화', '수', '목', '금', '토', '일']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: d == '일'
                                      ? Colors.red
                                      : d == '토'
                                          ? Colors.blue
                                          : null)),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 4),

          // 달력 그리드
          _isLoading
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : _buildCalendarGrid(theme),

          // 선택된 날짜 상세
          if (_selectedDay != null) _buildDayDetail(theme, _selectedDay!),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(ThemeData theme) {
    final map = _recordMap;
    // 해당 월 1일의 요일 (1=월요일 기준으로 맞추기)
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    // weekday: 1=월, 7=일
    final startOffset = firstDay.weekday - 1;
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final today = DateTime.now();

    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: rows * 7,
          itemBuilder: (ctx, index) {
            final dayNum = index - startOffset + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const SizedBox.shrink();
            }

            final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
            final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            final record = map[dateStr];
            final isToday = date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            final isSelected = _selectedDay?.date == dateStr;
            final isSunday = date.weekday == 7;
            final isSaturday = date.weekday == 6;

            return GestureDetector(
              onTap: record != null
                  ? () => setState(() {
                        _selectedDay = isSelected ? null : record;
                      })
                  : null,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : isToday
                          ? theme.colorScheme.primary.withAlpha(30)
                          : null,
                  borderRadius: reelyRadius(context, 8),
                  border: isToday && !isSelected
                      ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dayNum',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : isSunday
                                ? Colors.red
                                : isSaturday
                                    ? Colors.blue
                                    : null,
                      ),
                    ),
                    if (record != null) ...[
                      const SizedBox(height: 2),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDayDetail(ThemeData theme, CalendarDay day) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withAlpha(50),
                borderRadius: reelyRadius(context, 2),
              ),
            ),
          ),

          // 날짜 + 총 집중 시간
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDateLabel(day.date),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Chip(
                avatar: const Icon(Icons.timer, size: 16),
                label: Text(_fmt(day.totalFocusTime)),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 과목별 시간
          if (day.subjects.isEmpty)
            Text('과목 기록 없음',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))
          else
            ...day.subjects.map((sub) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _hexToColor(sub.color),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(sub.subjectName,
                            style: theme.textTheme.bodyMedium),
                      ),
                      Text(
                        _fmt(sub.focusTime),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  String _formatDateLabel(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length < 3) return dateStr;
    return '${parts[1]}월 ${int.parse(parts[2])}일';
  }
}
