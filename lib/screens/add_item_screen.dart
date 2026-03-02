import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../constants/categories.dart';
import '../models/inventory_item.dart';
import '../providers/auth_provider.dart' as app;
import '../providers/inventory_provider.dart';
import '../services/logger_service.dart';
import '../services/storage_service.dart';
import 'scanner_screen.dart';

/// Screen for adding a new inventory item with category dropdown and image picker.
class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _storageService = StorageService();
  final _loggerService = LoggerService();

  String? _selectedCategory;
  String? _scannedBarcode;
  File? _selectedImage;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
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

  Future<void> _pickImage() async {
    final fg = ShadTheme.of(context).colorScheme.foreground;
    final mutedFg = ShadTheme.of(context).colorScheme.mutedForeground;

    showModalBottomSheet(
      context: context,
      backgroundColor: ShadTheme.of(context).colorScheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              ListTile(
                leading: Icon(Icons.camera_alt_rounded,
                    color: const Color(0xFF6366F1)),
                title: Text('Take Photo',
                    style: TextStyle(color: fg)),
                subtitle: Text('Use camera to take a picture',
                    style: TextStyle(fontSize: 12, color: mutedFg)),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await _storageService.takePhoto();
                  if (file != null && mounted) {
                    setState(() => _selectedImage = file);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_rounded,
                    color: const Color(0xFF6366F1)),
                title: Text('Choose from Gallery',
                    style: TextStyle(color: fg)),
                subtitle: Text('Select an existing photo',
                    style: TextStyle(fontSize: 12, color: mutedFg)),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await _storageService.pickFromGallery();
                  if (file != null && mounted) {
                    setState(() => _selectedImage = file);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveItem() async {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final stockText = _stockController.text.trim();

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
    final inventoryProvider = context.read<InventoryProvider>();

    try {
      // Save image locally if selected
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _storageService.saveImageLocally(_selectedImage!);
      }

      final now = DateTime.now();
      final item = InventoryItem(
        id: '',
        name: name,
        price: price,
        stock: stock,
        barcode: _scannedBarcode,
        category: _selectedCategory,
        imageUrl: imageUrl,
        createdAt: now,
        updatedAt: now,
      );

      final success =
          await inventoryProvider.addItem(user.uid, item);

      if (!mounted) return;

      if (success) {
        // Log the action
        await _loggerService.logItemAdded(
          uid: user.uid,
          itemName: name,
          quantity: stock,
          price: price,
        );

        if (!mounted) return;
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
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Error'),
            description: Text('An error occurred. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mutedFg = ShadTheme.of(context).colorScheme.mutedForeground;
    final fg = ShadTheme.of(context).colorScheme.foreground;

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
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fill in the details below to add a new item.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 28),

            // --- Image Picker ---
            _buildLabel('Item Photo'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: ShadCard(
                padding: const EdgeInsets.all(0),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            Image.file(
                              _selectedImage!,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                            // Remove button
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      size: 18, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                size: 32,
                                color: mutedFg),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add a photo',
                              style: TextStyle(
                                  fontSize: 13, color: mutedFg),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Camera or Gallery',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

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

            // --- Category Dropdown ---
            _buildLabel('Category'),
            const SizedBox(height: 8),
            ShadCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: DropdownButton<String>(
                value: _selectedCategory,
                hint: Text('Select a category',
                    style: TextStyle(fontSize: 14, color: mutedFg)),
                isExpanded: true,
                underline: const SizedBox.shrink(),
                dropdownColor: ShadTheme.of(context).colorScheme.card,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: mutedFg),
                style: TextStyle(fontSize: 14, color: fg),
                items: StoreCategories.all
                    .map((cat) => DropdownMenuItem<String>(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(Icons.label_outlined,
                                  size: 16,
                                  color: const Color(0xFF6366F1)),
                              const SizedBox(width: 8),
                              Text(cat),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedCategory = value),
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
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: fg,
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
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: ShadTheme.of(context).colorScheme.mutedForeground,
      ),
    );
  }
}
