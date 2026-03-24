import 'dart:math';
import 'dart:ui' show Size;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/detection_result.dart';

/// 카메라 프레임에서 얼굴 + 눈 윤곽 + 고개 각도를 분석하는 온디바이스 서비스.
/// EAR(Eye Aspect Ratio)를 직접 계산해 실눈/감음 구분 정확도를 높임.
class FaceDetectionService {
  late final FaceDetector _faceDetector;
  bool _isProcessing = false;

  FaceDetectionService() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableContours: true,
        enableLandmarks: false,
        enableClassification: true, // EAR fallback용 확률값
        enableTracking: false,
        minFaceSize: 0.15,
      ),
    );
  }

  bool get isProcessing => _isProcessing;

  Future<DetectionResult?> detectFace(
      CameraImage image, CameraDescription camera) async {
    if (_isProcessing) return null;
    _isProcessing = true;

    try {
      final inputImage = _buildInputImage(image, camera);
      if (inputImage == null) return null;

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return DetectionResult(faceDetected: false);
      }

      // 바운딩 박스가 가장 큰 얼굴 = 카메라에 가장 가까운 사람
      final face = faces.reduce((a, b) {
        final areaA = a.boundingBox.width * a.boundingBox.height;
        final areaB = b.boundingBox.width * b.boundingBox.height;
        return areaA >= areaB ? a : b;
      });

      // 눈 윤곽에서 EAR 계산
      final leftEAR = _calculateEAR(
          face.contours[FaceContourType.leftEye]?.points);
      final rightEAR = _calculateEAR(
          face.contours[FaceContourType.rightEye]?.points);

      return DetectionResult(
        faceDetected: true,
        leftEyeOpenProb: face.leftEyeOpenProbability,
        rightEyeOpenProb: face.rightEyeOpenProbability,
        leftEAR: leftEAR,
        rightEAR: rightEAR,
        headAngleX: face.headEulerAngleX,
        headAngleY: face.headEulerAngleY,
      );
    } catch (e) {
      debugPrint('얼굴 감지 오류: $e');
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  /// ML Kit 눈 윤곽 16포인트에서 Eye Aspect Ratio 계산.
  ///
  /// 16포인트 배치 (시계 방향, 안쪽 모서리부터):
  ///   [0]  = 안쪽 꼬리
  ///   [3]  = 위쪽 눈꺼풀 (안쪽)
  ///   [5]  = 위쪽 눈꺼풀 (바깥쪽)
  ///   [8]  = 바깥쪽 꼬리
  ///   [11] = 아래쪽 눈꺼풀 (바깥쪽)
  ///   [13] = 아래쪽 눈꺼풀 (안쪽)
  ///
  /// EAR = (|p3-p13| + |p5-p11|) / (2 × |p0-p8|)
  double? _calculateEAR(List<Point<int>>? points) {
    if (points == null || points.length < 16) return null;

    final vertical1 = _dist(points[3], points[13]);
    final vertical2 = _dist(points[5], points[11]);
    final horizontal = _dist(points[0], points[8]);

    if (horizontal < 1.0) return null;
    return (vertical1 + vertical2) / (2.0 * horizontal);
  }

  double _dist(Point<int> a, Point<int> b) {
    final dx = (a.x - b.x).toDouble();
    final dy = (a.y - b.y).toDouble();
    return sqrt(dx * dx + dy * dy);
  }

  // ── InputImage 변환 ──

  InputImage? _buildInputImage(CameraImage image, CameraDescription camera) {
    final rotation = _sensorToRotation(camera.sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }

    return InputImage.fromBytes(
      bytes: allBytes.done().buffer.asUint8List(),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  InputImageRotation? _sensorToRotation(int orientation) {
    switch (orientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return null;
    }
  }

  void dispose() {
    _faceDetector.close();
  }
}
