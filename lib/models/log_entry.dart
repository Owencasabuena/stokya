import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single audit log entry for inventory changes.
class LogEntry {
  final String id;
  final String itemName;
  final String action;
  final int? quantity;
  final double? price;
  final DateTime timestamp;

  const LogEntry({
    required this.id,
    required this.itemName,
    required this.action,
    this.quantity,
    this.price,
    required this.timestamp,
  });

  /// Creates a [LogEntry] from a Firestore document snapshot.
  factory LogEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LogEntry(
      id: doc.id,
      itemName: data['itemName'] ?? '',
      action: data['action'] ?? '',
      quantity: data['quantity'],
      price: data['price'] != null ? (data['price'] as num).toDouble() : null,
      timestamp:
          (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts this entry to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'itemName': itemName,
      'action': action,
      'quantity': quantity,
      'price': price,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
