import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../models/detection_result.dart';
import '../models/session_result.dart';
import '../services/api_service.dart';
import '../services/face_detection_service.dart';
import '../services/realtime_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../theme/retro_ui.dart';

class StudyScreen extends StatefulWidget {
  final Subject? subject;
  const StudyScreen({super.key, this.subject});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> with WidgetsBindingObserver {
  // ── 카메라 ──
  CameraController? _cameraController;
  CameraDescription? _frontCamera;
  bool _isCameraInitialized = false;
  String? _cameraError;

  // ── 얼굴 감지 ──
  final FaceDetectionService _faceDetection = FaceDetectionService();
  bool _isStreaming = false;
  DateTime _lastDetectionTime = DateTime.now();
  static const _detectionInterval = Duration(milliseconds: 500);

  // ── 집중 상태 ──
  FocusStatus _focusStatus = FocusStatus.focused;
  DateTime? _noFaceSince;
  static const _noFaceGracePeriod = Duration(seconds: 15);
  DateTime? _eyesClosedSince;
  static const _eyesOnlyDrowsinessThreshold = Duration(seconds: 5);
  static const _headTiltDrowsinessThreshold = Duration(seconds: 3);

  // ── 앱 이탈 ──
  DateTime? _appLeftAt;
  Timer? _autoEndTimer;
  bool _autoEnded = false;
  static const _autoEndDelay = Duration(seconds: 30);

  // ── 타이머 ──
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _focusTimeSeconds = 0;
  int _distractionCount = 0;
  int _drowsinessCount = 0;

  // ── 세션 ──
  String? _sessionId;
  bool _isLoading = true;
  bool _isEnding = false;
  String get _userId => SupabaseService.currentUser?.id ?? 'anonymous';
  String get _nickname =>
      SupabaseService.currentUser?.userMetadata?['full_name']?.toString() ?? '사용자';

  FocusStatus? _lastAlertedStatus;
  bool get _shouldCountFocus =>
      _focusStatus == FocusStatus.focused || _focusStatus == FocusStatus.eyesClosed;

  // ── 공부방 실시간 ──
  final PageController _pageController = PageController();
  List<StudyUser> _studyUsers = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  /// 깨우기 알람 루프 재생 중(졸음 해제·이탈·종료 시까지)
  bool _pokeAlarmLooping = false;

  // ══════════════════════════════════════
  //  라이프사이클
  // ══════════════════════════════════════

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initFlow();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      default:
        break;
    }
  }

  void _onAppPaused() {
    _stopPokeAlarmLoop();
    _appLeftAt = DateTime.now();
    _stopImageStream();
    _disposeCamera();
    setState(() => _focusStatus = FocusStatus.appLeft);
    _autoEndTimer?.cancel();
    _autoEndTimer = Timer(_autoEndDelay, () {
      _autoEnded = true;
      _timer?.cancel();
    });
  }

  void _onAppResumed() {
    _autoEndTimer?.cancel();
    if (_autoEnded) {
      _endSession();
      return;
    }
    _initCamera();
    if (_appLeftAt != null) {
      final awayDuration = DateTime.now().difference(_appLeftAt!);
      _appLeftAt = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showReturnDialog(awayDuration);
      });
    }
  }

  void _showReturnDialog(Duration awayDuration) {
    final seconds = awayDuration.inSeconds;
    final remaining = _autoEndDelay.inSeconds - seconds;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            size: 48, color: Theme.of(ctx).colorScheme.primary),
        title: const Text('앱을 떠났습니다'),
        content: Text(
          '$seconds초 동안 앱을 떠나있었습니다.\n해당 시간은 집중 시간에 포함되지 않습니다.\n\n'
          '${remaining > 0 ? "$remaining초 더 이탈하면 세션이 자동 종료됩니다." : ""}',
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.of(ctx).pop(); _endSession(); },
            child: const Text('공부 종료'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _focusStatus = FocusStatus.focused);
            },
            child: const Text('계속 공부하기'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  //  초기화
  // ══════════════════════════════════════

  Future<void> _initFlow() async {
    await Future.wait([_initCamera(), _initSession()]);
    _startTimer();
    _joinStudyRoom();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = '사용 가능한 카메라가 없습니다.');
        return;
      }
      _frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        _frontCamera!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await controller.initialize();
      if (!mounted) { controller.dispose(); return; }
      setState(() {
        _cameraController = controller;
        _isCameraInitialized = true;
        _cameraError = null;
      });
      _startImageStream();
    } catch (e) {
      if (mounted) setState(() => _cameraError = '카메라 초기화 실패: $e');
    }
  }

  Future<void> _initSession() async {
    try {
      final sessionId = await ApiService.startSession(
        userId: _userId,
        subjectId: widget.subject?.id,
      );
      if (mounted) setState(() => _sessionId = sessionId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('세션 시작 실패: $e')),
        );
      }
    }
  }

  void _joinStudyRoom() {
    RealtimeService.joinStudyRoom(
      userId: _userId,
      nickname: _nickname,
      status: 'studying',
      subjectName: widget.subject?.name,
      onPresenceChanged: (users) {
        if (mounted) setState(() => _studyUsers = users);
      },
      onPoked: _onPokeReceived,
    );
  }

  /// 다른 사용자 깨우기: 졸음 중이면 알람을 졸음이 풀릴 때까지 반복 재생
  Future<void> _onPokeReceived() async {
    if (_focusStatus != FocusStatus.drowsy) return;
    await _startPokeAlarmLoop();
  }

  Future<void> _startPokeAlarmLoop() async {
    try {
      await _audioPlayer.stop();
      _pokeAlarmLooping = true;
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('mixkit_wake_alarm.mp3'));
    } catch (_) {
      _pokeAlarmLooping = false;
    }
  }

  Future<void> _stopPokeAlarmLoop() async {
    if (!_pokeAlarmLooping) return;
    _pokeAlarmLooping = false;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
    } catch (_) {}
  }

  // ══════════════════════════════════════
  //  이미지 스트림 & 얼굴 감지
  // ══════════════════════════════════════

  void _startImageStream() {
    final controller = _cameraController;
    if (controller == null || _isStreaming || _frontCamera == null) return;
    controller.startImageStream(_onCameraFrame);
    _isStreaming = true;
  }

  void _onCameraFrame(CameraImage image) {
    final now = DateTime.now();
    if (now.difference(_lastDetectionTime) < _detectionInterval) return;
    _lastDetectionTime = now;
    _faceDetection.detectFace(image, _frontCamera!).then((result) {
      if (!mounted || result == null) return;
      _processDetectionResult(result);
    });
  }

  void _stopImageStream() {
    if (_cameraController != null && _isStreaming) {
      _cameraController!.stopImageStream();
      _isStreaming = false;
    }
  }

  // ══════════════════════════════════════
  //  감지 결과 → 집중 상태 판정
  // ══════════════════════════════════════

  void _processDetectionResult(DetectionResult result) {
    if (_focusStatus == FocusStatus.appLeft) return;
    if (!result.faceDetected) {
      _eyesClosedSince = null;
      _noFaceSince ??= DateTime.now();
      final awayDuration = DateTime.now().difference(_noFaceSince!);
      if (awayDuration >= _noFaceGracePeriod) {
        _updateFocusStatus(FocusStatus.awayFromSeat);
      }
      return;
    }
    _noFaceSince = null;
    if (_focusStatus == FocusStatus.awayFromSeat) {
      _updateFocusStatus(FocusStatus.focused);
    }
    if (result.areEyesClosed) {
      _eyesClosedSince ??= DateTime.now();
      final closedDuration = DateTime.now().difference(_eyesClosedSince!);
      final threshold = result.isHeadTiltedDown
          ? _headTiltDrowsinessThreshold
          : _eyesOnlyDrowsinessThreshold;
      if (closedDuration >= threshold) {
        _updateFocusStatus(FocusStatus.drowsy);
      } else {
        _updateFocusStatus(FocusStatus.eyesClosed);
      }
    } else if (result.isHeadTiltedDown) {
      _eyesClosedSince = null;
      _updateFocusStatus(FocusStatus.eyesClosed);
    } else {
      _eyesClosedSince = null;
      _updateFocusStatus(FocusStatus.focused);
    }
  }

  void _updateFocusStatus(FocusStatus newStatus) {
    final prevStatus = _focusStatus;
    if (prevStatus == newStatus) return;
    setState(() {
      _focusStatus = newStatus;
      final wasCounting = prevStatus == FocusStatus.focused || prevStatus == FocusStatus.eyesClosed;
      final stoppedCounting =
          newStatus == FocusStatus.awayFromSeat || newStatus == FocusStatus.drowsy;
      if (wasCounting && stoppedCounting) {
        // 자리 이탈은 집중 시간만 제외, 산만 횟수에는 포함하지 않음
        if (newStatus == FocusStatus.drowsy) {
          _drowsinessCount++;
          _distractionCount++;
        }
      }
    });
    _showStatusAlert(newStatus);

    // 실시간 공부방에 상태 브로드캐스트
    final rtStatus = (newStatus == FocusStatus.drowsy) ? 'drowsy' : 'studying';
    RealtimeService.updateStatus(rtStatus);

    // 졸음이 아니게 되면 깨우기 루프 알람 중지
    if (newStatus != FocusStatus.drowsy) {
      _stopPokeAlarmLoop();
    }
  }

  void _showStatusAlert(FocusStatus status) {
    if (status == FocusStatus.focused || status == FocusStatus.appLeft) {
      _lastAlertedStatus = null;
      return;
    }
    // 하단 스낵바는 졸음(drowsy) 확정 시에만 — 눈 감김·자리 이탈은 UI 뱃지만 사용
    if (status != FocusStatus.drowsy) {
      return;
    }
    if (_lastAlertedStatus == status) return;
    _lastAlertedStatus = status;
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '졸음이 감지되었습니다! 잠시 스트레칭을 하세요.',
          style: TextStyle(color: Colors.white),
        ),
        duration: Duration(seconds: 2),
        backgroundColor: AppTheme.drowsyAccent,
      ),
    );
  }

  // ══════════════════════════════════════
  //  타이머
  // ══════════════════════════════════════

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
        if (_shouldCountFocus) _focusTimeSeconds++;
      });
      // 공부방 Presence에 실제 집중 시간 공유(다른 사용자 카드 실시간 표시)
      RealtimeService.updateFocusSeconds(_focusTimeSeconds);
    });
  }

  // ══════════════════════════════════════
  //  세션 종료
  // ══════════════════════════════════════

  Future<void> _endSession() async {
    if (_isEnding) return;
    await _stopPokeAlarmLoop();
    setState(() => _isEnding = true);
    _timer?.cancel();
    _autoEndTimer?.cancel();
    _stopImageStream();
    await RealtimeService.leaveStudyRoom();

    if (_sessionId == null) {
      _navigateToResult(SessionResult(
        sessionId: 'local',
        focusTime: Duration(seconds: _focusTimeSeconds),
        distractionCount: _distractionCount,
      ));
      return;
    }
    try {
      await ApiService.updateSession(
        sessionId: _sessionId!,
        focusTimeSeconds: _focusTimeSeconds,
        distractionCount: _distractionCount,
      );
      final resultData = await ApiService.endSession(
        sessionId: _sessionId!,
        focusTimeSeconds: _focusTimeSeconds,
        distractionCount: _distractionCount,
      );
      if (!mounted) return;
      _navigateToResult(SessionResult(
        sessionId: resultData['sessionId'].toString(),
        focusTime: Duration(seconds: resultData['focusTime'] as int),
        distractionCount: resultData['distractionCount'] as int,
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('세션 종료 실패: $e')),
        );
        setState(() => _isEnding = false);
      }
    }
  }

  void _navigateToResult(SessionResult result) {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/result', arguments: result);
  }

  // ══════════════════════════════════════
  //  리소스 해제
  // ══════════════════════════════════════

  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    if (controller != null) {
      _cameraController = null;
      _isCameraInitialized = false;
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    _pokeAlarmLooping = false;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _autoEndTimer?.cancel();
    _stopImageStream();
    _faceDetection.dispose();
    _cameraController?.dispose();
    _pageController.dispose();
    _audioPlayer.dispose();
    RealtimeService.leaveStudyRoom();
    super.dispose();
  }

  // ══════════════════════════════════════
  //  UI helpers
  // ══════════════════════════════════════

  String _formatTime(int seconds) {
    final d = Duration(seconds: seconds);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  ({Color color, IconData icon, String label}) get _statusDisplay {
    final scheme = Theme.of(context).colorScheme;
    switch (_focusStatus) {
      case FocusStatus.focused:
        return (color: scheme.primary, icon: Icons.face, label: '집중 중');
      case FocusStatus.eyesClosed:
        return (color: scheme.primary, icon: Icons.visibility_off, label: '눈 감김 감지');
      case FocusStatus.drowsy:
        return (color: scheme.secondary, icon: Icons.bedtime, label: '졸음 감지!');
      case FocusStatus.awayFromSeat:
        return (color: AppTheme.awaySeatAccent, icon: Icons.event_seat, label: '자리 이탈');
      case FocusStatus.appLeft:
        return (color: Colors.grey, icon: Icons.exit_to_app, label: '앱 이탈');
    }
  }

  String get _statusMessage {
    switch (_focusStatus) {
      case FocusStatus.drowsy:
        return '졸음이 감지되어 타이머가 일시정지되었습니다';
      case FocusStatus.awayFromSeat:
        return '얼굴이 화면에 잡히지 않아 자리 이탈로 간주합니다. 집중 시간이 멈춥니다';
      case FocusStatus.appLeft:
        return '앱을 떠나 타이머가 일시정지되었습니다';
      default:
        return '얼굴과 눈 상태를 자동으로 감지합니다';
    }
  }

  // ══════════════════════════════════════
  //  빌드
  // ══════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // 시스템/앱바 뒤로가기도 ■ 종료와 동일하게 세션 저장·결과 화면으로 이동
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _endSession();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.subject != null ? widget.subject!.name : '공부 중'),
          actions: [
            IconButton(
              onPressed: _isEnding ? null : _endSession,
              icon: const Icon(Icons.stop),
              tooltip: '공부 종료',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : PageView(
                controller: _pageController,
                children: [
                  _buildCameraPage(),
                  _buildStudyRoomPage(),
                ],
              ),
      ),
    );
  }

  // ── 카메라 페이지 ─────────────────────────────────────────────────────────
  Widget _buildCameraPage() {
    final status = _statusDisplay;
    return Column(
      children: [
        // 스와이프 힌트
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chevron_right, size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
              Text(
                '← 밀어서 공부방 보기',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ),

        // 카메라 프리뷰 + 상태 오버레이
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              Container(
                color: Colors.black,
                width: double.infinity,
                child: _buildCameraPreview(),
              ),
              // 집중 상태 뱃지
              Positioned(
                top: 12,
                right: 12,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status.color.withAlpha(210),
                    borderRadius: reelyRadius(context, 16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(status.icon, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(status.label,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              // 졸음/이탈 시 테두리 경고
              if (_focusStatus == FocusStatus.drowsy ||
                  _focusStatus == FocusStatus.awayFromSeat ||
                  _focusStatus == FocusStatus.appLeft)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _focusStatus == FocusStatus.drowsy
                              ? Theme.of(context).colorScheme.secondary
                              : _focusStatus == FocusStatus.awayFromSeat
                                  ? AppTheme.awaySeatAccent
                                  : Colors.grey,
                          width: 4,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 타이머 & 통계
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTimerColumn('총 경과 시간', _formatTime(_elapsedSeconds)),
                    _buildTimerColumn('실제 집중 시간', _formatTime(_focusTimeSeconds)),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      avatar: Icon(Icons.warning_amber, size: 18,
                          color: Theme.of(context).colorScheme.primary),
                      label: Text('산만: $_distractionCount'),
                    ),
                    Chip(
                      avatar: Icon(Icons.bedtime,
                          size: 18, color: Theme.of(context).colorScheme.secondary),
                      label: Text('졸음: $_drowsinessCount'),
                    ),
                  ],
                ),
                Text(
                  _statusMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _shouldCountFocus
                            ? Colors.grey
                            : Theme.of(context).colorScheme.secondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(_cameraError!, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('카메라 준비 중...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize!.height,
          height: _cameraController!.value.previewSize!.width,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildTimerColumn(String label, String time) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(time, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }

  // ── 공부방 페이지 ─────────────────────────────────────────────────────────
  Widget _buildStudyRoomPage() {
    final otherUsers = _studyUsers.where((u) => u.userId != _userId).toList();

    return Column(
      children: [
        // 헤더
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chevron_left, size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
              Text(
                '밀어서 내 카메라 보기 →',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.people, size: 20),
              const SizedBox(width: 8),
              Text(
                '지금 함께 공부 중 · ${otherUsers.length + 1}명',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // 내 상태 카드 (항상 첫 번째)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _UserStatusCard(
            nickname: '$_nickname (나)',
            status: _focusStatus == FocusStatus.drowsy ? 'drowsy' : 'studying',
            subjectName: widget.subject?.name,
            focusSeconds: _focusTimeSeconds,
            isSelf: true,
            onPoke: null,
          ),
        ),

        const SizedBox(height: 8),

        // 다른 사용자들
        Expanded(
          child: otherUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.group_off, size: 48,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25)),
                      const SizedBox(height: 12),
                      Text(
                        '아직 다른 공부 중인 이용자가 없어요.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: otherUsers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final user = otherUsers[i];
                    return _UserStatusCard(
                      nickname: user.nickname,
                      status: user.status,
                      subjectName: user.subjectName,
                      focusSeconds: user.focusSeconds,
                      isSelf: false,
                      onPoke: user.isDrowsy
                          ? () => _sendPoke(user)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _sendPoke(StudyUser target) {
    RealtimeService.sendPoke(
      targetUserId: target.userId,
      senderNickname: _nickname,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${target.nickname}님에게 기상 알림을 보냈습니다! 🔔'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── 사용자 상태 카드 ───────────────────────────────────────────────────────────
class _UserStatusCard extends StatelessWidget {
  final String nickname;
  final String status; // 'studying' | 'drowsy'
  final String? subjectName;
  final int focusSeconds;
  final bool isSelf;
  final VoidCallback? onPoke;

  const _UserStatusCard({
    required this.nickname,
    required this.status,
    this.subjectName,
    required this.focusSeconds,
    required this.isSelf,
    required this.onPoke,
  });

  static String _formatHms(int seconds) {
    final d = Duration(seconds: seconds);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final isDrowsy = status == 'drowsy';
    final theme = Theme.of(context);

    final drowsy = theme.colorScheme.secondary;
    // 다른 사용자 + 졸음일 때만 중앙 알람 버튼 표시(탭 시에만 poke 전송)
    final showAlarmEmojiButton = !isSelf && isDrowsy && onPoke != null;

    final focusTimeBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '실제 집중',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _formatHms(focusSeconds),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );

    final outlineW = isEightBitContext(context) ? 3.0 : 1.5;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: isDrowsy ? drowsy.withAlpha(20) : null,
      shape: RoundedRectangleBorder(
        borderRadius: reelyRadius(context, 12),
        side: isDrowsy
            ? BorderSide(color: drowsy, width: outlineW)
            : isEightBitContext(context)
                ? BorderSide(color: theme.colorScheme.outline, width: 3)
                : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // GIF 상태 이미지
            ClipRRect(
              borderRadius: reelyRadius(context, 8),
              child: Image.asset(
                isDrowsy ? 'assets/조는중.gif' : 'assets/공부중.gif',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),

            // 닉네임 + 과목 + 상태
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (subjectName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subjectName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isDrowsy ? drowsy : theme.colorScheme.primary,
                          shape: isEightBitContext(context)
                              ? BoxShape.rectangle
                              : BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isDrowsy ? '졸음 감지됨' : '공부 중',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDrowsy ? drowsy : theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 정보와 타이머 사이 — 졸음인 상대에게만 알람 이모지 버튼
            if (showAlarmEmojiButton) ...[
              const SizedBox(width: 6),
              IconButton(
                onPressed: onPoke,
                tooltip: '깨우기 알람 보내기',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                icon: Text(
                  '🔔',
                  style: TextStyle(
                    fontSize: 30,
                    height: 1,
                    color: isEightBitContext(context)
                        ? theme.colorScheme.onSurface
                        : drowsy,
                  ),
                ),
              ),
            ],

            const SizedBox(width: 10),

            // 실제 집중 시간 — 카드 오른쪽
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [focusTimeBlock],
            ),
          ],
        ),
      ),
    );
  }
}
