import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

/// Centralized Firebase service for database operations
/// NOTE: All database paths must remain unchanged for backend compatibility
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  DatabaseReference get db => _db;

  // ============ FEEDING ============

  /// Listen to food sensors
  Stream<DatabaseEvent> foodSensorsStream() {
    return _db.child("feeding/sensors").onValue;
  }

  /// Get meals as Map
  Future<Map<String, dynamic>> getMeals() async {
    final snap = await _db.child("feeding/meals").get();
    if (snap.value is Map) {
      return Map<String, dynamic>.from(snap.value as Map);
    }
    return {};
  }

  /// Add a new meal
  Future<void> addMeal({
    required String animal,
    required int hour,
    required int minute,
    required int amount,
    required String days,
  }) async {
    final id = _db.child("feeding/meals").push().key;
    await _db.child("feeding/meals/$id").set({
      "animal": animal,
      "hour": hour,
      "minute": minute,
      "amount": amount,
      "days": days,
    });
  }

  /// Delete a meal
  Future<void> deleteMeal(String id) {
    return _db.child("feeding/meals/$id").remove();
  }

  /// Feed cat command
  Future<void> feedCat() {
    return _db.child("feeding/commands/feed_cat").set(1);
  }

  /// Feed dog command
  Future<void> feedDog() {
    return _db.child("feeding/commands/feed_dog").set(1);
  }

  // ============ PROFILES ============

  /// Get all pet profiles as Map
  Future<Map<String, dynamic>> getProfiles() async {
    final snap = await _db.child("profiles").get();
    if (snap.value is Map) {
      return Map<String, dynamic>.from(snap.value as Map);
    }
    return {};
  }

  /// Add a new pet profile
  Future<void> addProfile({
    required String name,
    required String type,
    required int age,
    required String breed,
    required double weight,
    required String notes,
  }) async {
    final id = _db.child("profiles").push().key;
    await _db.child("profiles/$id").set({
      "name": name,
      "type": type,
      "age": age,
      "breed": breed,
      "weight": weight,
      "notes": notes,
    });
  }

  /// Delete a pet profile
  Future<void> deleteProfile(String id) {
    return _db.child("profiles/$id").remove();
  }

  // ============ WATER ============

  /// Listen to water sensors
  Stream<DatabaseEvent> waterSensorsStream() {
    return _db.child("water/sensors").onValue;
  }

  /// Listen to water status
  Stream<DatabaseEvent> waterStatusStream() {
    return _db.child("water/status").onValue;
  }

  /// Listen to water alerts
  Stream<DatabaseEvent> waterAlertsStream() {
    return _db.child("water/alerts").onValue;
  }

  /// Listen to drain control state
  Stream<DatabaseEvent> drainControlStream() {
    return _db.child("water/controls/drain_button").onValue;
  }

  /// Toggle drain control
  Future<void> setDrainControl(bool value) {
    return _db.child("water/controls/drain_button").set(value);
  }

  // ============ ENTERTAINMENT ============

  /// Set entertainment system status
  Future<void> setEntertainment(bool value) {
    return _db.child("entertainment/commands/system_on").set(value);
  }

  /// Listen to entertainment status
  Stream<DatabaseEvent> entertainmentStream() {
    return _db.child("entertainment/commands/system_on").onValue;
  }

  // ============ LOGS ============

  /// Log a command
  Future<void> logCommand(String type, Map<String, dynamic> extra) async {
    await _db.child("logs/commands").push().set({
      "type": type,
      "ts": ServerValue.timestamp,
      ...extra,
    });
  }

  /// Log an alert
  Future<void> logAlert(String type, Map<String, dynamic> extra) async {
    await _db.child("logs/alerts").push().set({
      "type": type,
      "ts": ServerValue.timestamp,
      ...extra,
    });
  }

  /// Listen to command logs
  Stream<DatabaseEvent> commandLogsStream({int limit = 20}) {
    return _db.child("logs/commands").limitToLast(limit).onValue;
  }

  /// Listen to alert logs
  Stream<DatabaseEvent> alertLogsStream({int limit = 20}) {
    return _db.child("logs/alerts").limitToLast(limit).onValue;
  }
}
