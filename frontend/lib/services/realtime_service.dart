import 'package:supabase_flutter/supabase_flutter.dart';

/// 공부방 참여자 정보
class StudyUser {
  final String userId;
  final String nickname;
  final String status; // 'studying' | 'drowsy' | 'offline'
  final String? subjectName;
  /// Presence로 공유되는 실제 집중 시간(초)
  final int focusSeconds;

  const StudyUser({
    required this.userId,
    required this.nickname,
    required this.status,
    this.subjectName,
    this.focusSeconds = 0,
  });

  bool get isDrowsy => status == 'drowsy';
  bool get isStudying => status == 'studying';
}

/// Supabase Realtime을 이용한 공부방 실시간 현황 서비스
class RealtimeService {
  static RealtimeChannel? _channel;
  static String? _currentUserId;

  static int _focusSecondsFromPayload(Map<String, dynamic> p) {
    final fs = p['focusSeconds'];
    if (fs is num) return fs.toInt();
    return int.tryParse(fs?.toString() ?? '') ?? 0;
  }

  static Map<String, dynamic>? _currentUserPayload() {
    if (_channel == null || _currentUserId == null) return null;
    for (final state in _channel!.presenceState()) {
      for (final presence in state.presences) {
        final p = presence.payload;
        if (p['userId']?.toString() == _currentUserId) {
          return Map<String, dynamic>.from(p);
        }
      }
    }
    return null;
  }

  /// 공부방 채널에 참가 (Presence + Broadcast)
  static Future<void> joinStudyRoom({
    required String userId,
    required String nickname,
    required String status,
    String? subjectName,
    required void Function(List<StudyUser>) onPresenceChanged,
    required void Function() onPoked,
  }) async {
    _currentUserId = userId;

    await leaveStudyRoom();

    _channel = Supabase.instance.client.channel(
      'study-room',
      opts: const RealtimeChannelConfig(self: false),
    );

    _channel!
        .onPresenceSync((_) {
          final users = _parsePresence(_channel!.presenceState());
          onPresenceChanged(users);
        })
        .onPresenceJoin((_) {
          final users = _parsePresence(_channel!.presenceState());
          onPresenceChanged(users);
        })
        .onPresenceLeave((_) {
          final users = _parsePresence(_channel!.presenceState());
          onPresenceChanged(users);
        })
        .onBroadcast(
          event: 'poke',
          callback: (payload) {
            final Map<String, dynamic> inner;
            final nested = payload['payload'];
            if (nested is Map) {
              inner = Map<String, dynamic>.from(
                Map<dynamic, dynamic>.from(nested),
              );
            } else {
              inner = payload;
            }
            if (inner['targetUserId']?.toString() == userId) {
              onPoked();
            }
          },
        )
        .subscribe((subStatus, _) async {
          if (subStatus == RealtimeSubscribeStatus.subscribed) {
            await _channel!.track({
              'userId': userId,
              'nickname': nickname,
              'status': status,
              'focusSeconds': 0,
              if (subjectName != null) 'subjectName': subjectName,
            });
          }
        });
  }

  /// 내 공부 상태 업데이트 (focused → drowsy 등)
  static Future<void> updateStatus(String status) async {
    final base = _currentUserPayload();
    if (_channel == null || base == null) return;
    await _channel!.track({...base, 'status': status});
  }

  /// 실제 집중 시간을 다른 참가자에게 Presence로 공유 (1초 단위 갱신 권장)
  static Future<void> updateFocusSeconds(int seconds) async {
    final base = _currentUserPayload();
    if (_channel == null || base == null) return;
    if (_focusSecondsFromPayload(base) == seconds) return;
    await _channel!.track({...base, 'focusSeconds': seconds});
  }

  /// 졸음 감지된 사용자에게 알림 발송
  static void sendPoke({
    required String targetUserId,
    required String senderNickname,
  }) {
    _channel?.sendBroadcastMessage(
      event: 'poke',
      payload: {
        'targetUserId': targetUserId,
        'senderNickname': senderNickname,
      },
    );
  }

  /// 공부방 나가기
  static Future<void> leaveStudyRoom() async {
    if (_channel != null) {
      await _channel!.untrack();
      await Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
    }
  }

  static List<StudyUser> _parsePresence(List<SinglePresenceState> states) {
    final users = <StudyUser>[];
    for (final state in states) {
      for (final presence in state.presences) {
        final p = presence.payload;
        final userId = p['userId']?.toString();
        final nickname = p['nickname']?.toString();
        final st = p['status']?.toString() ?? 'studying';
        if (userId == null || nickname == null) continue;
        final focusSec = _focusSecondsFromPayload(
          Map<String, dynamic>.from(p),
        );
        users.add(StudyUser(
          userId: userId,
          nickname: nickname,
          status: st,
          subjectName: p['subjectName']?.toString(),
          focusSeconds: focusSec,
        ));
      }
    }
    return users;
  }
}
