import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/inventory_item.dart';
import '../repositories/inventory_repository.dart';

/// Sorting options for the inventory list.
enum SortOption {
  nameAZ('Name: A → Z'),
  nameZA('Name: Z → A'),
  stockLowHigh('Stock: Low → High'),
  stockHighLow('Stock: High → Low'),
  priceHighLow('Price: High → Low'),
  priceLowHigh('Price: Low → High'),
  category('Group by Category');

  final String label;
  const SortOption(this.label);
}

/// Manages inventory state: item list, search, sorting, and CRUD operations.
class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repository = InventoryRepository();

  List<InventoryItem> _allItems = [];
  List<InventoryItem> _displayItems = [];
  String _searchQuery = '';
  SortOption _sortOption = SortOption.nameAZ;
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _itemsSubscription;
  String? _currentUid;

  /// The items to display (filtered and sorted).
  List<InventoryItem> get items => _displayItems;

  /// Whether the inventory is currently loading.
  bool get isLoading => _isLoading;

  /// Last error message, or null.
  String? get error => _error;

  /// Current search query.
  String get searchQuery => _searchQuery;

  /// Current sort option.
  SortOption get sortOption => _sortOption;

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
        _applyFiltersAndSort();
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

  /// Updates the search query and re-filters items locally.
  void search(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Sets the sort option and re-sorts the item list.
  void setSortOption(SortOption option) {
    _sortOption = option;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// Applies search filtering and sorting to the full item list.
  void _applyFiltersAndSort() {
    // Step 1: Filter by search
    List<InventoryItem> result;
    if (_searchQuery.isEmpty) {
      result = List.from(_allItems);
    } else {
      final lower = _searchQuery.toLowerCase();
      result = _allItems.where((item) {
        return item.name.toLowerCase().contains(lower) ||
            (item.category?.toLowerCase().contains(lower) ?? false);
      }).toList();
    }

    // Step 2: Sort
    switch (_sortOption) {
      case SortOption.nameAZ:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case SortOption.nameZA:
        result.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      case SortOption.stockLowHigh:
        result.sort((a, b) => a.stock.compareTo(b.stock));
      case SortOption.stockHighLow:
        result.sort((a, b) => b.stock.compareTo(a.stock));
      case SortOption.priceHighLow:
        result.sort((a, b) => b.price.compareTo(a.price));
      case SortOption.priceLowHigh:
        result.sort((a, b) => a.price.compareTo(b.price));
      case SortOption.category:
        result.sort((a, b) {
          final catA = a.category ?? 'zzz_uncategorized';
          final catB = b.category ?? 'zzz_uncategorized';
          final catCompare = catA.toLowerCase().compareTo(catB.toLowerCase());
          if (catCompare != 0) return catCompare;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
    }

    _displayItems = result;
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
    _displayItems = [];
    _searchQuery = '';
    _sortOption = SortOption.nameAZ;
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
