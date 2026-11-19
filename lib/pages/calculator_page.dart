import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/profit_record.dart';
import '../services/storage_service.dart';
import '../widgets/metric_card.dart';
import '../widgets/profit_pie_chart.dart';

class CalculatorPage extends StatefulWidget {
  final ProfitRecord? initialRecord;
  final VoidCallback? onSaved;
  final Function(ProfitRecord)? onRecordChanged;

  const CalculatorPage({
    super.key,
    this.initialRecord,
    this.onSaved,
    this.onRecordChanged,
  });

  @override
  State<CalculatorPage> createState() => CalculatorPageState();
}

class CalculatorPageState extends State<CalculatorPage> {
  String _selectedPlatform = '淘宝/天猫';

  final _nameCtrl = TextEditingController();
  final _sellingPriceCtrl = TextEditingController(text: '99.0');
  final _costPriceCtrl = TextEditingController(text: '35.0');
  final _expressFeeCtrl = TextEditingController(text: '3.5');
  final _packFeeCtrl = TextEditingController(text: '1.5');
  final _commissionRateCtrl = TextEditingController(text: '5.0');
  final _shippingInsuranceCtrl = TextEditingController(text: '1.5');
  final _returnRateCtrl = TextEditingController(text: '15.0');
  final _promoFeeCtrl = TextEditingController(text: '10.0');

  // 当前实时计算对象
  ProfitRecord? _currentRecord;

  // 互动推演沙盘折叠状态
  bool _isSandboxExpanded = true;

