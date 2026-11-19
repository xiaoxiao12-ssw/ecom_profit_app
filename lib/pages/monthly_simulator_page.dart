import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/profit_record.dart';
import '../widgets/metric_card.dart';

class MonthlySimulatorPage extends StatefulWidget {
  final ProfitRecord? baseRecord;

  const MonthlySimulatorPage({
    super.key,
    this.baseRecord,
  });

  @override
  State<MonthlySimulatorPage> createState() => _MonthlySimulatorPageState();
}

class _MonthlySimulatorPageState extends State<MonthlySimulatorPage> {
  final _unitNetProfitCtrl = TextEditingController(text: '41.2');
  final _unitPriceCtrl = TextEditingController(text: '99.0');
  final _fixedCostRentCtrl = TextEditingController(text: '3000.0');
  final _fixedCostLaborCtrl = TextEditingController(text: '8000.0');
  final _fixedCostOtherCtrl = TextEditingController(text: '1500.0');
  final _targetMonthlyProfitCtrl = TextEditingController(text: '20000.0');
  final _operatingDaysCtrl = TextEditingController(text: '30');

  @override
  void initState() {
    super.initState();
    _syncFromBase();
  }

  void _syncFromBase() {
    final b = widget.baseRecord;
    if (b != null && b.sellingPrice > 0) {
      _unitPriceCtrl.text = b.sellingPrice.toStringAsFixed(1);
      _unitNetProfitCtrl.text = b.realNetProfit.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final unitNetProfit = double.tryParse(_unitNetProfitCtrl.text.trim()) ?? 0.0;
    final unitPrice = double.tryParse(_unitPriceCtrl.text.trim()) ?? 0.0;
    final rent = double.tryParse(_fixedCostRentCtrl.text.trim()) ?? 0.0;
    final labor = double.tryParse(_fixedCostLaborCtrl.text.trim()) ?? 0.0;
    final other = double.tryParse(_fixedCostOtherCtrl.text.trim()) ?? 0.0;
    final totalFixedCost = rent + labor + other;

    final targetMonthlyProfit = double.tryParse(_targetMonthlyProfitCtrl.text.trim()) ?? 0.0;
    final days = max(1, int.tryParse(_operatingDaysCtrl.text.trim()) ?? 30);

    // 计算指标
    final bool isProfitable = unitNetProfit > 0.001;
    final int breakevenMonthlyOrders = isProfitable ? (totalFixedCost / unitNetProfit).ceil() : 0;
    final double breakevenDailyOrders = isProfitable ? breakevenMonthlyOrders / days : 0.0;

    final double totalRequiredGrossMargin = totalFixedCost + targetMonthlyProfit;
    final int targetMonthlyOrders = isProfitable ? (totalRequiredGrossMargin / unitNetProfit).ceil() : 0;
    final double targetDailyOrders = isProfitable ? targetMonthlyOrders / days : 0.0;

    final double breakevenGmv = breakevenMonthlyOrders * unitPrice;
    final double targetGmv = targetMonthlyOrders * unitPrice;

    // 保本与纯利进度占比
    final double breakevenRatio = totalRequiredGrossMargin > 0
        ? (totalFixedCost / totalRequiredGrossMargin).clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("月度盈利沙盘"),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: "从测算器同步单品数据",
            onPressed: () {
              HapticFeedback.lightImpact();
              _syncFromBase();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("已从当前单品测算方案同步数据！")),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 顶部核心推演大卡片
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                      : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.flag_rounded, color: Color(0xFF38BDF8), size: 20),
                          SizedBox(width: 8),
                          Text(
                            "月度单量推演目标",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isProfitable
                              ? const Color(0xFF059669).withOpacity(0.3)
                              : const Color(0xFFDC2626).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isProfitable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                        child: Text(
                          isProfitable ? "正向盈利模型" : "单品亏损警告",
                          style: TextStyle(
                            color: isProfitable ? const Color(0xFF34D399) : const Color(0xFFF87171),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (!isProfitable)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7F1D1D).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "⚠️ 警告：当前单品净利润为 0 或负数，单品处于亏损状态！多卖不仅不能保本，还会扩大亏损，请先提价或降低成本。",
                        style: TextStyle(color: Color(0xFFFECACA), fontSize: 13),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _targetBox(
                            title: "保本日均单量",
                            value: "${breakevenDailyOrders.toStringAsFixed(1)} 单/天",
                            sub: "月需 $breakevenMonthlyOrders 单抵扣开支",
                            accentColor: const Color(0xFF38BDF8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _targetBox(
                            title: "目标日均单量",
                            value: "${targetDailyOrders.toStringAsFixed(1)} 单/天",
                            sub: "月需 $targetMonthlyOrders 单达成纯利",
                            accentColor: const Color(0xFF34D399),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // 目标进度与构成分布
                    Text(
                      "营收目标吸纳结构 (总需贡献毛利: ¥${totalRequiredGrossMargin.toStringAsFixed(0)})",
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: (breakevenRatio * 100).round().clamp(1, 100),
                            child: Container(
                              height: 12,
                              color: const Color(0xFF38BDF8),
                            ),
                          ),
                          Expanded(
                            flex: ((1.0 - breakevenRatio) * 100).round().clamp(1, 100),
                            child: Container(
                              height: 12,
                              color: const Color(0xFF34D399),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "固定开支: ¥${totalFixedCost.toStringAsFixed(0)} (${(breakevenRatio * 100).toStringAsFixed(0)}%)",
                          style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8)),
                        ),
                        Text(
                          "目标月纯利: ¥${targetMonthlyProfit.toStringAsFixed(0)} (${((1.0 - breakevenRatio) * 100).toStringAsFixed(0)}%)",
                          style: const TextStyle(fontSize: 11, color: Color(0xFF34D399)),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Colors.white24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _summaryGmv("保本月GMV", "¥${breakevenGmv.toStringAsFixed(0)}"),
                        _summaryGmv("目标月GMV", "¥${targetGmv.toStringAsFixed(0)}"),
                        _summaryGmv("单品净利", "¥${unitNetProfit.toStringAsFixed(1)}/单"),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 1. 每月固定开支
            Text(
              "1. 每月硬性固定开支 (无论卖多少都必须支出)",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[200] : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  _buildInputRow("仓库/办公房租 (元/月)", _fixedCostRentCtrl, "如场地仓租"),
                  const Divider(height: 16),
                  _buildInputRow("团队/人工底薪 (元/月)", _fixedCostLaborCtrl, "如客服、运营、美工"),
                  const Divider(height: 16),
                  _buildInputRow("软件/水电杂费 (元/月)", _fixedCostOtherCtrl, "如打单ERP、网络水电"),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "月固定开支合计",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "¥${totalFixedCost.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. 经营预期与运营天数
            Text(
              "2. 经营预期与运营周期",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[200] : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  _buildInputRow("期望每月纯利 (元/月)", _targetMonthlyProfitCtrl, "扣除所有成本后的纯到手利润"),
                  const Divider(height: 16),
                  _buildInputRow("月发货/营业天数 (天)", _operatingDaysCtrl, "默认 30 天"),
                  const Divider(height: 16),
                  _buildInputRow("当前单品售价 (元)", _unitPriceCtrl, "用于推算月度 GMV"),
                  const Divider(height: 16),
                  _buildInputRow("当前单品真实净利 (元/单)", _unitNetProfitCtrl, "单均扣除退货推广后的净利"),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _targetBox({
    required String title,
    required String value,
    required String sub,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _summaryGmv(String title, String val) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInputRow(String label, TextEditingController ctrl, String hint) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(hint, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.end,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (v) => setState(() {}),
          ),
        ),
      ],
    );
  }
}
