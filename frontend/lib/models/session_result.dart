class SessionResult {
  final String sessionId;
  final Duration focusTime;
  final int distractionCount;

  SessionResult({
    required this.sessionId,
    required this.focusTime,
    required this.distractionCount,
  });
}

