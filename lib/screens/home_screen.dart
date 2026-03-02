import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/auth_provider.dart' as app;
import '../providers/inventory_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/inventory_card.dart';
import 'item_detail_screen.dart';
import 'add_item_screen.dart';
import 'checkout_screen.dart';
import 'history_screen.dart';
import 'sales_dashboard_screen.dart';
import 'scanner_screen.dart';

/// Main home screen showing the inventory list with search, sort, and scan.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Start listening to inventory stream once we have a user.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<app.AuthProvider>().user;
      if (user != null) {
        context.read<InventoryProvider>().listenToItems(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Handle barcode scan from the home screen.
  Future<void> _handleScan() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (barcode == null || !mounted) return;

    final user = context.read<app.AuthProvider>().user;
    if (user == null) return;

    final inventoryProvider = context.read<InventoryProvider>();
    final item = await inventoryProvider.getItemByBarcode(user.uid, barcode);

    if (!mounted) return;

    if (item != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ItemDetailScreen(item: item),
        ),
      );
    } else {
      ShadToaster.of(context).show(
        ShadToast(
          title: const Text('Item Not Found'),
          description: Text('No item found with barcode: $barcode'),
        ),
      );
    }
  }

  void _handleLogout() async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('Sign Out'),
        description: const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('Are you sure you want to sign out?'),
        ),
        actions: [
          ShadButton.outline(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: const Text('Sign Out'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<InventoryProvider>().reset();
      context.read<app.AuthProvider>().signOut();
    }
  }

  void _showSortOptions() {
    final inventoryProvider = context.read<InventoryProvider>();
    final isDark = context.read<ThemeProvider>().isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1D) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                ...SortOption.values.map((option) {
                  final isSelected =
                      inventoryProvider.sortOption == option;
                  return ListTile(
                    leading: Icon(
                      _sortIcon(option),
                      size: 20,
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : (isDark ? Colors.grey[500] : Colors.grey[600]),
                    ),
                    title: Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded,
                            size: 18, color: Color(0xFF6366F1))
                        : null,
                    onTap: () {
                      inventoryProvider.setSortOption(option);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _sortIcon(SortOption option) {
    switch (option) {
      case SortOption.nameAZ:
        return Icons.sort_by_alpha_rounded;
      case SortOption.nameZA:
        return Icons.sort_by_alpha_rounded;
      case SortOption.stockLowHigh:
        return Icons.trending_up_rounded;
      case SortOption.stockHighLow:
        return Icons.trending_down_rounded;
      case SortOption.priceHighLow:
        return Icons.arrow_downward_rounded;
      case SortOption.priceLowHigh:
        return Icons.arrow_upward_rounded;
      case SortOption.category:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.storefront_rounded,
                size: 24, color: Color(0xFF6366F1)),
            SizedBox(width: 10),
            Text('Stokya'),
          ],
        ),
        actions: [
          // Theme toggle
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 22,
            ),
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
            onPressed: () => themeProvider.toggleTheme(),
          ),
          // Sales Dashboard button
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, size: 22),
            tooltip: 'Sales Dashboard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SalesDashboardScreen()),
              );
            },
          ),
          // Checkout button
          IconButton(
            icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 22),
            tooltip: 'Checkout',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CheckoutScreen()),
              );
            },
          ),
          // History button
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 22),
            tooltip: 'History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          // Add item button
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 26),
            tooltip: 'Add Item',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddItemScreen()),
              );
            },
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 22),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar + Filter button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: ShadInput(
                    controller: _searchController,
                    placeholder: const Text('Search items...'),
                    onChanged: (value) {
                      inventoryProvider.search(value);
                    },
                    prefix: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.search_rounded,
                          size: 20, color: Colors.grey[500]),
                    ),
                    suffix: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              inventoryProvider.search('');
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(Icons.close_rounded,
                                  size: 18, color: Colors.grey[500]),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                // Sort/Filter button
                GestureDetector(
                  onTap: _showSortOptions,
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: inventoryProvider.sortOption != SortOption.nameAZ
                          ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                          : (isDark
                              ? Colors.grey.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: inventoryProvider.sortOption != SortOption.nameAZ
                            ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                            : Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.sort_rounded,
                      size: 20,
                      color: inventoryProvider.sortOption != SortOption.nameAZ
                          ? const Color(0xFF6366F1)
                          : Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${inventoryProvider.items.length} item${inventoryProvider.items.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
                if (inventoryProvider.searchQuery.isNotEmpty) ...[
                  Text(
                    '  ·  Searching "${inventoryProvider.searchQuery}"',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                if (inventoryProvider.sortOption != SortOption.nameAZ) ...[
                  Text(
                    '  ·  ${inventoryProvider.sortOption.label}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Item list
          Expanded(
            child: inventoryProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6366F1),
                    ),
                  )
                : inventoryProvider.items.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: inventoryProvider.items.length,
                        itemBuilder: (context, index) {
                          final item = inventoryProvider.items[index];

                          // Category header for "Group by Category" mode
                          Widget? categoryHeader;
                          if (inventoryProvider.sortOption ==
                              SortOption.category) {
                            final currentCat =
                                item.category ?? 'Uncategorized';
                            final prevCat = index > 0
                                ? (inventoryProvider.items[index - 1]
                                        .category ??
                                    'Uncategorized')
                                : null;
                            if (prevCat == null || currentCat != prevCat) {
                              categoryHeader = Padding(
                                padding: EdgeInsets.only(
                                  top: index == 0 ? 0 : 16,
                                  bottom: 8,
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.label_outlined,
                                        size: 16,
                                        color: const Color(0xFF6366F1)),
                                    const SizedBox(width: 6),
                                    Text(
                                      currentCat,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? const Color(0xFF6366F1)
                                            : const Color(0xFF4F46E5),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ?categoryHeader,
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: InventoryCard(
                                  item: item,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ItemDetailScreen(item: item),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),

      // Scan FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleScan,
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text(
          'Scan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final inventoryProvider = context.read<InventoryProvider>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No items yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            inventoryProvider.searchQuery.isNotEmpty
                ? 'No items match your search'
                : 'Tap + to add your first inventory item',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
