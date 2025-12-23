import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final db = FirebaseDatabase.instance.ref();

  List<Map<String, dynamic>> commandLogs = [];
  List<Map<String, dynamic>> alertLogs = [];

  StreamSubscription<DatabaseEvent>? _subCommands;
  StreamSubscription<DatabaseEvent>? _subAlerts;

  @override
  void initState() {
    super.initState();

    // Last 20 commands
    _subCommands = db.child("logs/commands").limitToLast(20).onValue.listen((
      event,
    ) {
      final v = event.snapshot.value;
      if (v is Map) {
        final items = v.entries.map((e) {
          final m = Map<String, dynamic>.from(e.value as Map);
          m["_id"] = e.key;
          return m;
        }).toList();

        items.sort(
          (a, b) => ((b["ts"] ?? 0) as int).compareTo((a["ts"] ?? 0) as int),
        );

        if (!mounted) return;
        setState(() => commandLogs = items);
      } else {
        if (!mounted) return;
        setState(() => commandLogs = []);
      }
    });

    // Last 20 alerts
    _subAlerts = db.child("logs/alerts").limitToLast(20).onValue.listen((
      event,
    ) {
      final v = event.snapshot.value;
      if (v is Map) {
        final items = v.entries.map((e) {
          final m = Map<String, dynamic>.from(e.value as Map);
          m["_id"] = e.key;
          return m;
        }).toList();

        items.sort(
          (a, b) => ((b["ts"] ?? 0) as int).compareTo((a["ts"] ?? 0) as int),
        );

        if (!mounted) return;
        setState(() => alertLogs = items);
      } else {
        if (!mounted) return;
        setState(() => alertLogs = []);
      }
    });
  }

  @override
  void dispose() {
    _subCommands?.cancel();
    _subAlerts?.cancel();
    super.dispose();
  }

  String formatTs(dynamic ts) {
    if (ts is int) {
      final d = DateTime.fromMillisecondsSinceEpoch(ts);
      return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} "
          "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
    }
    return "-";
  }

  Widget logTile(Map<String, dynamic> m) {
    final type = (m["type"] ?? "unknown").toString();
    final ts = formatTs(m["ts"]);
    final extra = Map<String, dynamic>.from(m)
      ..remove("type")
      ..remove("ts")
      ..remove("_id");

    return Card(
      child: ListTile(
        title: Text(type),
        subtitle: Text("$ts\n${extra.isEmpty ? "" : extra.toString()}"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Logs / History")),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text(
            "Commands",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (commandLogs.isEmpty) const Text("No command logs yet."),
          ...commandLogs.map(logTile),
          const SizedBox(height: 20),
          const Text(
            "Alerts",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (alertLogs.isEmpty) const Text("No alert logs yet."),
          ...alertLogs.map(logTile),
        ],
      ),
    );
  }
}