  // 平台常见参考预设
  static const Map<String, Map<String, double>> platformDefaults = {
    '淘宝/天猫': {
      'commission': 5.0,
      'insurance': 1.5,
      'returnRate': 15.0,
      'express': 3.5,
      'pack': 1.5,
    },
    '拼多多': {
      'commission': 1.0,
      'insurance': 1.0,
      'returnRate': 20.0,
      'express': 3.0,
      'pack': 1.2,
    },
    '抖音': {
      'commission': 3.0,
      'insurance': 2.0,
      'returnRate': 25.0,
      'express': 3.8,
      'pack': 1.5,
    },
    '自定义': {
      'commission': 0.0,
      'insurance': 0.0,
      'returnRate': 0.0,
      'express': 0.0,
      'pack': 0.0,
    },
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialRecord != null) {
      loadRecord(widget.initialRecord!);
    } else {
      _recalculate();
    }
  }

  void loadRecord(ProfitRecord record) {
    setState(() {
      _selectedPlatform = record.platform;
      _nameCtrl.text = record.productName;
      _sellingPriceCtrl.text = record.sellingPrice > 0 ? record.sellingPrice.toStringAsFixed(2) : '';
      _costPriceCtrl.text = record.costPrice > 0 ? record.costPrice.toStringAsFixed(2) : '';
      _expressFeeCtrl.text = record.expressFee > 0 ? record.expressFee.toStringAsFixed(2) : '';
      _packFeeCtrl.text = record.packFee > 0 ? record.packFee.toStringAsFixed(2) : '';
      _commissionRateCtrl.text = record.commissionRate.toStringAsFixed(1);
      _shippingInsuranceCtrl.text = record.shippingInsurance > 0 ? record.shippingInsurance.toStringAsFixed(2) : '';
      _returnRateCtrl.text = record.returnRate.toStringAsFixed(1);
      _promoFeeCtrl.text = record.promoFee > 0 ? record.promoFee.toStringAsFixed(2) : '';
      _recalculate();
    });
  }

  void _switchPlatform(String platform) {
    if (_selectedPlatform == platform) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPlatform = platform;
      final defaults = platformDefaults[platform];
      if (defaults != null) {
        if (platform != '自定义') {
          _commissionRateCtrl.text = defaults['commission']!.toStringAsFixed(1);
          _shippingInsuranceCtrl.text = defaults['insurance']!.toStringAsFixed(2);
          _returnRateCtrl.text = defaults['returnRate']!.toStringAsFixed(1);
          _expressFeeCtrl.text = defaults['express']!.toStringAsFixed(2);
          _packFeeCtrl.text = defaults['pack']!.toStringAsFixed(2);
        }
      }
      _recalculate();
    });
  }

  double _parse(TextEditingController ctrl) {
    return double.tryParse(ctrl.text.trim()) ?? 0.0;
  }

  void _recalculate() {
    final record = ProfitRecord(
      id: _currentRecord?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      productName: _nameCtrl.text.trim(),
      platform: _selectedPlatform,
      sellingPrice: _parse(_sellingPriceCtrl),
      costPrice: _parse(_costPriceCtrl),
      expressFee: _parse(_expressFeeCtrl),
      packFee: _parse(_packFeeCtrl),
      commissionRate: _parse(_commissionRateCtrl),
      shippingInsurance: _parse(_shippingInsuranceCtrl),
      returnRate: _parse(_returnRateCtrl),
      promoFee: _parse(_promoFeeCtrl),
      createdAt: DateTime.now(),
    );

    setState(() {
      _currentRecord = record;
    });

    widget.onRecordChanged?.call(record);
  }

  Future<void> _saveRecord() async {
    if (_currentRecord == null) return;
    HapticFeedback.mediumImpact();

    final toSave = ProfitRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productName: _nameCtrl.text.trim().isEmpty ? '未命名商品' : _nameCtrl.text.trim(),
      platform: _selectedPlatform,
      sellingPrice: _parse(_sellingPriceCtrl),
      costPrice: _parse(_costPriceCtrl),
      expressFee: _parse(_expressFeeCtrl),
      packFee: _parse(_packFeeCtrl),
      commissionRate: _parse(_commissionRateCtrl),
      shippingInsurance: _parse(_shippingInsuranceCtrl),
      returnRate: _parse(_returnRateCtrl),
      promoFee: _parse(_promoFeeCtrl),
      createdAt: DateTime.now(),
    );

    await StorageService.saveRecord(toSave);
    widget.onSaved?.call();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('方案已成功保存到本地历史记录！'),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _copyBill() {
    if (_currentRecord == null) return;
    HapticFeedback.lightImpact();
    final bill = _currentRecord!.toShareableBill();
    Clipboard.setData(ClipboardData(text: bill));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.content_copy_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('精美账单已复制，可直接发送微信！'),
          ],
        ),
        backgroundColor: const Color(0xFF0284C7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rec = _currentRecord;

    return Scaffold(
      appBar: AppBar(
        title: const Text('少伟利润通'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '一键复制微信账单',
            icon: const Icon(Icons.share_outlined),
            onPressed: _copyBill,
          ),
          IconButton(
            tooltip: '保存当前方案',
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: _saveRecord,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. 经营平台快捷选择
            Container(
              padding: const EdgeInsets.all(12),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '经营平台预设',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      if (rec != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: platformDefaults.keys.map((platform) {
                      final isSelected = _selectedPlatform == platform;
                      return ChoiceChip(
                        label: Text(platform),
                        selected: isSelected,
                        selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF059669)
                              : (isDark ? Colors.grey[300] : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (_) => _switchPlatform(platform),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. 成本与利润构成全景环形图 (fl_chart)
            if (rec != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ProfitPieChart(record: rec, isDark: isDark),
              ),
            const SizedBox(height: 14),

            // 3. 核心经营指标卡片网格
            if (rec != null) ...[
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: '真实单笔净利',
                      value: '¥${rec.realNetProfit.toStringAsFixed(2)}',
                      subtitle: '已扣退货损耗与广告',
                      valueColor: rec.healthColor,
                      icon: Icons.savings_outlined,
                      iconColor: rec.healthColor,
                      isHighlight: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricCard(
                      title: '真实净利率',
                      value: '${rec.netMargin.toStringAsFixed(1)}%',
                      subtitle: rec.healthBadgeText,
                      valueColor: rec.healthColor,
                      icon: Icons.pie_chart_outline_rounded,
                      iconColor: rec.healthColor,
                      isHighlight: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: '单笔基础毛利',
                      value: '¥${rec.grossProfit.toStringAsFixed(2)}',
                      subtitle: '毛利率: ${rec.grossMargin.toStringAsFixed(1)}%',
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricCard(
                      title: '保本投产比 (ROI)',
                      value: rec.breakevenRoi > 0 ? rec.breakevenRoi.toStringAsFixed(2) : '不可保本',
                      subtitle: rec.breakevenRoi > 0 ? '推广ROI高于此即盈利' : '成本倒挂',
                      icon: Icons.track_changes_rounded,
                      valueColor: rec.breakevenRoi > 0 ? const Color(0xFF0284C7) : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),

            // 4. 【可折叠的互动推演沙盘】
            _buildInteractiveSandbox(isDark, rec),
            const SizedBox(height: 14),

            // 5. 详细参数输入表单
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '基础经营参数输入',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _nameCtrl.clear();
                          _sellingPriceCtrl.text = '99.0';
                          _costPriceCtrl.text = '35.0';
                          _recalculate();
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 14),
                        label: const Text('重置数值', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildTextInput(
                    controller: _nameCtrl,
                    label: '商品名称 / 款号 (选填)',
                    hint: '例如: 夏季透气运动速干T恤',
                    icon: Icons.label_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberInput(
                          controller: _sellingPriceCtrl,
                          label: '销售标价',
                          prefix: '¥',
                          suffix: '元',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildNumberInput(
                          controller: _costPriceCtrl,
                          label: '拿货成本',
                          prefix: '¥',
                          suffix: '元',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberInput(
                          controller: _expressFeeCtrl,
                          label: '发货快递费',
                          prefix: '¥',
                          suffix: '元',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildNumberInput(
                          controller: _packFeeCtrl,
                          label: '包材与人工',
                          prefix: '¥',
                          suffix: '元',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberInput(
                          controller: _commissionRateCtrl,
                          label: '平台扣点比例',
                          suffix: '%',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildNumberInput(
                          controller: _shippingInsuranceCtrl,
                          label: '单笔运费险',
                          prefix: '¥',
                          suffix: '元',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberInput(
                          controller: _returnRateCtrl,
                          label: '预估退货率',
                          suffix: '%',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildNumberInput(
                          controller: _promoFeeCtrl,
                          label: '单单推广花费',
                          prefix: '¥',
                          suffix: '元',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 6. 底部快捷操作按钮组
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: _saveRecord,
                    icon: const Icon(Icons.bookmark_added_rounded),
                    label: const Text('保存测算方案'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: _copyBill,
                    icon: const Icon(Icons.content_copy_rounded, size: 16),
                    label: const Text('一键复制'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- 互动推演沙盘组件 ---
  Widget _buildInteractiveSandbox(bool isDark, ProfitRecord? rec) {
    final double sellingPrice = _parse(_sellingPriceCtrl);
    final double returnRate = _parse(_returnRateCtrl);
    final double promoFee = _parse(_promoFeeCtrl);

    // 售价滑块区间：基于当前售价的 0.5 ~ 2.0 倍
    final double minPrice = max(5.0, (sellingPrice * 0.5).roundToDouble());
    final double maxPrice = max(50.0, (sellingPrice * 1.8).roundToDouble());
    final double currentSliderPrice = sellingPrice.clamp(minPrice, maxPrice);

    final double maxPromoLimit = max(50.0, sellingPrice > 0 ? sellingPrice * 0.6 : 50.0);
    final double currentPromo = promoFee.clamp(0.0, maxPromoLimit);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0284C7).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // 标题与折叠开关
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isSandboxExpanded = !_isSandboxExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.tune_rounded, color: Color(0xFF0284C7), size: 18),
                      SizedBox(width: 8),
                      Text(
                        "🎛️ 互动推演沙盘",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        "(拖动滑块实时推演)",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  Icon(
                    _isSandboxExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_isSandboxExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 1. 售价微调滑块
                  _buildSliderRow(
                    label: "售价微调",
                    valueText: "¥${sellingPrice.toStringAsFixed(1)}",
                    min: minPrice,
                    max: maxPrice,
                    current: currentSliderPrice,
                    activeColor: const Color(0xFF059669),
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      _sellingPriceCtrl.text = val.toStringAsFixed(1);
                      _recalculate();
                    },
                  ),
                  const SizedBox(height: 14),

                  // 2. 退货率 (0% ~ 50%) 滑块
                  _buildSliderRow(
                    label: "预估退货率",
                    valueText: "${returnRate.toStringAsFixed(1)}%",
                    min: 0.0,
                    max: 50.0,
                    current: returnRate.clamp(0.0, 50.0),
                    activeColor: const Color(0xFFF43F5E),
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      _returnRateCtrl.text = val.toStringAsFixed(1);
                      _recalculate();
                    },
                  ),
                  const SizedBox(height: 14),

                  // 3. 单均推广费滑块
                  _buildSliderRow(
                    label: "单均推广费",
                    valueText: "¥${promoFee.toStringAsFixed(1)}",
                    min: 0.0,
                    max: maxPromoLimit,
                    current: currentPromo,
                    activeColor: const Color(0xFFEAB308),
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      _promoFeeCtrl.text = val.toStringAsFixed(1);
                      _recalculate();
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueText,
    required double min,
    required double max,
    required double current,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(
              valueText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: activeColor,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: activeColor,
            thumbColor: activeColor,
            overlayColor: activeColor.withOpacity(0.15),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: current,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: (_) => _recalculate(),
    );
  }

  Widget _buildNumberInput({
    required TextEditingController controller,
    required String label,
    String? prefix,
    String? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix != null ? '$prefix ' : null,
        suffixText: suffix != null ? ' $suffix' : null,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: (_) => _recalculate(),
    );
  }
}
