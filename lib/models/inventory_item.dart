import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single inventory item in the sari-sari store.
class InventoryItem {
  final String id;
  final String name;
  final double price;
  final double costPrice;
  final double salePrice;
  final int stock;
  final String? barcode;
  final String? category;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.price,
    this.costPrice = 0,
    this.salePrice = 0,
    required this.stock,
    this.barcode,
    this.category,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates an [InventoryItem] from a Firestore document snapshot.
  factory InventoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryItem(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      costPrice: (data['costPrice'] ?? data['price'] ?? 0).toDouble(),
      salePrice: (data['salePrice'] ?? data['price'] ?? 0).toDouble(),
      stock: (data['stock'] ?? 0).toInt(),
      barcode: data['barcode'],
      category: data['category'],
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts this item to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'nameLower': name.toLowerCase(),
      'price': price,
      'costPrice': costPrice,
      'salePrice': salePrice,
      'stock': stock,
      'barcode': barcode,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Profit per unit sold.
  double get profit => salePrice - costPrice;

  /// Creates a copy of this item with optional field overrides.
  InventoryItem copyWith({
    String? id,
    String? name,
    double? price,
    double? costPrice,
    double? salePrice,
    int? stock,
    String? barcode,
    String? category,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      salePrice: salePrice ?? this.salePrice,
      stock: stock ?? this.stock,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'InventoryItem(id: $id, name: $name, stock: $stock)';
}
