import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/inventory_item.dart';
import '../repositories/inventory_repository.dart';

/// Manages inventory state: item list, search, and CRUD operations.
class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repository = InventoryRepository();

  List<InventoryItem> _allItems = [];
  List<InventoryItem> _filteredItems = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _itemsSubscription;
  String? _currentUid;

  /// The items to display (filtered if search is active).
  List<InventoryItem> get items =>
      _searchQuery.isEmpty ? _allItems : _filteredItems;

  /// Whether the inventory is currently loading.
  bool get isLoading => _isLoading;

  /// Last error message, or null.
  String? get error => _error;

  /// Current search query.
  String get searchQuery => _searchQuery;

  /// Total number of items in inventory.
  int get totalItems => _allItems.length;

  /// Subscribes to the Firestore inventory stream for a user.
  void listenToItems(String uid) {
    if (_currentUid == uid) return; // Already listening
    _currentUid = uid;
    _itemsSubscription?.cancel();

    _isLoading = true;
    notifyListeners();

    _itemsSubscription = _repository.getItems(uid).listen(
      (items) {
        _allItems = items;
        _applySearch();
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load inventory.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Updates the search query and filters items locally.
  void search(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  /// Applies the current search filter to the full item list.
  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredItems = [];
      return;
    }
    final lower = _searchQuery.toLowerCase();
    _filteredItems = _allItems.where((item) {
      return item.name.toLowerCase().contains(lower) ||
          (item.category?.toLowerCase().contains(lower) ?? false);
    }).toList();
  }

  /// Looks up an item by barcode.
  Future<InventoryItem?> getItemByBarcode(String uid, String barcode) async {
    try {
      return await _repository.getItemByBarcode(uid, barcode);
    } catch (e) {
      _error = 'Failed to look up barcode.';
      notifyListeners();
      return null;
    }
  }

  /// Adds a new item to the inventory.
  Future<bool> addItem(String uid, InventoryItem item) async {
    try {
      await _repository.addItem(uid, item);
      return true;
    } catch (e) {
      _error = 'Failed to add item.';
      notifyListeners();
      return false;
    }
  }

  /// Updates an existing item.
  Future<bool> updateItem(String uid, InventoryItem item) async {
    try {
      await _repository.updateItem(uid, item);
      return true;
    } catch (e) {
      _error = 'Failed to update item.';
      notifyListeners();
      return false;
    }
  }

  /// Updates just the stock count.
  Future<bool> updateStock(String uid, String itemId, int newStock) async {
    try {
      await _repository.updateStock(uid, itemId, newStock);
      return true;
    } catch (e) {
      _error = 'Failed to update stock.';
      notifyListeners();
      return false;
    }
  }

  /// Deletes an item from the inventory.
  Future<bool> deleteItem(String uid, String itemId) async {
    try {
      await _repository.deleteItem(uid, itemId);
      return true;
    } catch (e) {
      _error = 'Failed to delete item.';
      notifyListeners();
      return false;
    }
  }

  /// Clears the current error.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Stops listening and resets state (e.g., on logout).
  void reset() {
    _itemsSubscription?.cancel();
    _allItems = [];
    _filteredItems = [];
    _searchQuery = '';
    _currentUid = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _itemsSubscription?.cancel();
    super.dispose();
  }
}
