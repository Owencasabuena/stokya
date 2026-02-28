import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item.dart';

/// Repository for CRUD operations on the user's inventory in Firestore.
///
/// Each user's inventory is stored under: `users/{uid}/inventory/`
class InventoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns a reference to the user's inventory collection.
  CollectionReference _inventoryCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('inventory');
  }

  /// Streams all inventory items for a user, ordered by name.
  Stream<List<InventoryItem>> getItems(String uid) {
    return _inventoryCollection(uid)
        .orderBy('nameLower')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InventoryItem.fromFirestore(doc))
          .toList();
    });
  }

  /// Searches items by name prefix (case-insensitive).
  Future<List<InventoryItem>> searchItems(String uid, String query) async {
    final lowerQuery = query.toLowerCase();
    final snapshot = await _inventoryCollection(uid)
        .where('nameLower', isGreaterThanOrEqualTo: lowerQuery)
        .where('nameLower', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
        .get();

    return snapshot.docs
        .map((doc) => InventoryItem.fromFirestore(doc))
        .toList();
  }

  /// Looks up a single item by barcode. Returns null if not found.
  Future<InventoryItem?> getItemByBarcode(String uid, String barcode) async {
    final snapshot = await _inventoryCollection(uid)
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return InventoryItem.fromFirestore(snapshot.docs.first);
  }

  /// Adds a new inventory item. Returns the created document ID.
  Future<String> addItem(String uid, InventoryItem item) async {
    final docRef = await _inventoryCollection(uid).add(item.toFirestore());
    return docRef.id;
  }

  /// Updates an existing inventory item.
  Future<void> updateItem(String uid, InventoryItem item) async {
    await _inventoryCollection(uid).doc(item.id).update(item.toFirestore());
  }

  /// Updates only the stock count of an item.
  Future<void> updateStock(String uid, String itemId, int newStock) async {
    await _inventoryCollection(uid).doc(itemId).update({
      'stock': newStock,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Deletes an item by its document ID.
  Future<void> deleteItem(String uid, String itemId) async {
    await _inventoryCollection(uid).doc(itemId).delete();
  }
}
