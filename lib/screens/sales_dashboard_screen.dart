import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/sale.dart';
import '../providers/auth_provider.dart' as app;
import '../services/sales_service.dart';

/// Sales analytics dashboard with summary cards and charts.
class SalesDashboardScreen extends StatefulWidget {
  const SalesDashboardScreen({super.key});

  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  final _salesService = SalesService();
  List<Sale> _todaySales = [];
  List<Sale> _weekSales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = context.read<app.AuthProvider>().user;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final today = await _salesService.getTodaySales(user.uid);
      final week = await _salesService.getLast7DaysSales(user.uid);

      if (!mounted) return;
      setState(() {
        _todaySales = today;
        _weekSales = week;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _todayProfit =>
      _todaySales.fold(0.0, (sum, s) => sum + s.profitEarned);

  double get _todayRevenue =>
      _todaySales.fold(0.0, (sum, s) => sum + s.salePrice);

  int get _todayItemsSold => _todaySales.length;

  /// Computes daily profit totals for the last 7 days.
  List<_DayProfit> get _dailyProfits {
    final now = DateTime.now();
    final result = <_DayProfit>[];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final dayEnd = day.add(const Duration(days: 1));

      final dayProfit = _weekSales
          .where((s) =>
              s.saleDate.isAfter(day.subtract(const Duration(seconds: 1))) &&
              s.saleDate.isBefore(dayEnd))
          .fold(0.0, (sum, s) => sum + s.profitEarned);

      result.add(_DayProfit(day: day, profit: dayProfit));
    }
    return result;
  }

  /// Returns the top 5 best-selling items by quantity.
  List<_TopItem> get _topItems {
    final counts = <String, int>{};
    for (final sale in _weekSales) {
      counts[sale.itemName] = (counts[sale.itemName] ?? 0) + sale.quantity;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(5)
        .map((e) => _TopItem(name: e.key, quantity: e.value))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final fg = ShadTheme.of(context).colorScheme.foreground;
    final mutedFg = ShadTheme.of(context).colorScheme.mutedForeground;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Summary Cards ---
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Profit Today',
                            value: '₱${_todayProfit.toStringAsFixed(2)}',
                            icon: Icons.trending_up_rounded,
                            color: const Color(0xFF22C55E),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Items Sold',
                            value: '$_todayItemsSold',
                            icon: Icons.shopping_cart_rounded,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryCard(
                      title: 'Revenue Today',
                      value: '₱${_todayRevenue.toStringAsFixed(2)}',
                      icon: Icons.payments_rounded,
                      color: const Color(0xFF6366F1),
                    ),
                    const SizedBox(height: 24),

                    // --- Profit Chart (Last 7 Days) ---
                    Text(
                      'Profit · Last 7 Days',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ShadCard(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        height: 200,
                        child: _buildProfitChart(mutedFg),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Top 5 Best Sellers ---
                    Text(
                      'Top 5 Best Sellers · This Week',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _topItems.isEmpty
                        ? ShadCard(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'No sales data yet',
                                style:
                                    TextStyle(fontSize: 13, color: mutedFg),
                              ),
                            ),
                          )
                        : ShadCard(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              height: 200,
                              child: _buildTopItemsChart(fg, mutedFg),
                            ),
                          ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: ShadTheme.of(context).colorScheme.mutedForeground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: ShadTheme.of(context).colorScheme.foreground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitChart(Color mutedFg) {
    final dailyProfits = _dailyProfits;
    final maxProfit = dailyProfits.fold(0.0,
        (max, d) => d.profit > max ? d.profit : max);
    final maxY = maxProfit == 0 ? 100.0 : (maxProfit * 1.3);

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '₱${rod.toY.toStringAsFixed(0)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= dailyProfits.length) {
                  return const SizedBox.shrink();
                }
                final day = dailyProfits[index].day;
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    days[day.weekday - 1],
                    style: TextStyle(fontSize: 11, color: mutedFg),
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: dailyProfits.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.profit,
                color: const Color(0xFF22C55E),
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopItemsChart(Color fg, Color mutedFg) {
    final items = _topItems;
    final maxQty = items.fold(0, (max, i) => i.quantity > max ? i.quantity : max);
    final maxY = maxQty == 0 ? 10.0 : (maxQty * 1.3);

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final name = items[groupIndex].name;
              return BarTooltipItem(
                '$name\n${rod.toY.toInt()} sold',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= items.length) {
                  return const SizedBox.shrink();
                }
                final name = items[index].name;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    name.length > 8 ? '${name.substring(0, 7)}…' : name,
                    style: TextStyle(fontSize: 10, color: mutedFg),
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: items.asMap().entries.map((entry) {
          final colors = [
            const Color(0xFF6366F1),
            const Color(0xFF3B82F6),
            const Color(0xFF22C55E),
            const Color(0xFFF59E0B),
            const Color(0xFFEF4444),
          ];
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.quantity.toDouble(),
                color: colors[entry.key % colors.length],
                width: 24,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DayProfit {
  final DateTime day;
  final double profit;
  _DayProfit({required this.day, required this.profit});
}

class _TopItem {
  final String name;
  final int quantity;
  _TopItem({required this.name, required this.quantity});
}
