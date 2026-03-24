/// 집중 상태 분류
enum FocusStatus {
  focused,     // 집중 중 (얼굴 감지 + 눈 뜸)
  eyesClosed,  // 눈 감김 (짧은 시간, 아직 집중으로 간주)
  drowsy,       // 졸음 (눈 오래 감음 또는 고개 떨어짐)
  awayFromSeat, // 자리 이탈 — 얼굴이 프레임에 거의/전혀 안 잡힐 때(연속 미검출)
  appLeft,      // 앱 이탈 (다른 앱으로 전환)
}

/// ML Kit 감지 결과를 담는 모델
class DetectionResult {
  final bool faceDetected;

  // ML Kit 확률 (fallback용)
  final double? leftEyeOpenProb;
  final double? rightEyeOpenProb;

  // Eye Aspect Ratio — 눈 윤곽 16포인트 기반 (primary)
  // 눈 뜸: 0.25~0.40 / 실눈: 0.15~0.25 / 감김: 0.05~0.15
  final double? leftEAR;
  final double? rightEAR;

  final double? headAngleX; // pitch: 양수=위, 음수=아래
  final double? headAngleY; // yaw: 좌우 회전

  static const double earClosedThreshold = 0.21;
  static const double probClosedThreshold = 0.25;
  static const double headTiltDownThreshold = -15.0;

  DetectionResult({
    required this.faceDetected,
    this.leftEyeOpenProb,
    this.rightEyeOpenProb,
    this.leftEAR,
    this.rightEAR,
    this.headAngleX,
    this.headAngleY,
  });

  /// EAR 기반 유효값 (양쪽 평균 / 한쪽만 / null)
  double? get effectiveEAR {
    if (leftEAR != null && rightEAR != null) {
      return (leftEAR! + rightEAR!) / 2.0;
    }
    return leftEAR ?? rightEAR;
  }

  /// 확률 기반 유효값 (fallback)
  double? get effectiveEyeOpenProb {
    if (leftEyeOpenProb != null && rightEyeOpenProb != null) {
      return (leftEyeOpenProb! + rightEyeOpenProb!) / 2.0;
    }
    return leftEyeOpenProb ?? rightEyeOpenProb;
  }

  /// 눈 감김 여부 — EAR 또는 확률 중 하나라도 감지되면 true.
  /// 졸음 판정은 5초 지속이 필요하므로 순간 오탐은 자연스럽게 걸러짐.
  bool get areEyesClosed {
    final ear = effectiveEAR;
    final prob = effectiveEyeOpenProb;

    if (ear != null && ear < earClosedThreshold) return true;
    if (prob != null && prob < probClosedThreshold) return true;

    return false;
  }

  /// 고개가 아래로 상당히 기울어졌는지
  bool get isHeadTiltedDown {
    if (headAngleX == null) return false;
    return headAngleX! < headTiltDownThreshold;
  }
}
