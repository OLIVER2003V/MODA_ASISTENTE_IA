import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';
import '../../../../core/theme/app_theme.dart';

class FaceScanPage extends StatefulWidget {
  const FaceScanPage({super.key});

  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage>
    with TickerProviderStateMixin {
  // Cámara
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = -1;

  // ML Kit Face Mesh
  final FaceMeshDetector _meshDetector = FaceMeshDetector(
    option: FaceMeshDetectorOptions.faceMesh,
  );
  bool _canProcess = true;
  bool _isBusy = false;

  // Estado
  bool _isCameraReady = false;
  bool _faceDetected = false;
  bool _isScanning = false;
  bool _scanComplete = false;
  int _scanProgress = 0;
  String _statusMessage = 'Iniciando cámara...';
  int _stableFrames = 0;

  // Animaciones
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _scanLineController;

  final List<String> _scanMessages = [
    'Rostro detectado...',
    'Generando malla facial...',
    'Mapeando 468 puntos...',
    'Procesando geometría 3D...',
    'Construyendo triangulación...',
    'Verificando estructura...',
    'Finalizando análisis...',
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeCamera();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();

    // Buscar cámara frontal
    for (int i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == CameraLensDirection.front) {
        _cameraIndex = i;
        break;
      }
    }

    if (_cameraIndex == -1 && _cameras.isNotEmpty) {
      _cameraIndex = 0;
    }

    if (_cameraIndex >= 0) {
      await _startCamera();
    } else {
      setState(() {
        _statusMessage = 'No se encontró cámara';
      });
    }
  }

