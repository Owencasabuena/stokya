import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/inventory_item.dart';
import '../providers/auth_provider.dart' as app;
import '../providers/inventory_provider.dart';
import 'scanner_screen.dart';

/// Screen for adding a new inventory item.
class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _categoryController = TextEditingController();
  String? _scannedBarcode;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const ScannerScreen(returnBarcodeOnly: true),
      ),
    );
    if (barcode != null && mounted) {
      setState(() => _scannedBarcode = barcode);
    }
  }

  Future<void> _saveItem() async {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final stockText = _stockController.text.trim();
    final category = _categoryController.text.trim();

    // Validate
    if (name.isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Missing Name'),
          description: Text('Please enter an item name.'),
        ),
      );
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price < 0) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Invalid Price'),
          description: Text('Please enter a valid price.'),
        ),
      );
      return;
    }

    final stock = int.tryParse(stockText);
    if (stock == null || stock < 0) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Invalid Stock'),
          description: Text('Please enter a valid stock count.'),
        ),
      );
      return;
    }

    final user = context.read<app.AuthProvider>().user;
    if (user == null) return;

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final item = InventoryItem(
      id: '', // Will be set by Firestore
      name: name,
      price: price,
      stock: stock,
      barcode: _scannedBarcode,
      category: category.isEmpty ? null : category,
      createdAt: now,
      updatedAt: now,
    );

    final success =
        await context.read<InventoryProvider>().addItem(user.uid, item);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
      ShadToaster.of(context).show(
        ShadToast(
          title: const Text('Item Added'),
          description: Text('$name has been added to your inventory.'),
        ),
      );
    } else {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Save Failed'),
          description: Text('Could not save item. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'New Inventory Item',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fill in the details below to add a new item.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 28),

            // Name
            _buildLabel('Item Name *'),
            const SizedBox(height: 8),
            ShadInput(
              controller: _nameController,
              placeholder: const Text('e.g. Lucky Me Pancit Canton'),
              prefix: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.inventory_2_outlined,
                    size: 18, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 20),

            // Price
            _buildLabel('Price (₱) *'),
            const SizedBox(height: 8),
            ShadInput(
              controller: _priceController,
              placeholder: const Text('0.00'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              prefix: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.sell_outlined,
                    size: 18, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 20),

            // Initial Stock
            _buildLabel('Initial Stock *'),
            const SizedBox(height: 8),
            ShadInput(
              controller: _stockController,
              placeholder: const Text('0'),
              keyboardType: TextInputType.number,
              prefix: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.stacked_bar_chart_rounded,
                    size: 18, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 20),

            // Category (optional)
            _buildLabel('Category'),
            const SizedBox(height: 8),
            ShadInput(
              controller: _categoryController,
              placeholder: const Text('e.g. Snacks, Beverages, Canned Goods'),
              prefix: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.category_outlined,
                    size: 18, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 20),

            // Barcode
            _buildLabel('Barcode'),
            const SizedBox(height: 8),
            ShadCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _scannedBarcode != null
                        ? Row(
                            children: [
                              const Icon(Icons.qr_code_rounded,
                                  size: 20, color: Color(0xFF22C55E)),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  _scannedBarcode!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontFamily: 'monospace',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'No barcode scanned',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                  ),
                  ShadButton.outline(
                    onPressed: _scanBarcode,
                    size: ShadButtonSize.sm,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.qr_code_scanner_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text(_scannedBarcode != null ? 'Rescan' : 'Scan'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ShadButton(
                onPressed: _isSaving ? null : _saveItem,
                size: ShadButtonSize.lg,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add to Inventory'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
      ),
    );
  }
}
