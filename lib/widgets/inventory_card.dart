import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/inventory_item.dart';
import '../services/storage_service.dart';

/// A card widget displaying an inventory item's name, price, stock, and image.
///
/// Uses Image.file() for local image paths with a placeholder fallback.
class InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;

  const InventoryCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  Color _stockColor() {
    if (item.stock <= 0) return const Color(0xFFEF4444);
    if (item.stock <= 5) return const Color(0xFFF59E0B);
    return const Color(0xFF22C55E);
  }

  String _stockLabel() {
    if (item.stock <= 0) return 'Out of stock';
    if (item.stock <= 5) return 'Low stock';
    return 'In stock';
  }

  @override
  Widget build(BuildContext context) {
    final fg = ShadTheme.of(context).colorScheme.foreground;
    final mutedFg = ShadTheme.of(context).colorScheme.mutedForeground;
    final hasImage = StorageService.imageExists(item.imageUrl);

    return GestureDetector(
      onTap: onTap,
      child: ShadCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Item image or placeholder icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: !hasImage
                    ? LinearGradient(
                        colors: [
                          const Color(0xFF6366F1).withValues(alpha: 0.2),
                          const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? Image.file(
                      File(item.imageUrl!),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.inventory_2_outlined,
                        color: Color(0xFF6366F1),
                        size: 24,
                      ),
                    )
                  : const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF6366F1),
                      size: 24,
                    ),
            ),
            const SizedBox(width: 14),

            // Name and category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.category ?? 'Uncategorized',
                    style: TextStyle(
                      fontSize: 12,
                      color: mutedFg,
                    ),
                  ),
                ],
              ),
            ),

            // Price & stock
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₱${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _stockColor().withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.stock} · ${_stockLabel()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _stockColor(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
