import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../widgets/reely_logo_image.dart';
import '../theme/retro_ui.dart';
import 'study_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _todayFocusSeconds = 0;
  bool _isLoading = true;
  List<Subject> _subjects = [];
  List<SubjectStat> _subjectStats = [];

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  /// 하단 탭으로 돌아올 때 등 외부에서 통계 다시 불러오기
  Future<void> reload() => _fetchAll();

  Future<void> _fetchAll() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final results = await Future.wait([
        ApiService.getTodayStats(userId: userId),
        ApiService.getSubjects(userId: userId),
        ApiService.getTodaySubjectStats(userId: userId),
      ]);
      if (mounted) {
        final stats = results[0] as Map<String, dynamic>;
        setState(() {
          _todayFocusSeconds = (stats['totalFocusTime'] as num?)?.toInt() ?? 0;
          _subjects = results[1] as List<Subject>;
          _subjectStats = results[2] as List<SubjectStat>;
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

  int _subjectFocusTime(int subjectId) {
    for (final stat in _subjectStats) {
      if (stat.subjectId == subjectId) return stat.focusTime;
    }
    return 0;
  }

  // 과목 추가 다이얼로그
  Future<void> _showAddSubjectDialog() async {
    final nameCtrl = TextEditingController();
    String selectedColor = '#F7C948';
    const colors = [
      '#F7C948', '#F6993F', '#F59E0B', '#E65100',
      '#EC4899', '#10B981', '#3B82F6', '#6366F1',
    ];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('과목 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '과목명',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('색상', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: colors.map((c) {
                  final color = _hexToColor(c);
                  return GestureDetector(
                    onTap: () => setInner(() => selectedColor = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selectedColor == c
                            ? Border.all(width: 3, color: Colors.black45)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                await _addSubject(name, selectedColor);
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSubject(String name, String color) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;
    try {
      final subject = await ApiService.createSubject(
        userId: userId,
        name: name,
        color: color,
      );
      if (mounted) setState(() => _subjects.add(subject));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('과목 추가 실패: $e')),
        );
      }
    }
  }

  Future<void> _deleteSubject(Subject subject) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('과목 삭제'),
        content: Text('"${subject.name}" 과목을 삭제할까요?\n해당 과목의 공부 기록은 유지됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.deleteSubject(id: subject.id, userId: userId);
      if (mounted) setState(() => _subjects.removeWhere((s) => s.id == subject.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('과목 삭제 실패: $e')),
        );
      }
    }
  }

  Future<void> _startStudy(Subject subject) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => StudyScreen(subject: subject)),
    );
    if (mounted) await _fetchAll();
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = SupabaseService.currentUser;
    final greeting = user?.userMetadata?['full_name'] ?? '사용자';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 88,
        // 라이트/다크는 ReelyLogoImage 내부에서 brightness로 분기
        title: const ReelyLogoImage(size: 72, borderRadius: 12),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchAll();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAll,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // 인사말
                        Text(
                          '안녕하세요, $greeting 님!',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '오늘도 집중해서 공부해볼까요?',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 오늘의 집중 시간 카드
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Icon(Icons.timer, size: 40, color: theme.colorScheme.primary),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('오늘의 집중 시간', style: theme.textTheme.bodySmall),
                                    const SizedBox(height: 4),
                                    Text(
                                      _fmt(_todayFocusSeconds),
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 과목 리스트 헤더
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('과목',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              '${_subjects.length}개',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ]),
                    ),
                  ),

                  // 과목 리스트
                  if (_subjects.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: Text(
                            '아래 버튼을 눌러 과목을 추가해보세요.',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final subject = _subjects[i];
                            final focusTime = _subjectFocusTime(subject.id);
                            final color = _hexToColor(subject.color);
                            return _SubjectTile(
                              subject: subject,
                              focusTime: focusTime,
                              color: color,
                              onStart: () => _startStudy(subject),
                              onDelete: () => _deleteSubject(subject),
                              formatTime: _fmt,
                            );
                          },
                          childCount: _subjects.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),

      // 하단 중앙 과목 추가 버튼
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSubjectDialog,
        icon: const Icon(Icons.add),
        label: const Text('과목 추가'),
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  final Subject subject;
  final int focusTime;
  final Color color;
  final VoidCallback onStart;
  final VoidCallback onDelete;
  final String Function(int) formatTime;

  const _SubjectTile({
    required this.subject,
    required this.focusTime,
    required this.color,
    required this.onStart,
    required this.onDelete,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 색상 인디케이터
            Container(
              width: 12,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: reelyRadius(context, 6),
              ),
            ),
            const SizedBox(width: 14),

            // 과목명 + 오늘 집중 시간
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '오늘 ${focusTime > 0 ? formatTime(focusTime) : '0초'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),

            // 삭제 버튼
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
              onPressed: onDelete,
              tooltip: '과목 삭제',
            ),

            // 공부 시작 버튼 (play icon)
            IconButton.filled(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow),
              style: IconButton.styleFrom(backgroundColor: color),
              tooltip: '공부 시작',
            ),
          ],
        ),
      ),
    );
  }
}
