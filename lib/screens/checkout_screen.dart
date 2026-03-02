import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/inventory_item.dart';
import '../providers/auth_provider.dart' as app;
import '../providers/inventory_provider.dart';
import '../services/logger_service.dart';
import '../services/sales_service.dart';
import 'scanner_screen.dart';

/// Checkout mode: scan a barcode to sell an item (subtract stock + record sale).
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _salesService = SalesService();
  final _loggerService = LoggerService();
  bool _isProcessing = false;
  final List<_SaleRecord> _recentSales = [];

  Future<void> _scanAndSell() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const ScannerScreen(returnBarcodeOnly: true),
      ),
    );
    if (barcode == null || !mounted) return;

    final user = context.read<app.AuthProvider>().user;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      // Find item by barcode
      final inventoryProvider = context.read<InventoryProvider>();
      final items = inventoryProvider.items;
      final item = items.cast<InventoryItem?>().firstWhere(
            (i) => i!.barcode == barcode,
            orElse: () => null,
          );

      if (item == null) {
        if (!mounted) return;
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Item Not Found'),
            description: Text('No item with barcode "$barcode" in inventory.'),
          ),
        );
        setState(() => _isProcessing = false);
        return;
      }

      if (item.stock <= 0) {
        if (!mounted) return;
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Out of Stock'),
            description: Text('${item.name} has no stock remaining.'),
          ),
        );
        setState(() => _isProcessing = false);
        return;
      }

      // Process the sale
      final sale = await _salesService.processSale(user.uid, item);

      // Log the sale
      await _loggerService.logStockUpdated(
        uid: user.uid,
        itemName: item.name,
        oldStock: item.stock,
        newStock: item.stock - 1,
      );


      if (!mounted) return;

      setState(() {
        _recentSales.insert(
          0,
          _SaleRecord(
            itemName: item.name,
            salePrice: item.salePrice,
            profit: sale.profitEarned,
            time: DateTime.now(),
          ),
        );
        _isProcessing = false;
      });

      ShadToaster.of(context).show(
        ShadToast(
          title: const Text('Sale Recorded ✓'),
          description: Text(
            '${item.name} — ₱${item.salePrice.toStringAsFixed(2)} '
            '(Profit: ₱${sale.profitEarned.toStringAsFixed(2)})',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Sale Failed'),
          description: Text('Could not process sale. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = ShadTheme.of(context).colorScheme.foreground;
    final mutedFg = ShadTheme.of(context).colorScheme.mutedForeground;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Scan button area
          Padding(
            padding: const EdgeInsets.all(20),
            child: ShadCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.point_of_sale_rounded,
                      size: 36,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Scan to Sell',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Scan a barcode to record a sale and\nautomatically update stock',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: mutedFg),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ShadButton(
                      onPressed: _isProcessing ? null : _scanAndSell,
                      size: ShadButtonSize.lg,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_scanner_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Scan Barcode'),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recent sales header
          if (_recentSales.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Recent Sales',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_recentSales.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Recent sales list
          Expanded(
            child: _recentSales.isEmpty
                ? Center(
                    child: Text(
                      'No sales this session yet',
                      style: TextStyle(fontSize: 13, color: mutedFg),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _recentSales.length,
                    itemBuilder: (context, index) {
                      final sale = _recentSales[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ShadCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.shopping_cart_checkout_rounded,
                                  size: 18,
                                  color: Color(0xFF22C55E),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sale.itemName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: fg,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₱${sale.salePrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontSize: 12, color: mutedFg),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '+₱${sale.profit.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF22C55E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SaleRecord {
  final String itemName;
  final double salePrice;
  final double profit;
  final DateTime time;

  _SaleRecord({
    required this.itemName,
    required this.salePrice,
    required this.profit,
    required this.time,
  });
}
