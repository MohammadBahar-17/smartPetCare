// main.dart (محدّث) - includes MJPEG validation + safe display + filters
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const SmartPetCareApp());
}

class SmartPetCareApp extends StatelessWidget {
  const SmartPetCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartPetCare Camera',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const CameraStreamPage(),
    );
  }
}

enum ImageFilterMode { none, grayscale, invert }

class CameraStreamPage extends StatefulWidget {
  const CameraStreamPage({super.key});

  @override
  State<CameraStreamPage> createState() => _CameraStreamPageState();
}

class _CameraStreamPageState extends State<CameraStreamPage> {
  final String deviceId = "cam001";
  final String baseUrl = "https://esp32cam-cloud-relay.onrender.com";

  final storage = const FlutterSecureStorage();
  StreamController<Uint8List>? _frameController;
  HttpClient? _ioClient;
  bool _streaming = false;
  String _status = "Idle";
  List<int> _buffer = [];
  ImageFilterMode _filterMode = ImageFilterMode.none;

  // minimal acceptable jpeg size (avoid tiny junk)
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

  // storage helpers
  Future<void> saveToken(String token) async =>
      await storage.write(key: "session_token", value: token);
  Future<String?> readToken() async => await storage.read(key: "session_token");
  Future<void> deleteToken() async =>
      await storage.delete(key: "session_token");

  // API calls (same as before)
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

  // ========================
  // MJPEG parsing & validation
  // ========================

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

  // Validate JPEG by trying to instantiate image codec (async)
  Future<bool> _validateJpeg(Uint8List bytes) async {
    try {
      // quick length check
      if (bytes.length < _minJpegSize) return false;
      // try decode - this will throw on invalid data
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      // optionally check dimensions: frame.image.width > 0 etc
      // dispose of image by letting Dart GC handle it — there's no explicit dispose here
      return frame.image.width > 0 && frame.image.height > 0;
    } catch (e) {
      // invalid image
      return false;
    }
  }

  // Add frame after validation (non-blocking but ensures only valid bytes are pushed)
  Future<void> _extractFramesAndAdd(List<int> chunk) async {
    _buffer.addAll(chunk);

    // loop to extract all complete JPEGs currently in buffer
    while (true) {
      int start = indexOfBytes(_buffer, [0xFF, 0xD8]);
      if (start < 0) {
        // no SOI yet -> keep buffer (but prevent unbounded growth)
        if (_buffer.length > 2 * 1024 * 1024) {
          // 2MB safety cap
          _buffer = _buffer.sublist(
            _buffer.length - 512,
          ); // keep last small tail
        }
        break;
      }
      int end = indexOfBytes(_buffer, [0xFF, 0xD9], start + 2);
      if (end < 0) {
        // incomplete, wait for more data
        // but if buffer too big drop early bytes (safety)
        if (_buffer.length > 2 * 1024 * 1024) {
          _buffer = _buffer.sublist(start); // keep from start
        }
        break;
      }

      final frameBytes = _buffer.sublist(start, end + 2);
      // cut buffer
      _buffer = _buffer.sublist(end + 2);

      try {
        final u = Uint8List.fromList(frameBytes);
        final valid = await _validateJpeg(u);
        if (valid) {
          // only add valid frames (non-blocking)
          _frameController?.add(u);
        } else {
          // ignore invalid frame
          debugPrint("Dropped invalid frame (size=${u.length})");
        }
      } catch (e) {
        debugPrint("Frame processing error: $e");
      }
    }
  }

