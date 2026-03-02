import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/log_entry.dart';
import '../providers/auth_provider.dart' as app;
import '../services/logger_service.dart';

/// Screen displaying the inventory audit trail as a time-sorted log list.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _loggerService = LoggerService();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<app.AuthProvider>().user;
    final fg = ShadTheme.of(context).colorScheme.foreground;
    final mutedFg = ShadTheme.of(context).colorScheme.mutedForeground;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? const Center(child: Text('Not authenticated'))
          : StreamBuilder<List<LogEntry>>(
              stream: _loggerService.getLogs(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6366F1),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading history',
                      style: TextStyle(color: mutedFg),
                    ),
                  );
                }

                final logs = snapshot.data ?? [];

                if (logs.isEmpty) {
                  return _buildEmptyState(fg, mutedFg);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final prevLog = index > 0 ? logs[index - 1] : null;

                    // Date header
                    Widget? dateHeader;
                    final logDate = _dateOnly(log.timestamp);
                    final prevDate = prevLog != null
                        ? _dateOnly(prevLog.timestamp)
                        : null;
                    if (prevDate == null || logDate != prevDate) {
                      dateHeader = Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? 0 : 20,
                          bottom: 10,
                        ),
                        child: Text(
                          _formatDateHeader(log.timestamp),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ?dateHeader,
                        _buildLogCard(log, fg, mutedFg),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildLogCard(LogEntry log, Color fg, Color mutedFg) {
    final icon = _actionIcon(log.action);
    final iconColor = _actionColor(log.action);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShadCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.itemName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    log.action,
                    style: TextStyle(
                      fontSize: 12,
                      color: mutedFg,
                    ),
                  ),
                  if (log.quantity != null || log.price != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (log.quantity != null)
                          _buildBadge(
                            'Qty: ${log.quantity}',
                            const Color(0xFF3B82F6),
                          ),
                        if (log.quantity != null && log.price != null)
                          const SizedBox(width: 6),
                        if (log.price != null)
                          _buildBadge(
                            '₱${log.price!.toStringAsFixed(2)}',
                            const Color(0xFF22C55E),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Time
            Text(
              _formatTime(log.timestamp),
              style: TextStyle(fontSize: 11, color: mutedFg),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  IconData _actionIcon(String action) {
    if (action == 'Added') return Icons.add_circle_outline_rounded;
    if (action == 'Deleted') return Icons.delete_outline_rounded;
    if (action.startsWith('Stock')) return Icons.sync_alt_rounded;
    if (action.startsWith('Price')) return Icons.attach_money_rounded;
    return Icons.history_rounded;
  }

  Color _actionColor(String action) {
    if (action == 'Added') return const Color(0xFF22C55E);
    if (action == 'Deleted') return const Color(0xFFEF4444);
    if (action.startsWith('Stock')) return const Color(0xFF3B82F6);
    if (action.startsWith('Price')) return const Color(0xFFF59E0B);
    return const Color(0xFF6366F1);
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  String _formatDateHeader(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDay = DateTime(dt.year, dt.month, dt.day);

    if (logDay == today) return 'Today';
    if (logDay == today.subtract(const Duration(days: 1))) return 'Yesterday';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _dateOnly(DateTime dt) => '${dt.year}-${dt.month}-${dt.day}';

  Widget _buildEmptyState(Color fg, Color mutedFg) {
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
              Icons.history_rounded,
              size: 40,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No history yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Actions will appear here as you\nmanage your inventory',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: mutedFg),
          ),
        ],
      ),
    );
  }
}
