import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single sale transaction.
class Sale {
  final String id;
  final String itemId;
  final String itemName;
  final String? barcode;
  final double costPrice;
  final double salePrice;
  final double profitEarned;
  final int quantity;
  final DateTime saleDate;

  const Sale({
    required this.id,
    required this.itemId,
    required this.itemName,
    this.barcode,
    required this.costPrice,
    required this.salePrice,
    required this.profitEarned,
    this.quantity = 1,
    required this.saleDate,
  });

  factory Sale.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Sale(
      id: doc.id,
      itemId: data['itemId'] ?? '',
      itemName: data['itemName'] ?? '',
      barcode: data['barcode'],
      costPrice: (data['costPrice'] ?? 0).toDouble(),
      salePrice: (data['salePrice'] ?? 0).toDouble(),
      profitEarned: (data['profitEarned'] ?? 0).toDouble(),
      quantity: (data['quantity'] ?? 1).toInt(),
      saleDate: (data['saleDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'barcode': barcode,
      'costPrice': costPrice,
      'salePrice': salePrice,
      'profitEarned': profitEarned,
      'quantity': quantity,
      'saleDate': Timestamp.fromDate(saleDate),
    };
  }
}