  // start stream: opens HTTP connection and feeds chunks to parser
  Future<void> _startStreamWithToken(String token) async {
    _stopStream();
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

      if (mounted) {
        setState(() {
          _status = "Streaming";
        });
      }

      // stream chunks
      await for (List<int> chunk in resp) {
        if (!_streaming) break;
        try {
          // parse & validate frames (async but sequential)
          await _extractFramesAndAdd(chunk);
        } catch (e) {
          debugPrint("Error handling chunk: $e");
        }
      }
    } catch (e) {
      debugPrint("Stream connection error: $e");
      if (mounted) {
        setState(() {
          _status = "Error: $e";
        });
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
    setState(() {
      _status = "Stopped";
    });
  }

  // ========================
  // OTP & UI flows
  // ========================

  Future<void> openStreamFlow() async {
    final otpRequested = await showDialog<bool>(
      context: context,
      builder: (ctx) => RequestOtpDialog(onRequestOtp: requestOtp),
    );
    if (otpRequested != true) return;

    if (!mounted) return;

    final code = await showDialog<String?>(
      context: context,
      builder: (ctx) => EnterOtpDialog(),
    );
    if (code == null || code.isEmpty) return;

    final token = await verifyOtp(code);
    if (token == null) {
      setState(() {
        _status = "Verify failed";
      });
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
    if (mounted) {
      setState(() {
        _status = "Closed & token revoked";
      });
    }
  }

  // filter helpers
  ColorFilter getColorFilter(ImageFilterMode mode) {
    switch (mode) {
      case ImageFilterMode.grayscale:
        return const ColorFilter.matrix([
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      case ImageFilterMode.invert:
        return const ColorFilter.matrix([
          -1,
          0,
          0,
          0,
          255,
          0,
          -1,
          0,
          0,
          255,
          0,
          0,
          -1,
          0,
          255,
          0,
          0,
          0,
          1,
          0,
        ]);
      default:
        return const ColorFilter.mode(Colors.transparent, BlendMode.multiply);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SmartPetCare Camera"),
        actions: [
          PopupMenuButton<ImageFilterMode>(
            onSelected: (m) => setState(() => _filterMode = m),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: ImageFilterMode.none,
                child: Text("No Filter"),
              ),
              const PopupMenuItem(
                value: ImageFilterMode.grayscale,
                child: Text("Grayscale"),
              ),
              const PopupMenuItem(
                value: ImageFilterMode.invert,
                child: Text("Invert"),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await deleteToken();
              setState(() {
                _status = "Logged out";
              });
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          SizedBox(
            width: 360,
            height: 260,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: StreamBuilder<Uint8List>(
                stream: _frameController?.stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: Text(
                        _status,
                        style: const TextStyle(color: Colors.white60),
                      ),
                    );
                  }
                  final imageBytes = snapshot.data!;
                  // Image.memory with errorBuilder as final fallback
                  return ColorFiltered(
                    colorFilter: getColorFilter(_filterMode),
                    child: Image.memory(
                      imageBytes,
                      gaplessPlayback: true,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, error, stack) {
                        // If display fails unexpectedly, show placeholder but do not crash
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
          const SizedBox(height: 16),
          Text("Status: $_status", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _streaming ? null : openStreamFlow,
                child: const Text("Open Stream"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _streaming ? closeAndRevoke : null,
                child: const Text("Close Stream"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// OTP dialogs (same as before)
class RequestOtpDialog extends StatefulWidget {
  final Future<bool> Function() onRequestOtp;
  const RequestOtpDialog({super.key, required this.onRequestOtp});
  @override
  State<RequestOtpDialog> createState() => _RequestOtpDialogState();
}

class _RequestOtpDialogState extends State<RequestOtpDialog> {
  String msg = "Send OTP to your registered email.";
  bool loading = false;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Request OTP"),
      content: Text(msg),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: loading
              ? null
              : () async {
                  setState(() {
                    loading = true;
                    msg = "Sending...";
                  });
                  final ok = await widget.onRequestOtp();
                  if (!context.mounted) return;
                  if (ok) {
                    Navigator.pop(context, true);
                  } else {
                    setState(() {
                      loading = false;
                      msg = "Failed to send OTP";
                    });
                  }
                },
          child: const Text("Request OTP"),
        ),
      ],
    );
  }
}

class EnterOtpDialog extends StatelessWidget {
  final controller = TextEditingController();
  EnterOtpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Enter OTP"),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(hintText: "Enter code"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text("Verify"),
        ),
      ],
    );
  }
}
