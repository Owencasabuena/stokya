import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/log_entry.dart';

/// Service for writing and reading inventory audit logs.
///
/// Logs are stored under: `users/{uid}/logs/`
class LoggerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns a reference to the user's logs collection.
  CollectionReference _logsCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('logs');
  }

  /// Logs an "Item Added" action.
  Future<void> logItemAdded({
    required String uid,
    required String itemName,
    required int quantity,
    required double price,
  }) async {
    await _logsCollection(uid).add(LogEntry(
      id: '',
      itemName: itemName,
      action: 'Added',
      quantity: quantity,
      price: price,
      timestamp: DateTime.now(),
    ).toFirestore());
  }

  /// Logs a "Stock Updated" action.
  Future<void> logStockUpdated({
    required String uid,
    required String itemName,
    required int oldStock,
    required int newStock,
  }) async {
    final delta = newStock - oldStock;
    final sign = delta >= 0 ? '+' : '';
    await _logsCollection(uid).add(LogEntry(
      id: '',
      itemName: itemName,
      action: 'Stock Updated ($sign$delta)',
      quantity: newStock,
      timestamp: DateTime.now(),
    ).toFirestore());
  }

  /// Logs a "Price Updated" action.
  Future<void> logPriceUpdated({
    required String uid,
    required String itemName,
    required double oldPrice,
    required double newPrice,
  }) async {
    await _logsCollection(uid).add(LogEntry(
      id: '',
      itemName: itemName,
      action: 'Price Updated (₱${oldPrice.toStringAsFixed(2)} → ₱${newPrice.toStringAsFixed(2)})',
      price: newPrice,
      timestamp: DateTime.now(),
    ).toFirestore());
  }

  /// Logs an "Item Deleted" action.
  Future<void> logItemDeleted({
    required String uid,
    required String itemName,
  }) async {
    await _logsCollection(uid).add(LogEntry(
      id: '',
      itemName: itemName,
      action: 'Deleted',
      timestamp: DateTime.now(),
    ).toFirestore());
  }

  /// Streams all log entries for a user, newest first.
  Stream<List<LogEntry>> getLogs(String uid) {
    return _logsCollection(uid)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LogEntry.fromFirestore(doc))
          .toList();
    });
  }
}
