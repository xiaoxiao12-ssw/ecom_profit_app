import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/profit_record.dart';
import '../widgets/metric_card.dart';

class PricingToolsPage extends StatefulWidget {
  final ProfitRecord? baseRecord;
  final Function(ProfitRecord)? onApplyToCalculator;

  const PricingToolsPage({
    super.key,
    this.baseRecord,
    this.onApplyToCalculator,
  });

  @override
  State<PricingToolsPage> createState() => _PricingToolsPageState();
}

class _PricingToolsPageState extends State<PricingToolsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- 反推售价控制器 ---
  final _costCtrl = TextEditingController(text: '35.0');
  final _expressCtrl = TextEditingController(text: '3.5');
  final _packCtrl = TextEditingController(text: '1.5');
  final _commissionCtrl = TextEditingController(text: '5.0');
  final _insuranceCtrl = TextEditingController(text: '1.5');
  final _returnRateCtrl = TextEditingController(text: '15.0');
  final _promoCtrl = TextEditingController(text: '10.0');

  // 反推模式：0 = 期望单笔净利润 (元), 1 = 期望净利率 (%)
  int _targetMode = 0;
  final _targetProfitCtrl = TextEditingController(text: '25.0');
  final _targetMarginCtrl = TextEditingController(text: '20.0');

  double _recommendedPrice = 0.0;
  ProfitRecord? _reverseResultRecord;
  String? _reverseErrorMessage;

  // --- 三档对比方案控制器 ---
  final _tierDailyCtrl = TextEditingController(text: '99.0');
  final _tierPromoCtrl = TextEditingController(text: '89.0');
  final _tierFlashCtrl = TextEditingController(text: '79.0');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _syncFromBaseRecord();
    _calculateReversePrice();
  }

  void _syncFromBaseRecord() {
    final b = widget.baseRecord;
    if (b != null) {
      _costCtrl.text = b.costPrice > 0 ? b.costPrice.toStringAsFixed(1) : '35.0';
      _expressCtrl.text = b.expressFee > 0 ? b.expressFee.toStringAsFixed(1) : '3.5';
      _packCtrl.text = b.packFee > 0 ? b.packFee.toStringAsFixed(1) : '1.5';
      _commissionCtrl.text = b.commissionRate > 0 ? b.commissionRate.toStringAsFixed(1) : '5.0';
      _insuranceCtrl.text = b.shippingInsurance > 0 ? b.shippingInsurance.toStringAsFixed(1) : '1.5';
      _returnRateCtrl.text = b.returnRate > 0 ? b.returnRate.toStringAsFixed(1) : '15.0';
      _promoCtrl.text = b.promoFee > 0 ? b.promoFee.toStringAsFixed(1) : '10.0';

      if (b.sellingPrice > 0) {
        _tierDailyCtrl.text = b.sellingPrice.toStringAsFixed(1);
        _tierPromoCtrl.text = (b.sellingPrice * 0.9).toStringAsFixed(1);
        _tierFlashCtrl.text = (b.sellingPrice * 0.8).toStringAsFixed(1);
      }
    }
  }

  /// 严谨的数学反推公式
  /// 真实净利 NP = (1 - r) * [P * (1 - c) - Cost] - (Express + Pack + Insurance + Promo)
  /// 1. 按期望净利 NP_target:
  ///    P = [NP_target + (1 - r) * Cost + Express + Pack + Insurance + Promo] / [ (1 - r) * (1 - c) ]
  /// 2. 按期望净利率 m_target (NP = m_target * P):
  ///    P = [ (1 - r) * Cost + Express + Pack + Insurance + Promo ] / [ (1 - r) * (1 - c) - m_target ]
  void _calculateReversePrice() {
    final cost = double.tryParse(_costCtrl.text.trim()) ?? 0.0;
    final express = double.tryParse(_expressCtrl.text.trim()) ?? 0.0;
    final pack = double.tryParse(_packCtrl.text.trim()) ?? 0.0;
    final commissionPct = double.tryParse(_commissionCtrl.text.trim()) ?? 0.0;
    final insurance = double.tryParse(_insuranceCtrl.text.trim()) ?? 0.0;
    final returnRatePct = double.tryParse(_returnRateCtrl.text.trim()) ?? 0.0;
    final promo = double.tryParse(_promoCtrl.text.trim()) ?? 0.0;

    final r = (returnRatePct / 100.0).clamp(0.0, 0.999);
    final c = (commissionPct / 100.0).clamp(0.0, 0.999);
    final fixedCosts = express + pack + insurance + promo;

    setState(() {
      _reverseErrorMessage = null;
      try {
        if (_targetMode == 0) {
          // 固定净利润反推
          final targetProfit = double.tryParse(_targetProfitCtrl.text.trim()) ?? 0.0;
          final numerator = targetProfit + (1.0 - r) * cost + fixedCosts;
          final denominator = (1.0 - r) * (1.0 - c);
          if (denominator <= 0.0001) {
            _reverseErrorMessage = "退货率或平台扣点过高，无法反推";
            _recommendedPrice = 0.0;
            _reverseResultRecord = null;
            return;
          }
          _recommendedPrice = numerator / denominator;
        } else {
          // 期望净利率反推
          final targetMarginPct = double.tryParse(_targetMarginCtrl.text.trim()) ?? 0.0;
          final m = targetMarginPct / 100.0;
          final numerator = (1.0 - r) * cost + fixedCosts;
          final denominator = (1.0 - r) * (1.0 - c) - m;
          if (denominator <= 0.0001) {
            _reverseErrorMessage = "期望净利率过高（超过扣点与退货后的理论上限），无法达成";
            _recommendedPrice = 0.0;
            _reverseResultRecord = null;
            return;
          }
          _recommendedPrice = numerator / denominator;
        }

        if (_recommendedPrice < 0) {
          _reverseErrorMessage = "输入参数无法形成有效正售价";
          _recommendedPrice = 0.0;
          _reverseResultRecord = null;
          return;
        }

        _reverseResultRecord = ProfitRecord(
          id: 'reverse_${DateTime.now().millisecondsSinceEpoch}',
          productName: widget.baseRecord?.productName ?? '反推方案商品',
          platform: widget.baseRecord?.platform ?? '自定义',
          sellingPrice: _recommendedPrice,
          costPrice: cost,
          expressFee: express,
          packFee: pack,
          commissionRate: commissionPct,
          shippingInsurance: insurance,
          returnRate: returnRatePct,
          promoFee: promo,
          createdAt: DateTime.now(),
        );
      } catch (e) {
        _reverseErrorMessage = "计算异常，请检查数值格式";
        _recommendedPrice = 0.0;
        _reverseResultRecord = null;
      }
    });
  }

  ProfitRecord _createRecordForPrice(double price) {
    final cost = double.tryParse(_costCtrl.text.trim()) ?? 0.0;
    final express = double.tryParse(_expressCtrl.text.trim()) ?? 0.0;
    final pack = double.tryParse(_packCtrl.text.trim()) ?? 0.0;
    final commissionPct = double.tryParse(_commissionCtrl.text.trim()) ?? 0.0;
    final insurance = double.tryParse(_insuranceCtrl.text.trim()) ?? 0.0;
    final returnRatePct = double.tryParse(_returnRateCtrl.text.trim()) ?? 0.0;
    final promo = double.tryParse(_promoCtrl.text.trim()) ?? 0.0;

    return ProfitRecord(
      id: 'tier_${price.toInt()}',
      productName: widget.baseRecord?.productName ?? '对比商品',
      platform: widget.baseRecord?.platform ?? '自定义',
      sellingPrice: price,
      costPrice: cost,
      expressFee: express,
      packFee: pack,
      commissionRate: commissionPct,
      shippingInsurance: insurance,
      returnRate: returnRatePct,
      promoFee: promo,
      createdAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("定价与方案决策"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          indicatorColor: const Color(0xFF10B981),
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.calculate_outlined, size: 18), text: "利润反推售价"),
            Tab(icon: Icon(Icons.compare_arrows_rounded, size: 18), text: "三档定价对比"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReversePricingTab(isDark),
          _buildTierComparisonTab(isDark),
        ],
      ),
    );
  }

  // --- TAB 1: 利润反推售价 ---
  Widget _buildReversePricingTab(bool isDark) {
    final rec = _reverseResultRecord;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 核心反推结果展示大卡片
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0F2B26), const Color(0xFF134E4A)]
                    : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.auto_awesome, color: Color(0xFF059669), size: 20),
                        SizedBox(width: 6),
                        Text(
                          "系统建议最低售价",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                    if (rec != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: rec.healthBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          rec.healthBadgeText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: rec.healthColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_reverseErrorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _reverseErrorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        "¥",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _recommendedPrice.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF047857),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (rec != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _miniKpi("单笔净利", "¥${rec.realNetProfit.toStringAsFixed(1)}", isDark),
                        _miniKpi("真实净利率", "${rec.netMargin.toStringAsFixed(1)}%", isDark),
                        _miniKpi("保本 ROI", rec.breakevenRoi > 0 ? rec.breakevenRoi.toStringAsFixed(2) : "不可保本", isDark),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        if (widget.onApplyToCalculator != null && rec != null) {
                          widget.onApplyToCalculator!(rec);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("已将反推方案回填至【利润测算】页！")),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text("带入并应用此定价到测算器"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 期望盈利目标设置
          Text(
            "1. 期望盈利目标",
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
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text("按期望单笔净利润 (元)"),
                        selected: _targetMode == 0,
                        selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                        onSelected: (val) {
                          if (val) {
                            setState(() => _targetMode = 0);
                            _calculateReversePrice();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text("按期望净利率 (%)"),
                        selected: _targetMode == 1,
                        selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                        onSelected: (val) {
                          if (val) {
                            setState(() => _targetMode = 1);
                            _calculateReversePrice();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_targetMode == 0)
                  _buildInputRow("期望单笔净利 (元)", _targetProfitCtrl, "例如每单想赚 25.0 元", (v) => _calculateReversePrice())
                else
                  _buildInputRow("期望净利率 (%)", _targetMarginCtrl, "例如期望净利率 20.0%", (v) => _calculateReversePrice()),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 基础成本参数
          Text(
            "2. 基础成本与损耗参数",
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
                _buildInputRow("拿货成本 (元)", _costCtrl, "进货/生产单价", (v) => _calculateReversePrice()),
                const Divider(height: 16),
                _buildInputRow("发货快递费 (元)", _expressCtrl, "首重真实快递费", (v) => _calculateReversePrice()),
                const Divider(height: 16),
                _buildInputRow("包材人工 (元)", _packCtrl, "纸箱气泡袋与打包成本", (v) => _calculateReversePrice()),
                const Divider(height: 16),
                _buildInputRow("平台扣点 (%)", _commissionCtrl, "如天猫5%, 拼多多1%", (v) => _calculateReversePrice()),
                const Divider(height: 16),
                _buildInputRow("运费险费 (元)", _insuranceCtrl, "每单运费险保费", (v) => _calculateReversePrice()),
                const Divider(height: 16),
                _buildInputRow("预估退货率 (%)", _returnRateCtrl, "类目退货率", (v) => _calculateReversePrice()),
                const Divider(height: 16),
                _buildInputRow("单单推广费 (元)", _promoCtrl, "单均直通车/信息流花费", (v) => _calculateReversePrice()),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // --- TAB 2: 三档定价对比 ---
  Widget _buildTierComparisonTab(bool isDark) {
    final dailyP = double.tryParse(_tierDailyCtrl.text) ?? 99.0;
    final promoP = double.tryParse(_tierPromoCtrl.text) ?? 89.0;
    final flashP = double.tryParse(_tierFlashCtrl.text) ?? 79.0;

    final rDaily = _createRecordForPrice(dailyP);
    final rPromo = _createRecordForPrice(promoP);
    final rFlash = _createRecordForPrice(flashP);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "设置 3 档拟定售价",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _tierInput("日常标价", _tierDailyCtrl, () => setState(() {})),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _tierInput("大促活动价", _tierPromoCtrl, () => setState(() {})),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _tierInput("破价秒杀价", _tierFlashCtrl, () => setState(() {})),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 三档方案对比卡片
          _tierCompareCard("日常销售方案", rDaily, const Color(0xFF0284C7), isDark),
          const SizedBox(height: 12),
          _tierCompareCard("大促活动方案", rPromo, const Color(0xFFF59E0B), isDark),
          const SizedBox(height: 12),
          _tierCompareCard("破价秒杀方案", rFlash, const Color(0xFFEF4444), isDark),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _tierInput(String label, TextEditingController ctrl, VoidCallback onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: "¥",
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (v) => onChanged(),
        ),
      ],
    );
  }

  Widget _tierCompareCard(String title, ProfitRecord rec, Color accentColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rec.healthColor.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: rec.healthBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rec.healthBadgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: rec.healthColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: "拟定售价",
                  value: "¥${rec.sellingPrice.toStringAsFixed(1)}",
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricCard(
                  title: "真实净利",
                  value: "¥${rec.realNetProfit.toStringAsFixed(1)}",
                  valueColor: rec.healthColor,
                  isHighlight: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricCard(
                  title: "真实净利率",
                  value: "${rec.netMargin.toStringAsFixed(1)}%",
                  valueColor: rec.healthColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "保本 ROI: ${rec.breakevenRoi > 0 ? rec.breakevenRoi.toStringAsFixed(2) : '不可保本'}",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Text(
                "退货损耗分摊: ¥${rec.returnLossPerOrder.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(String label, TextEditingController ctrl, String hint, Function(String) onChanged) {
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
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _miniKpi(String label, String val, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[300] : const Color(0xFF065F46),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF047857),
          ),
        ),
      ],
    );
  }
}
