import 'dart:convert';
import 'package:http/http.dart' as http;

class Subject {
  final int id;
  final String name;
  final String color;

  const Subject({required this.id, required this.name, required this.color});

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: (json['id'] as num).toInt(),
        name: json['name'].toString(),
        color: json['color']?.toString() ?? '#F7C948',
      );
}

class SubjectStat {
  final int? subjectId;
  final String subjectName;
  final String color;
  final int focusTime;

  const SubjectStat({
    this.subjectId,
    required this.subjectName,
    required this.color,
    required this.focusTime,
  });

  factory SubjectStat.fromJson(Map<String, dynamic> json) => SubjectStat(
        subjectId: json['subjectId'] != null ? (json['subjectId'] as num).toInt() : null,
        subjectName: json['subjectName']?.toString() ?? '기타',
        color: json['color']?.toString() ?? '#9CA3AF',
        focusTime: (json['focusTime'] as num?)?.toInt() ?? 0,
      );
}

class DayStat {
  final String date;
  final int focusTime;
  final int distractionCount;

  const DayStat({
    required this.date,
    required this.focusTime,
    required this.distractionCount,
  });

  factory DayStat.fromJson(Map<String, dynamic> json) => DayStat(
        date: json['date'].toString(),
        focusTime: (json['focusTime'] as num?)?.toInt() ?? 0,
        distractionCount: (json['distractionCount'] as num?)?.toInt() ?? 0,
      );
}

class CalendarDay {
  final String date;
  final int totalFocusTime;
  final int distractionCount;
  final List<SubjectStat> subjects;

  const CalendarDay({
    required this.date,
    required this.totalFocusTime,
    required this.distractionCount,
    required this.subjects,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) => CalendarDay(
        date: json['date'].toString(),
        totalFocusTime: (json['totalFocusTime'] as num?)?.toInt() ?? 0,
        distractionCount: (json['distractionCount'] as num?)?.toInt() ?? 0,
        subjects: (json['subjects'] as List<dynamic>? ?? [])
            .map((s) => SubjectStat.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

class ApiService {
  /// 빌드 시 지정: `flutter build apk --dart-define=API_BASE_URL=https://api.example.com`
  /// 미지정 시 Android 에뮬레이터 → 호스트 PC의 백엔드(로컬 개발용).
  static String get baseUrl {
    const fromEnv = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:4000',
    );
    final trimmed = fromEnv.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  // ── 과목 ────────────────────────────────────────────────────────────────────

  static Future<List<Subject>> getSubjects({required String userId}) async {
    final uri = Uri.parse('$baseUrl/subjects/$userId');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('과목 조회 실패: ${res.body}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['subjects'] as List<dynamic>)
        .map((s) => Subject.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  static Future<Subject> createSubject({
    required String userId,
    required String name,
    required String color,
  }) async {
    final uri = Uri.parse('$baseUrl/subjects');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'name': name, 'color': color}),
    );
    if (res.statusCode != 200) throw Exception('과목 생성 실패: ${res.body}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Subject.fromJson(data['subject'] as Map<String, dynamic>);
  }

  static Future<void> deleteSubject({required int id, required String userId}) async {
    final uri = Uri.parse('$baseUrl/subjects/$id');
    final res = await http.delete(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    if (res.statusCode != 200) throw Exception('과목 삭제 실패: ${res.body}');
  }

  // ── 세션 ────────────────────────────────────────────────────────────────────

  static Future<String> startSession({
    required String userId,
    int? subjectId,
  }) async {
    final uri = Uri.parse('$baseUrl/session/start');
    final body = <String, dynamic>{'userId': userId};
    if (subjectId != null) body['subjectId'] = subjectId;
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) throw Exception('세션 시작 실패: ${res.body}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['sessionId'].toString();
  }

  static Future<void> updateSession({
    required String sessionId,
    required int focusTimeSeconds,
    required int distractionCount,
  }) async {
    final uri = Uri.parse('$baseUrl/session/update');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sessionId': int.parse(sessionId),
        'focusTime': focusTimeSeconds,
        'distractionCount': distractionCount,
      }),
    );
    if (res.statusCode != 200) throw Exception('세션 업데이트 실패: ${res.body}');
  }

  static Future<Map<String, dynamic>> endSession({
    required String sessionId,
    required int focusTimeSeconds,
    required int distractionCount,
  }) async {
    final uri = Uri.parse('$baseUrl/session/end');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sessionId': int.parse(sessionId),
        'focusTime': focusTimeSeconds,
        'distractionCount': distractionCount,
      }),
    );
    if (res.statusCode != 200) throw Exception('세션 종료 실패: ${res.body}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getTodayStats({required String userId}) async {
    final uri = Uri.parse('$baseUrl/session/today/$userId');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('오늘 통계 조회 실패: ${res.body}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<List<SubjectStat>> getTodaySubjectStats({required String userId}) async {
    final uri = Uri.parse('$baseUrl/session/today-subjects/$userId');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('과목별 오늘 통계 실패: ${res.body}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['subjects'] as List<dynamic>)
        .map((s) => SubjectStat.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  static Future<List<CalendarDay>> getCalendarRecords({
    required String userId,
    required int year,
    required int month,
  }) async {
    final uri = Uri.parse('$baseUrl/session/calendar/$userId?year=$year&month=$month');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('캘린더 기록 조회 실패: ${res.body}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['records'] as List<dynamic>)
        .map((r) => CalendarDay.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  static Future<List<DayStat>> getWeeklyStats({required String userId}) async {
    final uri = Uri.parse('$baseUrl/session/weekly/$userId');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('주간 통계 조회 실패: ${res.body}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['days'] as List<dynamic>)
        .map((d) => DayStat.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  static Future<List<DayStat>> getMonthlyStats({required String userId}) async {
    final uri = Uri.parse('$baseUrl/session/monthly/$userId');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('월간 통계 조회 실패: ${res.body}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['days'] as List<dynamic>)
        .map((d) => DayStat.fromJson(d as Map<String, dynamic>))
        .toList();
  }
}
