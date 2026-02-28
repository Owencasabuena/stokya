import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/auth_provider.dart' as app;
import '../providers/inventory_provider.dart';
import '../widgets/inventory_card.dart';
import 'item_detail_screen.dart';
import 'add_item_screen.dart';
import 'scanner_screen.dart';

/// Main home screen showing the inventory list with search and scan.
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

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();

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
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: inventoryProvider.items.length,
                        itemBuilder: (context, index) {
                          final item = inventoryProvider.items[index];
                          return Padding(
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

  Widget _buildEmptyState() {
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
          const Text(
            'No items yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
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

  InventoryProvider get inventoryProvider => context.read<InventoryProvider>();
}