  Future<void> _startCamera() async {
    final camera = _cameras[_cameraIndex];

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isCameraReady = true;
          _statusMessage = 'Posiciona tu rostro en el marco';
        });

        await _controller!.startImageStream(_processCameraImage);
      }
    } catch (e) {
      debugPrint('Error inicializando cámara: $e');
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (!_canProcess || _isBusy || _scanComplete) return;
    _isBusy = true;

    final inputImage = _inputImageFromCameraImage(image);

    if (inputImage == null) {
      _isBusy = false;
      return;
    }

    try {
      final meshes = await _meshDetector.processImage(inputImage);

      if (mounted) {
        setState(() {
          if (meshes.isNotEmpty) {
            _stableFrames++;
            if (!_faceDetected) {
              _faceDetected = true;
              _statusMessage = 'Malla facial detectada - Mantén la posición';
            }

            if (_stableFrames > 15 && !_isScanning) {
              _startScan();
            }
          } else {
            _stableFrames = 0;
            if (_faceDetected && !_isScanning) {
              _faceDetected = false;
              _statusMessage = 'Posiciona tu rostro en el marco';
            }
          }
        });
      }
    } catch (e) {
      debugPrint('FaceMesh: Error procesando imagen: $e');
    }

    _isBusy = false;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _cameras[_cameraIndex];
    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );
    if (rotation == null) return null;

    InputImageFormat? format;
    if (Platform.isAndroid) {
      format = InputImageFormat.nv21;
    } else if (Platform.isIOS) {
      format = InputImageFormat.bgra8888;
    }

    if (format == null) return null;

    final bytes = _concatenatePlanes(image.planes);

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _scanProgress = 0;
      _statusMessage = _scanMessages[0];
    });

    HapticFeedback.mediumImpact();

    Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _scanProgress++;
        if (_scanProgress < _scanMessages.length) {
          _statusMessage = _scanMessages[_scanProgress];
        }
      });

      if (_scanProgress >= _scanMessages.length) {
        timer.cancel();
        _completeScan();
      }
    });
  }

  Future<void> _completeScan() async {
    _canProcess = false;
    HapticFeedback.heavyImpact();

    setState(() {
      _scanComplete = true;
      _statusMessage = 'Escaneo Completado';
    });

    // Capturar foto limpia del rostro (sin lineas de mesh)
    String? photoPath;
    try {
      if (_controller != null && _controller!.value.isInitialized) {
        // Detener el stream para poder tomar la foto
        await _controller!.stopImageStream();
        final XFile photo = await _controller!.takePicture();
        photoPath = photo.path;
      }
    } catch (e) {
      debugPrint('Error capturando foto: $e');
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context, photoPath);
      }
    });
  }

  @override
  void dispose() {
    _canProcess = false;
    _controller?.dispose();
    _meshDetector.close();
    _pulseController.dispose();
    _glowController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isCameraReady && _controller != null)
            _buildCameraPreview()
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          if (_isCameraReady)
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _OverlayPainter(
                    faceDetected: _faceDetected,
                    isScanning: _isScanning,
                    scanComplete: _scanComplete,
                    glowValue: _glowController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),

          if (_isScanning && !_scanComplete)
            AnimatedBuilder(
              animation: _scanLineController,
              builder: (context, _) {
                final top =
                    size.height * 0.15 +
                    (size.height * 0.5 * _scanLineController.value);
                return Positioned(
                  top: top,
                  left: size.width * 0.1,
                  right: size.width * 0.1,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppPalette.accent.withOpacity(0.7),
                          AppPalette.accent,
                          AppPalette.accent.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppPalette.accent.withOpacity(0.8),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const Spacer(),
                _buildBottomPanel(theme, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _controller!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Transform.scale(
      scale: scale,
      child: Center(child: CameraPreview(_controller!)),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            style: IconButton.styleFrom(backgroundColor: Colors.black45),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _scanComplete
                  ? AppPalette.success.withOpacity(0.9)
                  : Colors.black54,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: _scanComplete
                    ? AppPalette.success
                    : (_faceDetected ? AppPalette.accent : Colors.white30),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _scanComplete
                      ? Icons.check_circle
                      : (_faceDetected
                            ? Icons.face
                            : Icons.face_retouching_natural),
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  _scanComplete
                      ? 'COMPLETADO'
                      : (_isScanning ? 'ESCANEANDO...' : 'ANÁLISIS FACIAL'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(width: 56),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: (isDark ? AppPalette.gray900 : Colors.white).withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _scanComplete
              ? AppPalette.success.withOpacity(0.5)
              : (_faceDetected
                    ? AppPalette.accent.withOpacity(0.3)
                    : Colors.white24),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: Tween(begin: 0.95, end: 1.05).animate(_pulseController),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: _scanComplete
                    ? const LinearGradient(
                        colors: [AppPalette.success, AppPalette.successLight],
                      )
                    : (_faceDetected
                          ? AppPalette.accentGradient
                          : LinearGradient(
                              colors: [AppPalette.gray600, AppPalette.gray500],
                            )),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        (_scanComplete
                                ? AppPalette.success
                                : (_faceDetected
                                      ? AppPalette.accent
                                      : AppPalette.gray500))
                            .withOpacity(0.5),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                _scanComplete
                    ? Icons.check_rounded
                    : (_faceDetected
                          ? Icons.face
                          : Icons.face_retouching_natural),
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _statusMessage,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: _scanComplete
                  ? AppPalette.success
                  : theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_isScanning && !_scanComplete) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _scanProgress / _scanMessages.length,
                minHeight: 10,
                backgroundColor: isDark
                    ? AppPalette.gray700
                    : AppPalette.gray200,
                valueColor: AlwaysStoppedAnimation<Color>(AppPalette.accent),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${((_scanProgress / _scanMessages.length) * 100).toInt()}%',
              style: TextStyle(
                color: AppPalette.accent,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ] else if (_scanComplete) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppPalette.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified,
                    color: AppPalette.success,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '¡Foto capturada!',
                    style: TextStyle(
                      color: AppPalette.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _faceDetected
                        ? AppPalette.success
                        : AppPalette.gray400,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _faceDetected ? 'Analizando posición...' : 'Buscando rostro...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final bool faceDetected;
  final bool isScanning;
  final bool scanComplete;
  final double glowValue;

  _OverlayPainter({
    required this.faceDetected,
    required this.isScanning,
    required this.scanComplete,
    required this.glowValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // OVERLAY FIJO - más redondo y grande
    final center = Offset(size.width / 2, size.height * 0.35);
    final ovalWidth = size.width * 0.85; // Más ancho (era 0.75)
    final ovalHeight = size.height * 0.55; // Más alto (era 0.48)

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withOpacity(0.7),
    );

    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withOpacity(0.7),
    );
    canvas.drawOval(ovalRect, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    Color borderColor = scanComplete
        ? AppPalette.success
        : (isScanning
              ? AppPalette.accent
              : (faceDetected
                    ? AppPalette.accent.withOpacity(0.7)
                    : Colors.white38));

    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = scanComplete ? 4 : 3,
    );

    if (faceDetected || isScanning) {
      canvas.drawOval(
        ovalRect,
        Paint()
          ..color = borderColor.withOpacity(0.2 * glowValue)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 15
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter old) => true;
}

double translateX(
  double x,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection cameraLensDirection,
) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
      return x * canvasSize.width / imageSize.height;
    case InputImageRotation.rotation270deg:
      return canvasSize.width - x * canvasSize.width / imageSize.height;
    case InputImageRotation.rotation0deg:
    case InputImageRotation.rotation180deg:
      switch (cameraLensDirection) {
        case CameraLensDirection.back:
          return x * canvasSize.width / imageSize.width;
        case CameraLensDirection.front:
          return canvasSize.width - x * canvasSize.width / imageSize.width;
        case CameraLensDirection.external:
          return x * canvasSize.width / imageSize.width;
      }
  }
}

double translateY(
  double y,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection cameraLensDirection,
) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
    case InputImageRotation.rotation270deg:
      return y * canvasSize.height / imageSize.width;
    case InputImageRotation.rotation0deg:
    case InputImageRotation.rotation180deg:
      return y * canvasSize.height / imageSize.height;
  }
}

// Painter con MALLA COMPLETA
class FaceMeshPainter extends CustomPainter {
  final List<FaceMesh> meshes;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final bool isScanning;
  final bool scanComplete;
  final double glowIntensity;

  FaceMeshPainter({
    required this.meshes,
    required this.imageSize,
    required this.rotation,
    required this.cameraLensDirection,
    required this.isScanning,
    required this.scanComplete,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Color meshColor = scanComplete
        ? AppPalette.success
        : (isScanning ? AppPalette.accent : const Color(0xFF00D9FF));

    for (final FaceMesh mesh in meshes) {
      // Convertir puntos a pantalla
      final List<Offset> screenPoints = [];
      for (final point in mesh.points) {
        final x = translateX(
          point.x.toDouble(),
          size,
          imageSize,
          rotation,
          cameraLensDirection,
        );
        final y = translateY(
          point.y.toDouble(),
          size,
          imageSize,
          rotation,
          cameraLensDirection,
        );
        screenPoints.add(Offset(x, y));
      }

      // AGREGAR PUNTOS ADICIONALES EN LOS BORDES para cobertura total
      final List<Offset> allPoints = List.from(screenPoints);

      // Obtener bounding box del rostro
      final rect = mesh.boundingBox;
      final left = translateX(
        rect.left,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final top = translateY(
        rect.top,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final right = translateX(
        rect.right,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final bottom = translateY(
        rect.bottom,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );

      final faceWidth = (right - left).abs();
      final faceHeight = (bottom - top).abs();
      final centerX = (left + right) / 2;
      final centerY = (top + bottom) / 2;

      // Agregar puntos en el perímetro (forma ovalada)
      final numBorderPoints = 48; // Puntos adicionales en el borde
      for (int i = 0; i < numBorderPoints; i++) {
        final angle = (i / numBorderPoints) * 2 * 3.14159;
        final x = centerX + (faceWidth / 2 * 1.1) * cos(angle);
        final y = centerY + (faceHeight / 2 * 1.1) * sin(angle);
        allPoints.add(Offset(x, y));
      }

      // Agregar puntos intermedios en la superficie
      final gridRows = 8;
      final gridCols = 6;
      for (int row = 1; row < gridRows; row++) {
        for (int col = 1; col < gridCols; col++) {
          final x = left + (faceWidth * col / gridCols);
          final y = top + (faceHeight * row / gridRows);

          // Solo agregar si está dentro del área facial (forma oval)
          final dx = (x - centerX) / (faceWidth / 2);
          final dy = (y - centerY) / (faceHeight / 2);
          if (dx * dx + dy * dy < 1.2) {
            // Dentro del óvalo
            allPoints.add(Offset(x, y));
          }
        }
      }

      // DIBUJAR MALLA con TODOS los puntos (originales + adicionales)
      final Paint meshLinePaint = Paint()
        ..color = meshColor.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.4;

      for (int i = 0; i < allPoints.length; i++) {
        final currentPoint = allPoints[i];
        final List<MapEntry<int, double>> nearbyPoints = [];

        for (int j = i + 1; j < allPoints.length; j++) {
          final distance = (currentPoint - allPoints[j]).distance;
          if (distance < 80) {
            nearbyPoints.add(MapEntry(j, distance));
          }
        }

        nearbyPoints.sort((a, b) => a.value.compareTo(b.value));

        for (int k = 0; k < nearbyPoints.length && k < 12; k++) {
          canvas.drawLine(
            currentPoint,
            allPoints[nearbyPoints[k].key],
            meshLinePaint,
          );
        }
      }

      // Dibujar contornos más gruesos encima de la malla
      final Paint contourPaint = Paint()
        ..color = meshColor.withOpacity(isScanning ? 0.5 : 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isScanning ? 1.5 : 1.0;

      for (final contourType in FaceMeshContourType.values) {
        final contour = mesh.contours[contourType];
        if (contour != null && contour.isNotEmpty) {
          final contourPoints = <Offset>[];
          for (final point in contour) {
            final x = translateX(
              point.x.toDouble(),
              size,
              imageSize,
              rotation,
              cameraLensDirection,
            );
            final y = translateY(
              point.y.toDouble(),
              size,
              imageSize,
              rotation,
              cameraLensDirection,
            );
            contourPoints.add(Offset(x, y));
          }

          if (contourPoints.length > 1) {
            final path = Path()
              ..moveTo(contourPoints.first.dx, contourPoints.first.dy);
            for (var i = 1; i < contourPoints.length; i++) {
              path.lineTo(contourPoints[i].dx, contourPoints[i].dy);
            }
            canvas.drawPath(path, contourPaint);
          }
        }
      }

      // Dibujar puntos principales
      final Paint pointPaint = Paint()
        ..color = meshColor
        ..style = PaintingStyle.fill;

      // Mostrar menos puntos para no saturar
      for (int i = 0; i < screenPoints.length; i += 8) {
        canvas.drawCircle(screenPoints[i], 1, pointPaint);
      }

      // Puntos clave más grandes
      final keyPoints = [10, 152, 234, 454, 1, 61, 291];
      final Paint keyPointPaint = Paint()
        ..color = scanComplete
            ? AppPalette.success
            : (isScanning ? AppPalette.accentLight : Colors.white)
        ..style = PaintingStyle.fill;

      for (final index in keyPoints) {
        if (index < screenPoints.length) {
          final point = screenPoints[index];

          if (isScanning) {
            canvas.drawCircle(
              point,
              6 * glowIntensity,
              Paint()
                ..color = keyPointPaint.color.withOpacity(0.4 * glowIntensity)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
            );
          }

          canvas.drawCircle(point, 2.5, keyPointPaint);

          canvas.drawCircle(
            point,
            4,
            Paint()
              ..color = keyPointPaint.color.withOpacity(0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
        }
      }

      // Bounding box (reutilizar variables ya calculadas arriba)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left, top, right, bottom),
          const Radius.circular(10),
        ),
        Paint()
          ..color = meshColor.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(FaceMeshPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.meshes != meshes;
  }
}
// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:camera/camera.dart';
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import '../../../../core/theme/app_theme.dart';

// class FaceScanPage extends StatefulWidget {
//   const FaceScanPage({super.key});

//   @override
//   State<FaceScanPage> createState() => _FaceScanPageState();
// }

// class _FaceScanPageState extends State<FaceScanPage>
//     with TickerProviderStateMixin {
//   // Cámara
//   CameraController? _controller;
//   List<CameraDescription> _cameras = [];
//   int _cameraIndex = -1;

//   // ML Kit
//   final FaceDetector _faceDetector = FaceDetector(
//     options: FaceDetectorOptions(enableContours: true, enableLandmarks: true),
//   );
//   bool _canProcess = true;
//   bool _isBusy = false;

//   // Estado
//   List<Face> _faces = [];
//   Size? _imageSize;
//   InputImageRotation? _imageRotation;
//   bool _isCameraReady = false;
//   bool _faceDetected = false;
//   bool _isScanning = false;
//   bool _scanComplete = false;
//   int _scanProgress = 0;
//   String _statusMessage = 'Iniciando cámara...';
//   int _stableFrames = 0;

//   // Animaciones
//   late AnimationController _pulseController;
//   late AnimationController _glowController;
//   late AnimationController _scanLineController;

//   final List<String> _scanMessages = [
//     'Rostro detectado...',
//     'Analizando estructura facial...',
//     'Mapeando puntos de referencia...',
//     'Procesando geometría...',
//     'Extrayendo características...',
//     'Verificando simetría...',
//     'Finalizando análisis...',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _initAnimations();
//     _initializeCamera();
//   }

//   void _initAnimations() {
//     _pulseController = AnimationController(
//       duration: const Duration(milliseconds: 1200),
//       vsync: this,
//     )..repeat(reverse: true);

//     _glowController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     )..repeat(reverse: true);

//     _scanLineController = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     )..repeat();
//   }

//   Future<void> _initializeCamera() async {
//     _cameras = await availableCameras();

//     // Buscar cámara frontal
//     for (int i = 0; i < _cameras.length; i++) {
//       if (_cameras[i].lensDirection == CameraLensDirection.front) {
//         _cameraIndex = i;
//         break;
//       }
//     }

//     if (_cameraIndex == -1 && _cameras.isNotEmpty) {
//       _cameraIndex = 0;
//     }

//     if (_cameraIndex >= 0) {
//       await _startCamera();
//     } else {
//       setState(() {
//         _statusMessage = 'No se encontró cámara';
//       });
//     }
//   }

//   Future<void> _startCamera() async {
//     final camera = _cameras[_cameraIndex];

//     _controller = CameraController(
//       camera,
//       ResolutionPreset.high,
//       enableAudio: false,
//       imageFormatGroup: Platform.isAndroid
//           ? ImageFormatGroup.nv21
//           : ImageFormatGroup.bgra8888,
//     );

//     try {
//       await _controller!.initialize();

//       if (mounted) {
//         setState(() {
//           _isCameraReady = true;
//           _statusMessage = 'Posiciona tu rostro en el marco';
//         });

//         // Iniciar stream de imágenes
//         await _controller!.startImageStream(_processCameraImage);
//       }
//     } catch (e) {
//       debugPrint('Error inicializando cámara: $e');
//       setState(() {
//         _statusMessage = 'Error: $e';
//       });
//     }
//   }

//   Future<void> _processCameraImage(CameraImage image) async {
//     if (!_canProcess || _isBusy || _scanComplete) return;
//     _isBusy = true;

//     final inputImage = _inputImageFromCameraImage(image);

//     if (inputImage == null) {
//       debugPrint('FaceScan: InputImage es null');
//       _isBusy = false;
//       return;
//     }

//     debugPrint(
//       'FaceScan: Procesando imagen ${image.width}x${image.height}, rotation: ${inputImage.metadata?.rotation}',
//     );

//     try {
//       final faces = await _faceDetector.processImage(inputImage);
//       debugPrint('FaceScan: Rostros detectados: ${faces.length}');

//       if (mounted) {
//         setState(() {
//           _faces = faces;
//           _imageSize = inputImage.metadata?.size;
//           _imageRotation = inputImage.metadata?.rotation;

//           if (faces.isNotEmpty) {
//             _stableFrames++;
//             if (!_faceDetected) {
//               _faceDetected = true;
//               _statusMessage = 'Rostro detectado - Mantén la posición';
//             }

//             // Esperar frames estables antes de escanear
//             if (_stableFrames > 15 && !_isScanning) {
//               _startScan();
//             }
//           } else {
//             _stableFrames = 0;
//             if (_faceDetected && !_isScanning) {
//               _faceDetected = false;
//               _statusMessage = 'Posiciona tu rostro en el marco';
//             }
//           }
//         });
//       }
//     } catch (e) {
//       debugPrint('FaceScan: Error procesando imagen: $e');
//     }

//     _isBusy = false;
//   }

//   InputImage? _inputImageFromCameraImage(CameraImage image) {
//     if (_controller == null) return null;

//     final camera = _cameras[_cameraIndex];
//     final rotation = InputImageRotationValue.fromRawValue(
//       camera.sensorOrientation,
//     );
//     if (rotation == null) {
//       debugPrint(
//         'FaceScan: Rotación no soportada: ${camera.sensorOrientation}',
//       );
//       return null;
//     }

//     // Determinar el formato correcto según la plataforma
//     InputImageFormat? format;
//     if (Platform.isAndroid) {
//       // En Android usamos NV21 que es el más compatible
//       format = InputImageFormat.nv21;
//     } else if (Platform.isIOS) {
//       format = InputImageFormat.bgra8888;
//     }

//     if (format == null) {
//       debugPrint('FaceScan: Formato de imagen no soportado');
//       return null;
//     }

//     final bytes = _concatenatePlanes(image.planes);

//     return InputImage.fromBytes(
//       bytes: bytes,
//       metadata: InputImageMetadata(
//         size: Size(image.width.toDouble(), image.height.toDouble()),
//         rotation: rotation,
//         format: format,
//         bytesPerRow: image.planes[0].bytesPerRow,
//       ),
//     );
//   }

//   Uint8List _concatenatePlanes(List<Plane> planes) {
//     final WriteBuffer allBytes = WriteBuffer();
//     for (final Plane plane in planes) {
//       allBytes.putUint8List(plane.bytes);
//     }
//     return allBytes.done().buffer.asUint8List();
//   }

//   void _startScan() {
//     setState(() {
//       _isScanning = true;
//       _scanProgress = 0;
//       _statusMessage = _scanMessages[0];
//     });

//     HapticFeedback.mediumImpact();

//     Timer.periodic(const Duration(milliseconds: 600), (timer) {
//       if (!mounted) {
//         timer.cancel();
//         return;
//       }

//       setState(() {
//         _scanProgress++;
//         if (_scanProgress < _scanMessages.length) {
//           _statusMessage = _scanMessages[_scanProgress];
//         }
//       });

//       if (_scanProgress >= _scanMessages.length) {
//         timer.cancel();
//         _completeScan();
//       }
//     });
//   }

//   void _completeScan() {
//     _canProcess = false;
//     HapticFeedback.heavyImpact();

//     setState(() {
//       _scanComplete = true;
//       _statusMessage = 'Escaneo Completado';
//     });

//     Future.delayed(const Duration(seconds: 2), () {
//       if (mounted) {
//         Navigator.pop(context, true);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _canProcess = false;
//     _controller?.dispose();
//     _faceDetector.close();
//     _pulseController.dispose();
//     _glowController.dispose();
//     _scanLineController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;
//     final size = MediaQuery.of(context).size;

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           // Cámara
//           if (_isCameraReady && _controller != null)
//             _buildCameraPreview()
//           else
//             const Center(child: CircularProgressIndicator(color: Colors.white)),

//           // Overlay
//           if (_isCameraReady)
//             AnimatedBuilder(
//               animation: _glowController,
//               builder: (context, _) {
//                 return CustomPaint(
//                   painter: _OverlayPainter(
//                     faceDetected: _faceDetected,
//                     isScanning: _isScanning,
//                     scanComplete: _scanComplete,
//                     glowValue: _glowController.value,
//                   ),
//                   size: Size.infinite,
//                 );
//               },
//             ),

//           // Puntos faciales
//           if (_faces.isNotEmpty &&
//               _imageSize != null &&
//               _imageRotation != null &&
//               _controller != null)
//             AnimatedBuilder(
//               animation: _glowController,
//               builder: (context, _) {
//                 return CustomPaint(
//                   painter: FaceDetectorPainter(
//                     faces: _faces,
//                     imageSize: _imageSize!,
//                     rotation: _imageRotation!,
//                     cameraLensDirection: _cameras[_cameraIndex].lensDirection,
//                     isScanning: _isScanning,
//                     scanComplete: _scanComplete,
//                     glowIntensity: _glowController.value,
//                   ),
//                   size: Size.infinite,
//                 );
//               },
//             ),

//           // Línea de escaneo
//           if (_isScanning && !_scanComplete)
//             AnimatedBuilder(
//               animation: _scanLineController,
//               builder: (context, _) {
//                 final top =
//                     size.height * 0.15 +
//                     (size.height * 0.5 * _scanLineController.value);
//                 return Positioned(
//                   top: top,
//                   left: size.width * 0.1,
//                   right: size.width * 0.1,
//                   child: Container(
//                     height: 4,
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [
//                           Colors.transparent,
//                           AppPalette.accent.withOpacity(0.7),
//                           AppPalette.accent,
//                           AppPalette.accent.withOpacity(0.7),
//                           Colors.transparent,
//                         ],
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: AppPalette.accent.withOpacity(0.8),
//                           blurRadius: 15,
//                           spreadRadius: 5,
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),

//           // UI
//           SafeArea(
//             child: Column(
//               children: [
//                 _buildHeader(),
//                 const Spacer(),
//                 _buildBottomPanel(theme, isDark),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCameraPreview() {
//     if (_controller == null || !_controller!.value.isInitialized) {
//       return const SizedBox.shrink();
//     }

//     final size = MediaQuery.of(context).size;
//     var scale = size.aspectRatio * _controller!.value.aspectRatio;
//     if (scale < 1) scale = 1 / scale;

//     return Transform.scale(
//       scale: scale,
//       child: Center(child: CameraPreview(_controller!)),
//     );
//   }

//   Widget _buildHeader() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Row(
//         children: [
//           IconButton(
//             onPressed: () => Navigator.pop(context),
//             icon: const Icon(Icons.close, color: Colors.white, size: 28),
//             style: IconButton.styleFrom(backgroundColor: Colors.black45),
//           ),
//           const Spacer(),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//             decoration: BoxDecoration(
//               color: _scanComplete
//                   ? AppPalette.success.withOpacity(0.9)
//                   : Colors.black54,
//               borderRadius: BorderRadius.circular(25),
//               border: Border.all(
//                 color: _scanComplete
//                     ? AppPalette.success
//                     : (_faceDetected ? AppPalette.accent : Colors.white30),
//                 width: 2,
//               ),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   _scanComplete
//                       ? Icons.check_circle
//                       : (_faceDetected
//                             ? Icons.face
//                             : Icons.face_retouching_natural),
//                   color: Colors.white,
//                   size: 22,
//                 ),
//                 const SizedBox(width: 10),
//                 Text(
//                   _scanComplete
//                       ? 'COMPLETADO'
//                       : (_isScanning ? 'ESCANEANDO...' : 'ESCANEO FACIAL'),
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const Spacer(),
//           const SizedBox(width: 56),
//         ],
//       ),
//     );
//   }

//   Widget _buildBottomPanel(ThemeData theme, bool isDark) {
//     return Container(
//       margin: const EdgeInsets.all(20),
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: (isDark ? AppPalette.gray900 : Colors.white).withOpacity(0.95),
//         borderRadius: BorderRadius.circular(28),
//         border: Border.all(
//           color: _scanComplete
//               ? AppPalette.success.withOpacity(0.5)
//               : (_faceDetected
//                     ? AppPalette.accent.withOpacity(0.3)
//                     : Colors.white24),
//           width: 2,
//         ),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Icono
//           ScaleTransition(
//             scale: Tween(begin: 0.95, end: 1.05).animate(_pulseController),
//             child: Container(
//               width: 80,
//               height: 80,
//               decoration: BoxDecoration(
//                 gradient: _scanComplete
//                     ? const LinearGradient(
//                         colors: [AppPalette.success, AppPalette.successLight],
//                       )
//                     : (_faceDetected
//                           ? AppPalette.accentGradient
//                           : LinearGradient(
//                               colors: [AppPalette.gray600, AppPalette.gray500],
//                             )),
//                 shape: BoxShape.circle,
//                 boxShadow: [
//                   BoxShadow(
//                     color:
//                         (_scanComplete
//                                 ? AppPalette.success
//                                 : (_faceDetected
//                                       ? AppPalette.accent
//                                       : AppPalette.gray500))
//                             .withOpacity(0.5),
//                     blurRadius: 25,
//                     spreadRadius: 5,
//                   ),
//                 ],
//               ),
//               child: Icon(
//                 _scanComplete
//                     ? Icons.check_rounded
//                     : (_faceDetected
//                           ? Icons.face
//                           : Icons.face_retouching_natural),
//                 color: Colors.white,
//                 size: 40,
//               ),
//             ),
//           ),

//           const SizedBox(height: 24),

//           Text(
//             _statusMessage,
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.bold,
//               color: _scanComplete
//                   ? AppPalette.success
//                   : theme.colorScheme.onSurface,
//             ),
//             textAlign: TextAlign.center,
//           ),

//           const SizedBox(height: 16),

//           if (_isScanning && !_scanComplete) ...[
//             ClipRRect(
//               borderRadius: BorderRadius.circular(6),
//               child: LinearProgressIndicator(
//                 value: _scanProgress / _scanMessages.length,
//                 minHeight: 10,
//                 backgroundColor: isDark
//                     ? AppPalette.gray700
//                     : AppPalette.gray200,
//                 valueColor: AlwaysStoppedAnimation<Color>(AppPalette.accent),
//               ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               '${((_scanProgress / _scanMessages.length) * 100).toInt()}%',
//               style: TextStyle(
//                 color: AppPalette.accent,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 24,
//               ),
//             ),
//           ] else if (_scanComplete) ...[
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               decoration: BoxDecoration(
//                 color: AppPalette.success.withOpacity(0.15),
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Icon(
//                     Icons.verified,
//                     color: AppPalette.success,
//                     size: 28,
//                   ),
//                   const SizedBox(width: 12),
//                   Text(
//                     'Análisis guardado',
//                     style: TextStyle(
//                       color: AppPalette.success,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ] else ...[
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   width: 12,
//                   height: 12,
//                   decoration: BoxDecoration(
//                     color: _faceDetected
//                         ? AppPalette.success
//                         : AppPalette.gray400,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   _faceDetected ? 'Iniciando escaneo...' : 'Buscando rostro...',
//                   style: theme.textTheme.bodyMedium?.copyWith(
//                     color: theme.colorScheme.onSurface.withOpacity(0.7),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// // Painter para el overlay
// class _OverlayPainter extends CustomPainter {
//   final bool faceDetected;
//   final bool isScanning;
//   final bool scanComplete;
//   final double glowValue;

//   _OverlayPainter({
//     required this.faceDetected,
//     required this.isScanning,
//     required this.scanComplete,
//     required this.glowValue,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height * 0.38);
//     final ovalWidth = size.width * 0.75;
//     final ovalHeight = size.height * 0.48;

//     // Fondo oscuro
//     canvas.drawRect(
//       Rect.fromLTWH(0, 0, size.width, size.height),
//       Paint()..color = Colors.black.withOpacity(0.7),
//     );

//     // Recorte oval
//     final ovalRect = Rect.fromCenter(
//       center: center,
//       width: ovalWidth,
//       height: ovalHeight,
//     );
//     canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
//     canvas.drawRect(
//       Rect.fromLTWH(0, 0, size.width, size.height),
//       Paint()..color = Colors.black.withOpacity(0.7),
//     );
//     canvas.drawOval(ovalRect, Paint()..blendMode = BlendMode.clear);
//     canvas.restore();

//     // Borde
//     Color borderColor = scanComplete
//         ? AppPalette.success
//         : (isScanning
//               ? AppPalette.accent
//               : (faceDetected
//                     ? AppPalette.accent.withOpacity(0.7)
//                     : Colors.white38));

//     canvas.drawOval(
//       ovalRect,
//       Paint()
//         ..color = borderColor
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = scanComplete ? 4 : 3,
//     );

//     // Glow
//     if (faceDetected || isScanning) {
//       canvas.drawOval(
//         ovalRect,
//         Paint()
//           ..color = borderColor.withOpacity(0.2 * glowValue)
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = 15
//           ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(covariant _OverlayPainter old) => true;
// }

// // Funciones de traducción de coordenadas (del ejemplo oficial de ML Kit)
// double translateX(
//   double x,
//   Size canvasSize,
//   Size imageSize,
//   InputImageRotation rotation,
//   CameraLensDirection cameraLensDirection,
// ) {
//   switch (rotation) {
//     case InputImageRotation.rotation90deg:
//       return x * canvasSize.width / imageSize.height;
//     case InputImageRotation.rotation270deg:
//       return canvasSize.width - x * canvasSize.width / imageSize.height;
//     case InputImageRotation.rotation0deg:
//     case InputImageRotation.rotation180deg:
//       switch (cameraLensDirection) {
//         case CameraLensDirection.back:
//           return x * canvasSize.width / imageSize.width;
//         case CameraLensDirection.front:
//           return canvasSize.width - x * canvasSize.width / imageSize.width;
//         case CameraLensDirection.external:
//           return x * canvasSize.width / imageSize.width;
//       }
//   }
// }

// double translateY(
//   double y,
//   Size canvasSize,
//   Size imageSize,
//   InputImageRotation rotation,
//   CameraLensDirection cameraLensDirection,
// ) {
//   switch (rotation) {
//     case InputImageRotation.rotation90deg:
//     case InputImageRotation.rotation270deg:
//       return y * canvasSize.height / imageSize.width;
//     case InputImageRotation.rotation0deg:
//     case InputImageRotation.rotation180deg:
//       return y * canvasSize.height / imageSize.height;
//   }
// }

// Painter para los puntos faciales (basado en el ejemplo oficial)
// class FaceDetectorPainter extends CustomPainter {
//   final List<Face> faces;
//   final Size imageSize;
//   final InputImageRotation rotation;
//   final CameraLensDirection cameraLensDirection;
//   final bool isScanning;
//   final bool scanComplete;
//   final double glowIntensity;

//   FaceDetectorPainter({
//     required this.faces,
//     required this.imageSize,
//     required this.rotation,
//     required this.cameraLensDirection,
//     required this.isScanning,
//     required this.scanComplete,
//     required this.glowIntensity,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final Paint contourPaint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = isScanning ? 2.0 : 1.0
//       ..color = scanComplete
//           ? AppPalette.success
//           : (isScanning ? AppPalette.accent : Colors.cyanAccent);

//     final Paint landmarkPaint = Paint()
//       ..style = PaintingStyle.fill
//       ..strokeWidth = 1.0
//       ..color = AppPalette.accentLight;

//     for (final Face face in faces) {
//       // Dibujar bounding box
//       final left = translateX(
//         face.boundingBox.left,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );
//       final top = translateY(
//         face.boundingBox.top,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );
//       final right = translateX(
//         face.boundingBox.right,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );
//       final bottom = translateY(
//         face.boundingBox.bottom,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );

//       // Bounding box con esquinas redondeadas
//       final rect = Rect.fromLTRB(left, top, right, bottom);
//       canvas.drawRRect(
//         RRect.fromRectAndRadius(rect, const Radius.circular(10)),
//         Paint()
//           ..color = contourPaint.color.withOpacity(0.3)
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = 2,
//       );

//       // Dibujar contornos
//       void paintContour(FaceContourType type) {
//         final contour = face.contours[type];
//         if (contour?.points != null) {
//           final points = <Offset>[];
//           for (final point in contour!.points) {
//             final x = translateX(
//               point.x.toDouble(),
//               size,
//               imageSize,
//               rotation,
//               cameraLensDirection,
//             );
//             final y = translateY(
//               point.y.toDouble(),
//               size,
//               imageSize,
//               rotation,
//               cameraLensDirection,
//             );
//             points.add(Offset(x, y));
//           }

//           // Dibujar líneas conectando los puntos
//           if (points.length > 1) {
//             final path = Path()..moveTo(points.first.dx, points.first.dy);
//             for (var i = 1; i < points.length; i++) {
//               path.lineTo(points[i].dx, points[i].dy);
//             }
//             canvas.drawPath(path, contourPaint);
//           }

//           // Dibujar puntos
//           for (final point in points) {
//             canvas.drawCircle(
//               point,
//               isScanning ? 3 : 2,
//               contourPaint..style = PaintingStyle.fill,
//             );

//             // Glow en modo escaneo
//             if (isScanning) {
//               canvas.drawCircle(
//                 point,
//                 6 * glowIntensity,
//                 Paint()
//                   ..color = contourPaint.color.withOpacity(0.3 * glowIntensity)
//                   ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
//               );
//             }
//           }
//           contourPaint.style = PaintingStyle.stroke;
//         }
//       }

//       // Dibujar landmarks
//       void paintLandmark(FaceLandmarkType type) {
//         final landmark = face.landmarks[type];
//         if (landmark?.position != null) {
//           final x = translateX(
//             landmark!.position.x.toDouble(),
//             size,
//             imageSize,
//             rotation,
//             cameraLensDirection,
//           );
//           final y = translateY(
//             landmark.position.y.toDouble(),
//             size,
//             imageSize,
//             rotation,
//             cameraLensDirection,
//           );

//           final point = Offset(x, y);

//           // Glow
//           if (isScanning) {
//             canvas.drawCircle(
//               point,
//               12 * glowIntensity,
//               Paint()
//                 ..color = landmarkPaint.color.withOpacity(0.4 * glowIntensity)
//                 ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
//             );
//           }

//           // Punto principal
//           canvas.drawCircle(point, isScanning ? 5 : 3, landmarkPaint);

//           // Círculo exterior
//           canvas.drawCircle(
//             point,
//             isScanning ? 8 : 5,
//             Paint()
//               ..color = landmarkPaint.color.withOpacity(0.5)
//               ..style = PaintingStyle.stroke
//               ..strokeWidth = 1.5,
//           );
//         }
//       }

//       // Pintar todos los contornos
//       for (final type in FaceContourType.values) {
//         paintContour(type);
//       }

//       // Pintar todos los landmarks
//       for (final type in FaceLandmarkType.values) {
//         paintLandmark(type);
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(FaceDetectorPainter oldDelegate) {
//     return oldDelegate.imageSize != imageSize || oldDelegate.faces != faces;
//   }
// }

// ESTILO PROFESIONAL/MÉDICO
// Colores azules técnicos, precisión, sin efectos exagerados
// class FaceDetectorPainter extends CustomPainter {
//   final List<Face> faces;
//   final Size imageSize;
//   final InputImageRotation rotation;
//   final CameraLensDirection cameraLensDirection;
//   final bool isScanning;
//   final bool scanComplete;
//   final double glowIntensity;

//   FaceDetectorPainter({
//     required this.faces,
//     required this.imageSize,
//     required this.rotation,
//     required this.cameraLensDirection,
//     required this.isScanning,
//     required this.scanComplete,
//     required this.glowIntensity,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     // Paleta profesional
//     final Color primaryBlue = const Color(0xFF2196F3);
//     final Color accentBlue = const Color(0xFF03A9F4);
//     final Color successGreen = const Color(0xFF4CAF50);

//     final Paint contourPaint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.8
//       ..color = scanComplete
//           ? successGreen
//           : (isScanning ? accentBlue : primaryBlue);

//     final Paint landmarkPaint = Paint()
//       ..style = PaintingStyle.fill
//       ..strokeWidth = 1.0
//       ..color = const Color(0xFFFF9800); // Naranja para landmarks

//     for (final Face face in faces) {
//       // Dibujar bounding box
//       final left = translateX(
//         face.boundingBox.left,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );
//       final top = translateY(
//         face.boundingBox.top,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );
//       final right = translateX(
//         face.boundingBox.right,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );
//       final bottom = translateY(
//         face.boundingBox.bottom,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );

//       final rect = Rect.fromLTRB(left, top, right, bottom);

//       // Bounding box con estilo técnico
//       canvas.drawRRect(
//         RRect.fromRectAndRadius(rect, const Radius.circular(8)),
//         Paint()
//           ..color = contourPaint.color.withOpacity(0.3)
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = 2,
//       );

//       // Marcas de medición en las esquinas
//       final markLength = 15.0;
//       final markPaint = Paint()
//         ..color = contourPaint.color
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 2
//         ..strokeCap = StrokeCap.square;

//       // Esquinas con marcas en L
//       canvas.drawLine(
//         Offset(left, top),
//         Offset(left + markLength, top),
//         markPaint,
//       );
//       canvas.drawLine(
//         Offset(left, top),
//         Offset(left, top + markLength),
//         markPaint,
//       );

//       canvas.drawLine(
//         Offset(right, top),
//         Offset(right - markLength, top),
//         markPaint,
//       );
//       canvas.drawLine(
//         Offset(right, top),
//         Offset(right, top + markLength),
//         markPaint,
//       );

//       canvas.drawLine(
//         Offset(left, bottom),
//         Offset(left + markLength, bottom),
//         markPaint,
//       );
//       canvas.drawLine(
//         Offset(left, bottom),
//         Offset(left, bottom - markLength),
//         markPaint,
//       );

//       canvas.drawLine(
//         Offset(right, bottom),
//         Offset(right - markLength, bottom),
//         markPaint,
//       );
//       canvas.drawLine(
//         Offset(right, bottom),
//         Offset(right, bottom - markLength),
//         markPaint,
//       );

//       // Dibujar contornos
//       void paintContour(FaceContourType type) {
//         final contour = face.contours[type];
//         if (contour?.points != null) {
//           final points = <Offset>[];
//           for (final point in contour!.points) {
//             final x = translateX(
//               point.x.toDouble(),
//               size,
//               imageSize,
//               rotation,
//               cameraLensDirection,
//             );
//             final y = translateY(
//               point.y.toDouble(),
//               size,
//               imageSize,
//               rotation,
//               cameraLensDirection,
//             );
//             points.add(Offset(x, y));
//           }

//           // Dibujar líneas conectando los puntos
//           if (points.length > 1) {
//             final path = Path()..moveTo(points.first.dx, points.first.dy);
//             for (var i = 1; i < points.length; i++) {
//               path.lineTo(points[i].dx, points[i].dy);
//             }
//             canvas.drawPath(path, contourPaint);
//           }

//           // Dibujar puntos técnicos
//           for (final point in points) {
//             // Glow sutil solo en escaneo
//             if (isScanning) {
//               canvas.drawCircle(
//                 point,
//                 6 * glowIntensity,
//                 Paint()
//                   ..color = contourPaint.color.withOpacity(0.3 * glowIntensity)
//                   ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
//               );
//             }

//             // Punto con borde (estilo técnico)
//             canvas.drawCircle(
//               point,
//               2.5,
//               Paint()
//                 ..color = Colors.white
//                 ..style = PaintingStyle.fill,
//             );

//             canvas.drawCircle(
//               point,
//               2.5,
//               Paint()
//                 ..color = contourPaint.color
//                 ..style = PaintingStyle.stroke
//                 ..strokeWidth = 1.5,
//             );
//           }
//         }
//       }

//       // Dibujar landmarks
//       void paintLandmark(FaceLandmarkType type) {
//         final landmark = face.landmarks[type];
//         if (landmark?.position != null) {
//           final x = translateX(
//             landmark!.position.x.toDouble(),
//             size,
//             imageSize,
//             rotation,
//             cameraLensDirection,
//           );
//           final y = translateY(
//             landmark.position.y.toDouble(),
//             size,
//             imageSize,
//             rotation,
//             cameraLensDirection,
//           );

//           final point = Offset(x, y);

//           // Glow moderado en escaneo
//           if (isScanning) {
//             canvas.drawCircle(
//               point,
//               10 * glowIntensity,
//               Paint()
//                 ..color = landmarkPaint.color.withOpacity(0.3 * glowIntensity)
//                 ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
//             );
//           }

//           // Cruz de medición en el landmark
//           final crossSize = 6.0;
//           final crossPaint = Paint()
//             ..color = landmarkPaint.color
//             ..style = PaintingStyle.stroke
//             ..strokeWidth = 1.5
//             ..strokeCap = StrokeCap.round;

//           canvas.drawLine(
//             Offset(point.dx - crossSize, point.dy),
//             Offset(point.dx + crossSize, point.dy),
//             crossPaint,
//           );
//           canvas.drawLine(
//             Offset(point.dx, point.dy - crossSize),
//             Offset(point.dx, point.dy + crossSize),
//             crossPaint,
//           );

//           // Punto central
//           canvas.drawCircle(point, 4, landmarkPaint);

//           // Centro blanco
//           canvas.drawCircle(
//             point,
//             2,
//             Paint()
//               ..color = Colors.white
//               ..style = PaintingStyle.fill,
//           );

//           // Anillo técnico
//           canvas.drawCircle(
//             point,
//             7,
//             Paint()
//               ..color = landmarkPaint.color.withOpacity(0.6)
//               ..style = PaintingStyle.stroke
//               ..strokeWidth = 1.5,
//           );
//         }
//       }

//       // Pintar todos los contornos
//       for (final type in FaceContourType.values) {
//         paintContour(type);
//       }

//       // Pintar todos los landmarks
//       for (final type in FaceLandmarkType.values) {
//         paintLandmark(type);
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(FaceDetectorPainter oldDelegate) {
//     return oldDelegate.imageSize != imageSize || oldDelegate.faces != faces;
//   }
// }

// ESTILO NEÓN
// Colores vibrantes, efectos de glow extremos, estética cyberpunk
// class FaceDetectorPainter extends CustomPainter {
//   final List<Face> faces;
//   final Size imageSize;
//   final InputImageRotation rotation;
//   final CameraLensDirection cameraLensDirection;
//   final bool isScanning;
//   final bool scanComplete;
//   final double glowIntensity;

//   FaceDetectorPainter({
//     required this.faces,
//     required this.imageSize,
//     required this.rotation,
//     required this.cameraLensDirection,
//     required this.isScanning,
//     required this.scanComplete,
//     required this.glowIntensity,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     // Colores neón personalizados
//     final Color neonPink = const Color(0xFFFF006E);
//     final Color neonPurple = const Color(0xFF8338EC);
//     final Color neonCyan = const Color(0xFF00F5FF);
//     final Color neonGreen = const Color(0xFF39FF14);

//     final Paint contourPaint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth =
//           3.0 // Líneas muy gruesas
//       ..color = scanComplete ? neonGreen : (isScanning ? neonPink : neonCyan);

//     final Paint landmarkPaint = Paint()
//       ..style = PaintingStyle.fill
//       ..strokeWidth = 1.0
//       ..color = neonPurple;

//     for (final Face face in faces) {
//       // Dibujar bounding box
//       final left = translateX(
//         face.boundingBox.left,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );
//       final top = translateY(
//         face.boundingBox.top,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );
//       final right = translateX(
//         face.boundingBox.right,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );
//       final bottom = translateY(
//         face.boundingBox.bottom,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );

//       // Bounding box con triple glow
//       final rect = Rect.fromLTRB(left, top, right, bottom);

//       // Glow exterior (más grande)
//       canvas.drawRRect(
//         RRect.fromRectAndRadius(rect, const Radius.circular(15)),
//         Paint()
//           ..color = contourPaint.color.withOpacity(0.2)
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = 20
//           ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
//       );

//       // Glow medio
//       canvas.drawRRect(
//         RRect.fromRectAndRadius(rect, const Radius.circular(15)),
//         Paint()
//           ..color = contourPaint.color.withOpacity(0.4)
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = 10
//           ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
//       );

//       // Bounding box principal brillante
//       canvas.drawRRect(
//         RRect.fromRectAndRadius(rect, const Radius.circular(15)),
//         Paint()
//           ..color = contourPaint.color
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = 3,
//       );

//       // Dibujar contornos
//       void paintContour(FaceContourType type) {
//         final contour = face.contours[type];
//         if (contour?.points != null) {
//           final points = <Offset>[];
//           for (final point in contour!.points) {
//             final x = translateX(
//               point.x.toDouble(),
//               size,
//               imageSize,
//               rotation,
//               cameraLensDirection,
//             );
//             final y = translateY(
//               point.y.toDouble(),
//               size,
//               imageSize,
//               rotation,
//               cameraLensDirection,
//             );
//             points.add(Offset(x, y));
//           }

//           // Dibujar líneas con efecto neón
//           if (points.length > 1) {
//             final path = Path()..moveTo(points.first.dx, points.first.dy);
//             for (var i = 1; i < points.length; i++) {
//               path.lineTo(points[i].dx, points[i].dy);
//             }

//             // Triple capa de glow
//             canvas.drawPath(
//               path,
//               Paint()
//                 ..color = contourPaint.color.withOpacity(0.3)
//                 ..style = PaintingStyle.stroke
//                 ..strokeWidth = 12
//                 ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
//             );

//             canvas.drawPath(
//               path,
//               Paint()
//                 ..color = contourPaint.color.withOpacity(0.6)
//                 ..style = PaintingStyle.stroke
//                 ..strokeWidth = 6
//                 ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
//             );

//             canvas.drawPath(path, contourPaint);
//           }

//           // Dibujar puntos neón
//           for (final point in points) {
//             // Glow extremo pulsante
//             canvas.drawCircle(
//               point,
//               15 * glowIntensity,
//               Paint()
//                 ..color = contourPaint.color.withOpacity(0.5 * glowIntensity)
//                 ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
//             );

//             // Glow medio
//             canvas.drawCircle(
//               point,
//               8 * glowIntensity,
//               Paint()
//                 ..color = contourPaint.color.withOpacity(0.7 * glowIntensity)
//                 ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
//             );

//             // Punto brillante
//             canvas.drawCircle(
//               point,
//               4.5,
//               contourPaint..style = PaintingStyle.fill,
//             );

//             // Centro ultra brillante
//             canvas.drawCircle(
//               point,
//               2,
//               Paint()
//                 ..color = Colors.white
//                 ..style = PaintingStyle.fill,
//             );
//           }
//           contourPaint.style = PaintingStyle.stroke;
//         }
//       }

//       // Dibujar landmarks
//       void paintLandmark(FaceLandmarkType type) {
//         final landmark = face.landmarks[type];
//         if (landmark?.position != null) {
//           final x = translateX(
//             landmark!.position.x.toDouble(),
//             size,
//             imageSize,
//             rotation,
//             cameraLensDirection,
//           );
//           final y = translateY(
//             landmark.position.y.toDouble(),
//             size,
//             imageSize,
//             rotation,
//             cameraLensDirection,
//           );

//           final point = Offset(x, y);

//           // Glow masivo pulsante
//           canvas.drawCircle(
//             point,
//             20 * glowIntensity,
//             Paint()
//               ..color = landmarkPaint.color.withOpacity(0.4 * glowIntensity)
//               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
//           );

//           canvas.drawCircle(
//             point,
//             12 * glowIntensity,
//             Paint()
//               ..color = landmarkPaint.color.withOpacity(0.6 * glowIntensity)
//               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
//           );

//           // Punto principal grande
//           canvas.drawCircle(point, 7, landmarkPaint);

//           // Centro blanco brillante
//           canvas.drawCircle(
//             point,
//             3,
//             Paint()
//               ..color = Colors.white
//               ..style = PaintingStyle.fill,
//           );

//           // Anillo exterior neón
//           canvas.drawCircle(
//             point,
//             12,
//             Paint()
//               ..color = landmarkPaint.color
//               ..style = PaintingStyle.stroke
//               ..strokeWidth = 3,
//           );

//           // Anillo medio
//           canvas.drawCircle(
//             point,
//             9,
//             Paint()
//               ..color = neonCyan
//               ..style = PaintingStyle.stroke
//               ..strokeWidth = 1.5,
//           );
//         }
//       }

//       // Pintar todos los contornos
//       for (final type in FaceContourType.values) {
//         paintContour(type);
//       }

//       // Pintar todos los landmarks
//       for (final type in FaceLandmarkType.values) {
//         paintLandmark(type);
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(FaceDetectorPainter oldDelegate) {
//     return oldDelegate.imageSize != imageSize || oldDelegate.faces != faces;
//   }
// }

// ESTILO SUTIL
// Solo landmarks principales, sin contornos, muy limpio
// class FaceDetectorPainter extends CustomPainter {
//   final List<Face> faces;
//   final Size imageSize;
//   final InputImageRotation rotation;
//   final CameraLensDirection cameraLensDirection;
//   final bool isScanning;
//   final bool scanComplete;
//   final double glowIntensity;

//   FaceDetectorPainter({
//     required this.faces,
//     required this.imageSize,
//     required this.rotation,
//     required this.cameraLensDirection,
//     required this.isScanning,
//     required this.scanComplete,
//     required this.glowIntensity,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final Paint contourPaint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.5
//       ..color = scanComplete
//           ? AppPalette.success.withOpacity(0.6)
//           : AppPalette.accent.withOpacity(0.4);

//     final Paint landmarkPaint = Paint()
//       ..style = PaintingStyle.fill
//       ..strokeWidth = 1.0
//       ..color = scanComplete
//           ? AppPalette.success
//           : (isScanning ? AppPalette.accent : Colors.white70);

//     for (final Face face in faces) {
//       // Dibujar bounding box muy sutil
//       final left = translateX(
//         face.boundingBox.left,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );
//       final top = translateY(
//         face.boundingBox.top,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );
//       final right = translateX(
//         face.boundingBox.right,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );
//       final bottom = translateY(
//         face.boundingBox.bottom,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );

//       // Solo esquinas del bounding box (estilo moderno)
//       final rect = Rect.fromLTRB(left, top, right, bottom);
//       final cornerLength = 20.0;
//       final cornerPaint = Paint()
//         ..color = contourPaint.color
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 2
//         ..strokeCap = StrokeCap.round;

//       // Esquina superior izquierda
//       canvas.drawLine(
//         Offset(left, top),
//         Offset(left + cornerLength, top),
//         cornerPaint,
//       );
//       canvas.drawLine(
//         Offset(left, top),
//         Offset(left, top + cornerLength),
//         cornerPaint,
//       );

//       // Esquina superior derecha
//       canvas.drawLine(
//         Offset(right, top),
//         Offset(right - cornerLength, top),
//         cornerPaint,
//       );
//       canvas.drawLine(
//         Offset(right, top),
//         Offset(right, top + cornerLength),
//         cornerPaint,
//       );

//       // Esquina inferior izquierda
//       canvas.drawLine(
//         Offset(left, bottom),
//         Offset(left + cornerLength, bottom),
//         cornerPaint,
//       );
//       canvas.drawLine(
//         Offset(left, bottom),
//         Offset(left, bottom - cornerLength),
//         cornerPaint,
//       );

//       // Esquina inferior derecha
//       canvas.drawLine(
//         Offset(right, bottom),
//         Offset(right - cornerLength, bottom),
//         cornerPaint,
//       );
//       canvas.drawLine(
//         Offset(right, bottom),
//         Offset(right, bottom - cornerLength),
//         cornerPaint,
//       );

//       // NO dibujar contornos - solo landmarks
//       // (Comentado intencionalmente para estilo limpio)

//       // Dibujar solo landmarks principales
//       void paintLandmark(FaceLandmarkType type) {
//         final landmark = face.landmarks[type];
//         if (landmark?.position != null) {
//           final x = translateX(
//             landmark!.position.x.toDouble(),
//             size,
//             imageSize,
//             rotation,
//             cameraLensDirection,
//           );
//           final y = translateY(
//             landmark.position.y.toDouble(),
//             size,
//             imageSize,
//             rotation,
//             cameraLensDirection,
//           );

//           final point = Offset(x, y);

//           // Glow muy sutil solo en escaneo
//           if (isScanning) {
//             canvas.drawCircle(
//               point,
//               8 * glowIntensity,
//               Paint()
//                 ..color = landmarkPaint.color.withOpacity(0.2 * glowIntensity)
//                 ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
//             );
//           }

//           // Punto principal pequeño
//           canvas.drawCircle(point, 3, landmarkPaint);

//           // Sin anillo exterior para mantener limpieza
//         }
//       }

//       // Pintar SOLO landmarks (sin contornos)
//       for (final type in FaceLandmarkType.values) {
//         paintLandmark(type);
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(FaceDetectorPainter oldDelegate) {
//     return oldDelegate.imageSize != imageSize || oldDelegate.faces != faces;
//   }
// }

// ESTILO MINIMALISTA
// Líneas sutiles, puntos pequeños, sin efectos exagerados
// class FaceDetectorPainter extends CustomPainter {
//   final List<Face> faces;
//   final Size imageSize;
//   final InputImageRotation rotation;
//   final CameraLensDirection cameraLensDirection;
//   final bool isScanning;
//   final bool scanComplete;
//   final double glowIntensity;

//   FaceDetectorPainter({
//     required this.faces,
//     required this.imageSize,
//     required this.rotation,
//     required this.cameraLensDirection,
//     required this.isScanning,
//     required this.scanComplete,
//     required this.glowIntensity,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final Paint contourPaint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth =
//           1.0 // Líneas delgadas
//       ..color = scanComplete
//           ? AppPalette.success.withOpacity(0.8)
//           : Colors.white.withOpacity(0.6); // Blanco sutil

//     final Paint landmarkPaint = Paint()
//       ..style = PaintingStyle.fill
//       ..strokeWidth = 1.0
//       ..color = Colors.white.withOpacity(0.9);

//     for (final Face face in faces) {
//       // Dibujar bounding box
//       final left = translateX(
//         face.boundingBox.left,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );
//       final top = translateY(
//         face.boundingBox.top,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );
//       final right = translateX(
//         face.boundingBox.right,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );
//       final bottom = translateY(
//         face.boundingBox.bottom,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );

//       // Bounding box minimalista
//       final rect = Rect.fromLTRB(left, top, right, bottom);
//       canvas.drawRRect(
//         RRect.fromRectAndRadius(rect, const Radius.circular(8)),
//         Paint()
//           ..color = contourPaint.color.withOpacity(0.2)
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = 1.5,
//       );

//       // Dibujar contornos
//       void paintContour(FaceContourType type) {
//         final contour = face.contours[type];
//         if (contour?.points != null) {
//           final points = <Offset>[];
//           for (final point in contour!.points) {
//             final x = translateX(
//               point.x.toDouble(),
//               size,
//               imageSize,
//               rotation,
//               cameraLensDirection,
//             );
//             final y = translateY(
//               point.y.toDouble(),
//               size,
//               imageSize,
//               rotation,
//               cameraLensDirection,
//             );
//             points.add(Offset(x, y));
//           }

//           // Dibujar líneas conectando los puntos
//           if (points.length > 1) {
//             final path = Path()..moveTo(points.first.dx, points.first.dy);
//             for (var i = 1; i < points.length; i++) {
//               path.lineTo(points[i].dx, points[i].dy);
//             }
//             canvas.drawPath(path, contourPaint);
//           }

//           // Dibujar puntos pequeños
//           for (final point in points) {
//             canvas.drawCircle(
//               point,
//               1.5, // Puntos muy pequeños
//               contourPaint..style = PaintingStyle.fill,
//             );
//           }
//           contourPaint.style = PaintingStyle.stroke;
//         }
//       }

//       // Dibujar landmarks
//       void paintLandmark(FaceLandmarkType type) {
//         final landmark = face.landmarks[type];
//         if (landmark?.position != null) {
//           final x = translateX(
//             landmark!.position.x.toDouble(),
//             size,
//             imageSize,
//             rotation,
//             cameraLensDirection,
//           );
//           final y = translateY(
//             landmark.position.y.toDouble(),
//             size,
//             imageSize,
//             rotation,
//             cameraLensDirection,
//           );

//           final point = Offset(x, y);

//           // Punto principal pequeño
//           canvas.drawCircle(point, 2.5, landmarkPaint);

//           // Anillo sutil
//           canvas.drawCircle(
//             point,
//             4.5,
//             Paint()
//               ..color = landmarkPaint.color.withOpacity(0.3)
//               ..style = PaintingStyle.stroke
//               ..strokeWidth = 1.0,
//           );
//         }
//       }

//       // Pintar todos los contornos
//       for (final type in FaceContourType.values) {
//         paintContour(type);
//       }

//       // Pintar todos los landmarks
//       for (final type in FaceLandmarkType.values) {
//         paintLandmark(type);
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(FaceDetectorPainter oldDelegate) {
//     return oldDelegate.imageSize != imageSize || oldDelegate.faces != faces;
//   }
// }

// ESTILO FUTURISTA
// Líneas gruesas, colores cyan/neón, efectos glow intensos
// class FaceDetectorPainter extends CustomPainter {
//   final List<Face> faces;
//   final Size imageSize;
//   final InputImageRotation rotation;
//   final CameraLensDirection cameraLensDirection;
//   final bool isScanning;
//   final bool scanComplete;
//   final double glowIntensity;

//   FaceDetectorPainter({
//     required this.faces,
//     required this.imageSize,
//     required this.rotation,
//     required this.cameraLensDirection,
//     required this.isScanning,
//     required this.scanComplete,
//     required this.glowIntensity,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final Paint contourPaint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth =
//           2.5 // Líneas gruesas
//       ..color = scanComplete
//           ? const Color(0xFF00FF88) // Verde neón
//           : (isScanning
//                 ? const Color(0xFF00FFFF) // Cyan brillante
//                 : const Color(0xFF00D9FF)); // Azul neón

//     final Paint landmarkPaint = Paint()
//       ..style = PaintingStyle.fill
//       ..strokeWidth = 1.0
//       ..color = const Color(0xFFFF00FF); // Magenta neón

//     for (final Face face in faces) {
//       // Dibujar bounding box
//       final left = translateX(
//         face.boundingBox.left,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );
//       final top = translateY(
//         face.boundingBox.top,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );
//       final right = translateX(
//         face.boundingBox.right,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );
//       final bottom = translateY(
//         face.boundingBox.bottom,
//         size,
//         imageSize,
//         rotation,
//         cameraLensDirection,
//       );

//       // Bounding box con glow
//       final rect = Rect.fromLTRB(left, top, right, bottom);

//       // Glow exterior del bounding box
//       canvas.drawRRect(
//         RRect.fromRectAndRadius(rect, const Radius.circular(12)),
//         Paint()
//           ..color = contourPaint.color.withOpacity(0.3)
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = 8
//           ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
//       );

//       // Bounding box principal
//       canvas.drawRRect(
//         RRect.fromRectAndRadius(rect, const Radius.circular(12)),
//         Paint()
//           ..color = contourPaint.color.withOpacity(0.5)
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = 3,
//       );

//       // Dibujar contornos
//       void paintContour(FaceContourType type) {
//         final contour = face.contours[type];
//         if (contour?.points != null) {
//           final points = <Offset>[];
//           for (final point in contour!.points) {
//             final x = translateX(
//               point.x.toDouble(),
//               size,
//               imageSize,
//               rotation,
//               cameraLensDirection,
//             );
//             final y = translateY(
//               point.y.toDouble(),
//               size,
//               imageSize,
//               rotation,
//               cameraLensDirection,
//             );
//             points.add(Offset(x, y));
//           }

//           // Dibujar líneas conectando los puntos
//           if (points.length > 1) {
//             final path = Path()..moveTo(points.first.dx, points.first.dy);
//             for (var i = 1; i < points.length; i++) {
//               path.lineTo(points[i].dx, points[i].dy);
//             }

//             // Glow de la línea
//             canvas.drawPath(
//               path,
//               Paint()
//                 ..color = contourPaint.color.withOpacity(0.4)
//                 ..style = PaintingStyle.stroke
//                 ..strokeWidth = 6
//                 ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
//             );

//             // Línea principal
//             canvas.drawPath(path, contourPaint);
//           }

//           // Dibujar puntos
//           for (final point in points) {
//             // Glow del punto
//             canvas.drawCircle(
//               point,
//               10 * glowIntensity,
//               Paint()
//                 ..color = contourPaint.color.withOpacity(0.6 * glowIntensity)
//                 ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
//             );

//             // Punto principal
//             canvas.drawCircle(
//               point,
//               4, // Puntos grandes
//               contourPaint..style = PaintingStyle.fill,
//             );
//           }
//           contourPaint.style = PaintingStyle.stroke;
//         }
//       }

//       // Dibujar landmarks
//       void paintLandmark(FaceLandmarkType type) {
//         final landmark = face.landmarks[type];
//         if (landmark?.position != null) {
//           final x = translateX(
//             landmark!.position.x.toDouble(),
//             size,
//             imageSize,
//             rotation,
//             cameraLensDirection,
//           );
//           final y = translateY(
//             landmark.position.y.toDouble(),
//             size,
//             imageSize,
//             rotation,
//             cameraLensDirection,
//           );

//           final point = Offset(x, y);

//           // Glow intenso
//           canvas.drawCircle(
//             point,
//             15 * glowIntensity,
//             Paint()
//               ..color = landmarkPaint.color.withOpacity(0.5 * glowIntensity)
//               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
//           );

//           // Punto principal grande
//           canvas.drawCircle(point, 6, landmarkPaint);

//           // Anillo exterior brillante
//           canvas.drawCircle(
//             point,
//             10,
//             Paint()
//               ..color = landmarkPaint.color.withOpacity(0.8)
//               ..style = PaintingStyle.stroke
//               ..strokeWidth = 2.5,
//           );
//         }
//       }

//       // Pintar todos los contornos
//       for (final type in FaceContourType.values) {
//         paintContour(type);
//       }

//       // Pintar todos los landmarks
//       for (final type in FaceLandmarkType.values) {
//         paintLandmark(type);
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(FaceDetectorPainter oldDelegate) {
//     return oldDelegate.imageSize != imageSize || oldDelegate.faces != faces;
//   }
// }
