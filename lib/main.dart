import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

void main() {
  runApp(SmartPetCareApp());
}

class SmartPetCareApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartPetCare Camera',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: CameraStreamPage(),
    );
  }
}

class CameraStreamPage extends StatelessWidget {
  // ID الكاميرا
  final String deviceId = "cam001";

  // رابط السيرفر تبعك على Render
  final String baseUrl = "https://esp32cam-cloud-relay.onrender.com";

  @override
  Widget build(BuildContext context) {
    final streamUrl = "$baseUrl/stream/$deviceId";

    return Scaffold(
      appBar: AppBar(
        title: Text("SmartPetCare Live Camera"),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Live Stream",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),

            // ====== MJPEG STREAM ======
            Container(
              width: 350,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade900,
              ),
              child: Mjpeg(
                isLive: true,
                stream: streamUrl,
                fit: BoxFit.contain,
                error: (context, error, stack) {
                  return Center(
                    child: Text(
                      "Stream Error!",
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 20),

            Text(
              "Source: $streamUrl",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
