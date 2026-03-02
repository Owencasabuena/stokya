import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/inventory_item.dart';
import '../providers/auth_provider.dart' as app;
import '../providers/inventory_provider.dart';
import '../services/logger_service.dart';
import '../services/storage_service.dart';
import '../widgets/stock_adjustment_buttons.dart';

/// Displays item details with stock management and delete functionality.
class ItemDetailScreen extends StatefulWidget {
  final InventoryItem item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late TextEditingController _stockController;
  late TextEditingController _priceController;
  late int _currentStock;
  late double _currentPrice;
  bool _isEditingPrice = false;
  bool _hasChanges = false;
  bool _isSaving = false;
  final _loggerService = LoggerService();

  @override
  void initState() {
    super.initState();
    _currentStock = widget.item.stock;
    _currentPrice = widget.item.price;
    _stockController = TextEditingController(text: _currentStock.toString());
    _priceController = TextEditingController(
        text: _currentPrice.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _stockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _adjustStock(int delta) {
    setState(() {
      _currentStock = (_currentStock + delta).clamp(0, 999999);
      _stockController.text = _currentStock.toString();
      _checkForChanges();
    });
  }

  void _onStockFieldChanged(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed >= 0) {
      setState(() {
        _currentStock = parsed;
        _checkForChanges();
      });
    }
  }

  void _onPriceFieldChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed >= 0) {
      setState(() {
        _currentPrice = parsed;
        _checkForChanges();
      });
    }
  }

  void _checkForChanges() {
    _hasChanges = _currentStock != widget.item.stock ||
        _currentPrice != widget.item.price;
  }

  Future<void> _saveChanges() async {
    final user = context.read<app.AuthProvider>().user;
    if (user == null) return;

    setState(() => _isSaving = true);

    final updatedItem = widget.item.copyWith(
      stock: _currentStock,
      price: _currentPrice,
      updatedAt: DateTime.now(),
    );

    final success = await context
        .read<InventoryProvider>()
        .updateItem(user.uid, updatedItem);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isEditingPrice = false;
    });

    if (success) {
      // Log stock/price changes
      if (_currentStock != widget.item.stock) {
        await _loggerService.logStockUpdated(
          uid: user.uid,
          itemName: widget.item.name,
          oldStock: widget.item.stock,
          newStock: _currentStock,
        );
      }
      if (_currentPrice != widget.item.price) {
        await _loggerService.logPriceUpdated(
          uid: user.uid,
          itemName: widget.item.name,
          oldPrice: widget.item.price,
          newPrice: _currentPrice,
        );
      }

      if (!mounted) return;
      setState(() => _hasChanges = false);
      ShadToaster.of(context).show(
        const ShadToast(
          title: Text('Item Updated'),
          description: Text('Changes have been saved successfully.'),
        ),
      );
    } else {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Update Failed'),
          description: Text('Could not save changes. Please try again.'),
        ),
      );
    }
  }

  Future<void> _deleteItem() async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('Delete Item'),
        description: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Are you sure you want to delete "${widget.item.name}"? '
            'This action cannot be undone.',
          ),
        ),
        actions: [
          ShadButton.outline(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final user = context.read<app.AuthProvider>().user;
    if (user == null) return;

    final success = await context
        .read<InventoryProvider>()
        .deleteItem(user.uid, widget.item.id);

    if (!mounted) return;

    if (success) {
      // Log deletion
      await _loggerService.logItemDeleted(
        uid: user.uid,
        itemName: widget.item.name,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Go back to home
      ShadToaster.of(context).show(
        const ShadToast(
          title: Text('Item Deleted'),
          description: Text('Item has been removed from inventory.'),
        ),
      );
    } else {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Delete Failed'),
          description: Text('Could not delete item. Please try again.'),
        ),
      );
    }
  }

  Color _stockColor() {
    if (_currentStock <= 0) return const Color(0xFFEF4444);
    if (_currentStock <= 5) return const Color(0xFFF59E0B);
    return const Color(0xFF22C55E);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
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
            // --- Item Header ---
            ShadCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Image or Icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: !StorageService.imageExists(widget.item.imageUrl)
                              ? const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: StorageService.imageExists(widget.item.imageUrl)
                            ? Image.file(
                                File(widget.item.imageUrl!),
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.inventory_2_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              )
                            : const Icon(
                                Icons.inventory_2_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                      ),
                      const SizedBox(width: 16),
                      // Name & category
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: ShadTheme.of(context)
                                    .colorScheme
                                    .foreground,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.item.category ?? 'Uncategorized',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Price
                  Row(
                    children: [
                      Icon(Icons.sell_outlined,
                          size: 18, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      if (_isEditingPrice)
                        Expanded(
                          child: ShadInput(
                            controller: _priceController,
                            placeholder: const Text('0.00'),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: _onPriceFieldChanged,
                            prefix: const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Text('₱',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6366F1),
                                  )),
                            ),
                          ),
                        )
                      else
                        Text(
                          '₱${_currentPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isEditingPrice = !_isEditingPrice;
                            if (_isEditingPrice) {
                              _priceController.text =
                                  _currentPrice.toStringAsFixed(2);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _isEditingPrice
                                ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _isEditingPrice
                                ? Icons.check_rounded
                                : Icons.edit_rounded,
                            size: 16,
                            color: _isEditingPrice
                                ? const Color(0xFF6366F1)
                                : Colors.grey[400],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Barcode (if present)
                  if (widget.item.barcode != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.qr_code_rounded,
                            size: 18, color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        Text(
                          widget.item.barcode!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Stock Management ---
            ShadCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stock Management',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ShadTheme.of(context)
                          .colorScheme
                          .foreground,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Current stock display
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '$_currentStock',
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w800,
                            color: _stockColor(),
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'units in stock',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick adjustment buttons
                  Text(
                    'Quick Adjust',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ShadTheme.of(context)
                          .colorScheme
                          .mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StockAdjustmentButtons(onAdjust: _adjustStock),
                  const SizedBox(height: 20),

                  // Manual entry
                  Text(
                    'Manual Entry',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ShadTheme.of(context)
                          .colorScheme
                          .mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ShadInput(
                    controller: _stockController,
                    placeholder: const Text('Enter stock count'),
                    keyboardType: TextInputType.number,
                    onChanged: _onStockFieldChanged,
                    prefix: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.edit_outlined,
                          size: 16, color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ShadButton(
                      onPressed:
                          (_hasChanges && !_isSaving) ? _saveChanges : null,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Delete Section ---
            SizedBox(
              width: double.infinity,
              child: ShadButton.destructive(
                onPressed: _deleteItem,
                icon: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.delete_outline_rounded, size: 18),
                ),
                child: const Text('Delete Item'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
