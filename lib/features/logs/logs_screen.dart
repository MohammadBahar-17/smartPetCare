import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/firebase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> with SingleTickerProviderStateMixin {
  final _firebase = FirebaseService();

  List<Map<String, dynamic>> commandLogs = [];
  List<Map<String, dynamic>> alertLogs = [];

  StreamSubscription<DatabaseEvent>? _subCommands;
  StreamSubscription<DatabaseEvent>? _subAlerts;

  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initListeners();
  }

  @override
  void dispose() {
    _subCommands?.cancel();
    _subAlerts?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _initListeners() {
    // Last 20 commands
    _subCommands = _firebase.commandLogsStream().listen((event) {
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
        setState(() {
          commandLogs = items;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          commandLogs = [];
          _isLoading = false;
        });
      }
    });

    // Last 20 alerts
    _subAlerts = _firebase.alertLogsStream().listen((event) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📋 Logs & History"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.terminal),
              text: "Commands (${commandLogs.length})",
            ),
            Tab(
              icon: const Icon(Icons.warning_amber),
              text: "Alerts (${alertLogs.length})",
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: "Loading logs...")
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLogsList(commandLogs, isCommand: true),
                _buildLogsList(alertLogs, isCommand: false),
              ],
            ),
    );
  }

  Widget _buildLogsList(List<Map<String, dynamic>> logs, {required bool isCommand}) {
    if (logs.isEmpty) {
      return EmptyState(
        icon: isCommand ? Icons.terminal : Icons.warning_amber,
        title: isCommand ? "No commands yet" : "No alerts yet",
        subtitle: isCommand
            ? "Commands will appear here when actions are triggered"
            : "Alerts will appear here when thresholds are reached",
      );
    }

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          return _buildLogCard(logs[index], isCommand: isCommand);
        },
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log, {required bool isCommand}) {
    final type = (log["type"] ?? "unknown").toString();
    final ts = log["ts"];
    final timeStr = Helpers.formatTimestamp(ts);

    final extra = Map<String, dynamic>.from(log)
      ..remove("type")
      ..remove("ts")
      ..remove("_id");

    // Get icon and color based on type
    IconData icon;
    Color color;

    if (isCommand) {
      switch (type.toLowerCase()) {
        case 'feed_cat':
          icon = Icons.pets;
          color = Colors.orange;
          break;
        case 'feed_dog':
          icon = Icons.pets;
          color = Colors.brown;
          break;
        case 'drain':
          icon = Icons.water;
          color = Colors.blue;
          break;
        case 'entertainment':
          icon = Icons.toys;
          color = Colors.purple;
          break;
        default:
          icon = Icons.touch_app;
          color = Colors.grey;
      }
    } else {
      switch (type.toLowerCase()) {
        case 'low_food':
          icon = Icons.fastfood;
          color = AppTheme.severityHigh;
          break;
        case 'low_water':
          icon = Icons.water_drop;
          color = AppTheme.severityMedium;
          break;
        case 'drain_full':
          icon = Icons.warning;
          color = AppTheme.severityHigh;
          break;
        default:
          icon = Icons.notification_important;
          color = AppTheme.warningColor;
      }
    }

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatType(type),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isCommand
                            ? Colors.blue.withValues(alpha: 0.1)
                            : AppTheme.severityMedium.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isCommand ? "CMD" : "ALERT",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isCommand ? Colors.blue : AppTheme.severityMedium,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
                if (extra.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: extra.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Text(
                                "${e.key}: ",
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              Expanded(
                                child: Text(
                                  "${e.value}",
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}
