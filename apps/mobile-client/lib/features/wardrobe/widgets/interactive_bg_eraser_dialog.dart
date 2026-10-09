import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/local_bg_removal_service.dart';
import '../../../core/theme/app_theme.dart';

enum EraserMode { erase, restore }

class TouchPoint {
  final Offset point;
  final double size;
  final EraserMode mode;

  TouchPoint({required this.point, required this.size, required this.mode});
}

class InteractiveBgEraserDialog extends StatefulWidget {
  final String imagePath;

  const InteractiveBgEraserDialog({super.key, required this.imagePath});

  @override
  State<InteractiveBgEraserDialog> createState() =>
      _InteractiveBgEraserDialogState();
}

class _InteractiveBgEraserDialogState
    extends State<InteractiveBgEraserDialog> {
  late String _currentPath;
  ui.Image? _decodedImage;
  bool _isLoading = true;
  bool _isAutoProcessing = false;

  EraserMode _activeMode = EraserMode.erase;
  double _brushSize = 30.0;
  final List<List<TouchPoint>> _strokes = [];
  List<TouchPoint> _currentStroke = [];

  @override
  void initState() {
    super.initState();
    _currentPath = widget.imagePath;
    _loadImage();
  }

  Future<String?> _ensureLocalPath(String path) async {
    if (path.isEmpty) return null;
    if (!path.startsWith('http://') && !path.startsWith('https://')) {
      return path;
    }
    try {
      final response = await http.get(Uri.parse(path));
      if (response.statusCode == 200) {
        final tempFile = File(
            '${Directory.systemTemp.path}/eraser_temp_${DateTime.now().millisecondsSinceEpoch}.png');
        await tempFile.writeAsBytes(response.bodyBytes);
        return tempFile.path;
      }
    } catch (e) {
      debugPrint('[EraserDialog] Error fetching HTTP image: $e');
    }
    return null;
  }

  Future<void> _loadImage() async {
    setState(() => _isLoading = true);
    try {
      Uint8List? bytes;
      if (_currentPath.startsWith('http://') ||
          _currentPath.startsWith('https://')) {
        final response = await http.get(Uri.parse(_currentPath));
        if (response.statusCode == 200) {
          bytes = response.bodyBytes;
          final local = await _ensureLocalPath(_currentPath);
          if (local != null) _currentPath = local;
        }
      } else {
        final file = File(_currentPath);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        }
      }

      if (bytes != null) {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        if (mounted) {
          setState(() {
            _decodedImage = frame.image;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('[EraserDialog] Error loading image: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _runAutoCutout() async {
    setState(() => _isAutoProcessing = true);
    final localPath = await _ensureLocalPath(_currentPath);
    if (localPath != null) {
      final result = await LocalBgRemovalService.processImage(localPath);
      if (result != null && mounted) {
        _currentPath = result;
        _strokes.clear();
        await _loadImage();
      }
    }
    if (mounted) {
      setState(() => _isAutoProcessing = false);
    }
  }

  Future<void> _saveAndFinish() async {
    if (_decodedImage == null) {
      Navigator.of(context).pop(_currentPath);
      return;
    }

    try {
      setState(() => _isLoading = true);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final size = Size(
        _decodedImage!.width.toDouble(),
        _decodedImage!.height.toDouble(),
      );

      // Draw original image
      canvas.drawImage(_decodedImage!, Offset.zero, Paint());

      // Apply eraser strokes
      final erasePaint = Paint()
        ..blendMode = ui.BlendMode.clear
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      for (final stroke in _strokes) {
        for (final pt in stroke) {
          if (pt.mode == EraserMode.erase) {
            erasePaint.strokeWidth = pt.size;
            canvas.drawCircle(pt.point, pt.size / 2, erasePaint);
          }
        }
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.width.toInt(), size.height.toInt());
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

      if (pngBytes != null) {
        final outPath = widget.imagePath
            .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '_erased.png');
        final outFile = File(outPath);
        await outFile.writeAsBytes(pngBytes.buffer.asUint8List());
        if (mounted) {
          Navigator.of(context).pop(outFile.path);
          return;
        }
      }
    } catch (e) {
      debugPrint('[EraserDialog] Save error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (mounted) {
      Navigator.of(context).pop(_currentPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: Text(
          'Chỉnh Sửa & Xóa Phông Nền',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveAndFinish,
            icon: const Icon(Icons.check_rounded, color: Color(0xFF10B981)),
            label: Text(
              'Lưu Ảnh',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Toolbar (Auto Cutout, Undo, Clear)
            Container(
              color: const Color(0xFF1F2937),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isAutoProcessing ? null : _runAutoCutout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryLight,
                      side: BorderSide(color: AppTheme.primaryLight),
                    ),
                    icon: _isAutoProcessing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_fix_high_rounded, size: 18),
                    label: const Text('AI Tách Tự Động'),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.undo_rounded, color: Colors.white70),
                    tooltip: 'Hoàn tác',
                    onPressed: _strokes.isEmpty
                        ? null
                        : () {
                            setState(() {
                              _strokes.removeLast();
                            });
                          },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent),
                    tooltip: 'Xóa toàn bộ',
                    onPressed: () {
                      setState(() {
                        _strokes.clear();
                      });
                    },
                  ),
                ],
              ),
            ),

            // Canvas Workspace
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryLight),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onPanStart: (details) {
                            final RenderBox box =
                                context.findRenderObject() as RenderBox;
                            final localPos =
                                box.globalToLocal(details.globalPosition);
                            _currentStroke = [
                              TouchPoint(
                                point: localPos,
                                size: _brushSize,
                                mode: _activeMode,
                              )
                            ];
                            setState(() {
                              _strokes.add(_currentStroke);
                            });
                          },
                          onPanUpdate: (details) {
                            final RenderBox box =
                                context.findRenderObject() as RenderBox;
                            final localPos =
                                box.globalToLocal(details.globalPosition);
                            _currentStroke.add(TouchPoint(
                              point: localPos,
                              size: _brushSize,
                              mode: _activeMode,
                            ));
                            (context as Element).markNeedsBuild();
                          },
                          child: RepaintBoundary(
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: const Color(0xFF111827),
                              child: CustomPaint(
                                painter: _EraserPainter(
                                  image: _decodedImage,
                                  strokes: _strokes,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Controls (Brush mode & Size)
            Container(
              color: const Color(0xFF1F2937),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mode Selector (Eraser vs Restore)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Row(
                          children: [
                            Icon(Icons.cleaning_services_rounded, size: 16),
                            SizedBox(width: 6),
                            Text('Xóa phông nền'),
                          ],
                        ),
                        selected: _activeMode == EraserMode.erase,
                        selectedColor: AppTheme.primaryLight,
                        onSelected: (val) {
                          if (val) setState(() => _activeMode = EraserMode.erase);
                        },
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Row(
                          children: [
                            Icon(Icons.brush_rounded, size: 16),
                            SizedBox(width: 6),
                            Text('Khôi phục'),
                          ],
                        ),
                        selected: _activeMode == EraserMode.restore,
                        selectedColor: AppTheme.primaryLight,
                        onSelected: (val) {
                          if (val) setState(() => _activeMode = EraserMode.restore);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Brush Size Slider
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 12, color: Colors.white70),
                      Expanded(
                        child: Slider(
                          value: _brushSize,
                          min: 10,
                          max: 60,
                          activeColor: AppTheme.primaryLight,
                          inactiveColor: Colors.white24,
                          onChanged: (val) => setState(() => _brushSize = val),
                        ),
                      ),
                      const Icon(Icons.circle, size: 28, color: Colors.white70),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EraserPainter extends CustomPainter {
  final ui.Image? image;
  final List<List<TouchPoint>> strokes;

  _EraserPainter({required this.image, required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;

    final srcRect =
        Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble());
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Optimized background grid pattern (drawn using grid path)
    final gridPaint = Paint()..color = const Color(0xFF374151);
    const step = 24.0;
    final gridPath = Path();
    for (double i = 0; i < size.width; i += step) {
      for (double j = 0; j < size.height; j += step) {
        if (((i / step).floor() + (j / step).floor()) % 2 == 0) {
          gridPath.addRect(Rect.fromLTWH(i, j, step, step));
        }
      }
    }
    canvas.drawPath(gridPath, gridPaint);

    // Draw main image fitted to dstRect
    canvas.drawImageRect(image!, srcRect, dstRect, Paint());

    // Draw user strokes
    final erasePaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in strokes) {
      for (final pt in stroke) {
        erasePaint.strokeWidth = pt.size;
        canvas.drawCircle(pt.point, pt.size / 2, erasePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EraserPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.strokes != strokes;
  }
}
