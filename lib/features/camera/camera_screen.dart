import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';

enum ImageFilterMode { none, grayscale, invert }

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final String deviceId = "cam001";
  final String baseUrl = "https://esp32cam-cloud-relay.onrender.com";

  final storage = const FlutterSecureStorage();
  StreamController<Uint8List>? _frameController;
  HttpClient? _ioClient;

  bool _streaming = false;
  String _status = "Idle";
  List<int> _buffer = [];
  ImageFilterMode _filterMode = ImageFilterMode.none;

  static const int _minJpegSize = 800;

  @override
  void initState() {
    super.initState();
    _frameController = StreamController<Uint8List>.broadcast();
    _ioClient = HttpClient();
  }

  @override
  void dispose() {
    _stopStream();
    _frameController?.close();
    _ioClient?.close(force: true);
    super.dispose();
  }

  Future<void> saveToken(String token) async =>
      await storage.write(key: "session_token", value: token);
  Future<String?> readToken() async => await storage.read(key: "session_token");
  Future<void> deleteToken() async =>
      await storage.delete(key: "session_token");

  Future<bool> requestOtp() async {
    final url = Uri.parse("$baseUrl/api/device/$deviceId/request_start");
    try {
      final resp = await http.post(url);
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        return j["ok"] == true;
      }
    } catch (e) {
      debugPrint("requestOtp error: $e");
    }
    return false;
  }

  Future<String?> verifyOtp(String code) async {
    final url = Uri.parse("$baseUrl/api/device/$deviceId/verify");
    try {
      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"code": code}),
      );
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        return j["token"];
      } else {
        debugPrint("verify failed: ${resp.statusCode} ${resp.body}");
      }
    } catch (e) {
      debugPrint("verify error: $e");
    }
    return null;
  }

  int indexOfBytes(List<int> data, List<int> pattern, [int start = 0]) {
    for (int i = start; i <= data.length - pattern.length; i++) {
      bool ok = true;
      for (int j = 0; j < pattern.length; j++) {
        if (data[i + j] != pattern[j]) {
          ok = false;
          break;
        }
      }
      if (ok) return i;
    }
    return -1;
  }

  Future<bool> _validateJpeg(Uint8List bytes) async {
    try {
      if (bytes.length < _minJpegSize) return false;
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image.width > 0 && frame.image.height > 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> _extractFramesAndAdd(List<int> chunk) async {
    _buffer.addAll(chunk);

    while (true) {
      int start = indexOfBytes(_buffer, [0xFF, 0xD8]);
      if (start < 0) {
        if (_buffer.length > 2 * 1024 * 1024) {
          _buffer = _buffer.sublist(_buffer.length - 512);
        }
        break;
      }

      int end = indexOfBytes(_buffer, [0xFF, 0xD9], start + 2);
      if (end < 0) {
        if (_buffer.length > 2 * 1024 * 1024) {
          _buffer = _buffer.sublist(start);
        }
        break;
      }

      final frameBytes = _buffer.sublist(start, end + 2);
      _buffer = _buffer.sublist(end + 2);

      try {
        final u = Uint8List.fromList(frameBytes);
        final valid = await _validateJpeg(u);
        if (valid) {
          _frameController?.add(u);
        } else {
          debugPrint("Dropped invalid frame (size=${u.length})");
        }
      } catch (e) {
        debugPrint("Frame processing error: $e");
      }
    }
  }

  Future<void> _startStreamWithToken(String token) async {
    _stopStream();
    if (!mounted) return;

    setState(() {
      _streaming = true;
      _status = "Connecting...";
    });
    _buffer = [];

    try {
      final url = Uri.parse("$baseUrl/stream/$deviceId");
      final req = await _ioClient!.getUrl(url);
      req.headers.set(HttpHeaders.authorizationHeader, "Bearer $token");
      req.headers.set(HttpHeaders.acceptHeader, "multipart/x-mixed-replace");

      final resp = await req.close();
      if (!mounted) return;

      if (resp.statusCode != 200) {
        setState(() {
          _streaming = false;
          _status = "Stream failed (${resp.statusCode})";
        });
        await resp.drain();
        return;
      }

      setState(() => _status = "Streaming");

      await for (List<int> chunk in resp) {
        if (!_streaming) break;
        await _extractFramesAndAdd(chunk);
      }
    } catch (e) {
      debugPrint("Stream connection error: $e");
      if (mounted) {
        setState(() => _status = "Error: $e");
      }
    } finally {
      _streaming = false;
      if (mounted) {
        setState(() {
          if (_status == "Streaming") _status = "Stopped";
        });
      }
    }
  }

  void _stopStream() {
    _streaming = false;
    if (mounted) setState(() => _status = "Stopped");
  }

  Future<void> openStreamFlow() async {
    final otpRequested = await showDialog<bool>(
      context: context,
      builder: (ctx) => _RequestOtpDialog(onRequestOtp: requestOtp),
    );
    if (otpRequested != true) return;
    if (!mounted) return;

    final code = await showDialog<String?>(
      context: context,
      builder: (ctx) => _EnterOtpDialog(),
    );
    if (code == null || code.isEmpty) return;

    final token = await verifyOtp(code);
    if (token == null) {
      if (mounted) setState(() => _status = "Verify failed");
      return;
    }

    await saveToken(token);
    await _startStreamWithToken(token);
  }

  Future<void> closeAndRevoke() async {
    final token = await readToken();
    if (token != null) {
      try {
        final url = Uri.parse("$baseUrl/api/device/$deviceId/revoke");
        final resp = await http.post(
          url,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );
        debugPrint("revoke resp: ${resp.statusCode} ${resp.body}");
      } catch (e) {
        debugPrint("revoke error: $e");
      }
    }
    await deleteToken();
    _stopStream();
    if (mounted) setState(() => _status = "Closed & token revoked");
  }

  ColorFilter getColorFilter(ImageFilterMode mode) {
    switch (mode) {
      case ImageFilterMode.grayscale:
        return const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ImageFilterMode.invert:
        return const ColorFilter.matrix([
          -1, 0, 0, 0, 255,
          0, -1, 0, 0, 255,
          0, 0, -1, 0, 255,
          0, 0, 0, 1, 0,
        ]);
      default:
        return const ColorFilter.mode(Colors.transparent, BlendMode.multiply);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("📷 Camera"),
          actions: [
            PopupMenuButton<ImageFilterMode>(
              icon: const Icon(Icons.filter),
              tooltip: "Image Filters",
              onSelected: (m) => setState(() => _filterMode = m),
              itemBuilder: (_) => [
                _buildFilterItem(ImageFilterMode.none, "No Filter", Icons.filter_none),
                _buildFilterItem(ImageFilterMode.grayscale, "Grayscale", Icons.filter_b_and_w),
                _buildFilterItem(ImageFilterMode.invert, "Invert", Icons.invert_colors),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Logout",
              onPressed: () async {
                await deleteToken();
                if (mounted) setState(() => _status = "Logged out");
              },
            ),
          ],
        ),
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: _buildVideoFrame(),
                  ),
                ),
              ),
              _buildStatusBar(),
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<ImageFilterMode> _buildFilterItem(
    ImageFilterMode mode,
    String label,
    IconData icon,
  ) {
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label),
          if (_filterMode == mode) ...[
            const Spacer(),
            const Icon(Icons.check, size: 18),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoFrame() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(16),
          ),
          child: StreamBuilder<Uint8List>(
            stream: _frameController?.stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _streaming ? Icons.videocam : Icons.videocam_off,
                        size: 64,
                        color: Colors.white30,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _status,
                        style: const TextStyle(color: Colors.white60),
                      ),
                      if (_streaming) ...[
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(),
                      ],
                    ],
                  ),
                );
              }
              return ColorFiltered(
                colorFilter: getColorFilter(_filterMode),
                child: Image.memory(
                  snapshot.data!,
                  gaplessPlayback: true,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, error, stack) {
                    debugPrint("Image.memory error: $error");
                    return const Center(
                      child: Text(
                        "Invalid image",
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    Color statusColor;
    IconData statusIcon;

    if (_streaming && _status == "Streaming") {
      statusColor = AppTheme.severityLow;
      statusIcon = Icons.fiber_manual_record;
    } else if (_streaming) {
      statusColor = AppTheme.warningColor;
      statusIcon = Icons.pending;
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.circle_outlined;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(statusIcon, color: statusColor, size: 12),
          const SizedBox(width: 8),
          Text(
            _status,
            style: TextStyle(color: statusColor),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _streaming ? null : openStreamFlow,
              icon: const Icon(Icons.play_arrow),
              label: const Text("Open Stream"),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _streaming ? closeAndRevoke : null,
              icon: const Icon(Icons.stop),
              label: const Text("Close Stream"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// OTP Dialogs - preserved exactly from original
// ============================================================================
class _RequestOtpDialog extends StatefulWidget {
  final Future<bool> Function() onRequestOtp;
  const _RequestOtpDialog({required this.onRequestOtp});

  @override
  State<_RequestOtpDialog> createState() => _RequestOtpDialogState();
}

class _RequestOtpDialogState extends State<_RequestOtpDialog> {
  String msg = "Send OTP to your registered email.";
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.email_outlined),
          SizedBox(width: 12),
          Text("Request OTP"),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(msg),
          if (loading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: loading
              ? null
              : () async {
                  setState(() {
                    loading = true;
                    msg = "Sending OTP...";
                  });
                  final ok = await widget.onRequestOtp();
                  if (!context.mounted) return;
                  if (ok) {
                    Navigator.pop(context, true);
                  } else {
                    setState(() {
                      loading = false;
                      msg = "Failed to send OTP. Please try again.";
                    });
                  }
                },
          child: const Text("Request OTP"),
        ),
      ],
    );
  }
}

class _EnterOtpDialog extends StatelessWidget {
  final controller = TextEditingController();
  _EnterOtpDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock_outline),
          SizedBox(width: 12),
          Text("Enter OTP"),
        ],
      ),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: "OTP Code",
          hintText: "Enter the code from your email",
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.pin),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text("Verify"),
        ),
      ],
    );
  }
}
