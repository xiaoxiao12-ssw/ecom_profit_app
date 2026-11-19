import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/profit_record.dart';

class ProfitPieChart extends StatelessWidget {
  final ProfitRecord record;
  final bool isDark;

  const ProfitPieChart({
    super.key,
    required this.record,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    if (record.sellingPrice <= 0) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        child: Text(
          "输入售价和成本后，此处将自动绘制成本与利润全景环形图",
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Cost Breakdown items
    final double sp = record.sellingPrice;
    final double cost = record.costPrice;
    final double fulfillment = record.expressFee + record.packFee;
    final double commission = record.commissionAmount;
    final double insurance = record.shippingInsurance;
    final double returnLoss = record.returnLossPerOrder;
    final double promo = record.promoFee;
    final double netProfit = max(0.0, record.realNetProfit);

    final items = [
      _PieSlice("拿货成本", cost, const Color(0xFF64748B)),
      _PieSlice("履约快递包材", fulfillment, const Color(0xFF0EA5E9)),
      _PieSlice("平台扣点", commission, const Color(0xFF8B5CF6)),
      _PieSlice("运费险", insurance, const Color(0xFFF97316)),
      _PieSlice("退货损耗", returnLoss, const Color(0xFFF43F5E)),
      _PieSlice("单单推广", promo, const Color(0xFFEAB308)),
      _PieSlice("真实净利", netProfit, const Color(0xFF10B981)),
    ].where((e) => e.value > 0.001).toList();

    final double totalValue = items.fold(0.0, (acc, e) => acc + e.value);

    final sections = items.map((slice) {
      final double pct = totalValue > 0 ? (slice.value / totalValue) * 100 : 0;
      return PieChartSectionData(
        value: slice.value,
        color: slice.color,
        radius: 28,
        showTitle: false,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.donut_large_rounded, size: 18, color: Color(0xFF10B981)),
                const SizedBox(width: 6),
                Text(
                  "成本与利润构成全景",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: record.healthBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                record.healthBadgeText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: record.healthColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Donut chart with centered health info
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 44,
                      sectionsSpace: 2,
                      startDegreeOffset: -90,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        record.realNetProfit >= 0 ? "净利率" : "亏损率",
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${record.netMargin.toStringAsFixed(1)}%",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: record.healthColor,
                        ),
                      ),
                      Text(
                        "¥${record.realNetProfit.toStringAsFixed(1)}",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Legends
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: items.map((slice) {
                  final pct = totalValue > 0 ? (slice.value / totalValue) * 100 : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: slice.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            slice.name,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          "¥${slice.value.toStringAsFixed(1)}",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[200] : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 38,
                          child: Text(
                            "${pct.toStringAsFixed(1)}%",
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.grey[400] : Colors.grey[500],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PieSlice {
  final String name;
  final double value;
  final Color color;

  _PieSlice(this.name, this.value, this.color);
}
