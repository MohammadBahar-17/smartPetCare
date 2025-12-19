import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  final String url =
      "https://us-central1-smartcatcare.cloudfunctions.net/askAi";

  Future<Map<String, dynamic>> ask(String question) async {
    final resp = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"question": question}),
    );

    if (resp.statusCode != 200) {
      throw Exception("AI error ${resp.statusCode}: ${resp.body}");
    }

    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}
