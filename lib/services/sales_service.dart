import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item.dart';
import '../models/sale.dart';

/// Service for processing sales and querying sales analytics.
///
/// Sales are stored under: `users/{uid}/sales/`
class SalesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _salesCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('sales');
  }

  DocumentReference _itemDoc(String uid, String itemId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('inventory')
        .doc(itemId);
  }

  /// Processes a sale: subtracts stock and records the transaction atomically.
  Future<Sale> processSale(String uid, InventoryItem item) async {
    final profit = item.salePrice - item.costPrice;
    final now = DateTime.now();

    final sale = Sale(
      id: '',
      itemId: item.id,
      itemName: item.name,
      barcode: item.barcode,
      costPrice: item.costPrice,
      salePrice: item.salePrice,
      profitEarned: profit,
      quantity: 1,
      saleDate: now,
    );

    // Use a Firestore batch for atomicity
    final batch = _firestore.batch();

    // 1. Subtract stock
    batch.update(_itemDoc(uid, item.id), {
      'stock': FieldValue.increment(-1),
      'updatedAt': Timestamp.now(),
    });

    // 2. Add sale record
    final saleRef = _salesCollection(uid).doc();
    batch.set(saleRef, sale.toFirestore());

    await batch.commit();

    return Sale(
      id: saleRef.id,
      itemId: sale.itemId,
      itemName: sale.itemName,
      barcode: sale.barcode,
      costPrice: sale.costPrice,
      salePrice: sale.salePrice,
      profitEarned: sale.profitEarned,
      quantity: sale.quantity,
      saleDate: sale.saleDate,
    );
  }

  /// Gets all sales for today.
  Future<List<Sale>> getTodaySales(String uid) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final snapshot = await _salesCollection(uid)
        .where('saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('saleDate', descending: true)
        .get();

    return snapshot.docs.map((doc) => Sale.fromFirestore(doc)).toList();
  }

  /// Gets all sales from the last 7 days.
  Future<List<Sale>> getLast7DaysSales(String uid) async {
    final now = DateTime.now();
    final sevenDaysAgo = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));

    final snapshot = await _salesCollection(uid)
        .where('saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
        .orderBy('saleDate', descending: true)
        .get();

    return snapshot.docs.map((doc) => Sale.fromFirestore(doc)).toList();
  }

  /// Streams today's sales for real-time dashboard updates.
  Stream<List<Sale>> streamTodaySales(String uid) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _salesCollection(uid)
        .where('saleDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('saleDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Sale.fromFirestore(doc)).toList());
  }
}
