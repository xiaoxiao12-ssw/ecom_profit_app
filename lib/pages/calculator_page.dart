import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/profit_record.dart';
import '../services/storage_service.dart';
import '../widgets/metric_card.dart';

class CalculatorPage extends StatefulWidget {
  final ProfitRecord? initialRecord;
  final VoidCallback? onSaved;

  const CalculatorPage({
    super.key,
    this.initialRecord,
    this.onSaved,
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
    setState(() {
      _selectedPlatform = platform;
      final defaults = platformDefaults[platform];
      if (defaults != null) {
        _commissionRateCtrl.text = defaults['commission']!.toStringAsFixed(1);
        _shippingInsuranceCtrl.text = defaults['insurance']!.toStringAsFixed(2);
        _returnRateCtrl.text = defaults['returnRate']!.toStringAsFixed(1);
        if (_expressFeeCtrl.text.isEmpty || _expressFeeCtrl.text == '0' || _expressFeeCtrl.text == '0.0') {
          _expressFeeCtrl.text = defaults['express']!.toStringAsFixed(2);
        }
        if (_packFeeCtrl.text.isEmpty || _packFeeCtrl.text == '0' || _packFeeCtrl.text == '0.0') {
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
      id: widget.initialRecord?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
  }

  Future<void> _saveRecord() async {
    if (_currentRecord == null) return;
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
        backgroundColor: Colors.teal.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _copyBill() {
    if (_currentRecord == null) return;
    final bill = _currentRecord!.toShareableBill();
    Clipboard.setData(ClipboardData(text: bill));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.content_copy_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('测算账单已复制到剪贴板，可直接发送！'),
          ],
        ),
        backgroundColor: Colors.indigo.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rec = _currentRecord;

    final isProfitPositive = rec != null && rec.realNetProfit >= 0;
    final profitColor = isProfitPositive ? const Color(0xFF059669) : Colors.redAccent.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('电商成本与利润测算'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '一键复制账单',
            icon: const Icon(Icons.share_outlined),
            onPressed: _copyBill,
          ),
          IconButton(
            tooltip: '保存方案',
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
            // 1. 平台快捷标签切换
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '经营平台',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
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
                          onSelected: (_) => _switchPlatform(platform),
                          selectedColor: theme.colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. 核心指标高亮大卡片 (实时收益面板)
            if (rec != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isProfitPositive
                        ? [Colors.teal.shade50, Colors.teal.shade100.withOpacity(0.4)]
                        : [Colors.red.shade50, Colors.red.shade100.withOpacity(0.4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isProfitPositive ? Colors.teal.shade200 : Colors.red.shade200,
                    width: 1.2,
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
                            Icon(
                              isProfitPositive ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                              color: isProfitPositive ? Colors.teal.shade800 : Colors.red.shade800,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '真实单单净利润 (计退货损耗)',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: isProfitPositive ? Colors.teal.shade900 : Colors.red.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isProfitPositive ? Colors.teal.shade800 : Colors.red.shade800,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '净利率 ${rec.netMargin.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '¥',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isProfitPositive ? Colors.teal.shade900 : Colors.red.shade900,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rec.realNetProfit.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: isProfitPositive ? Colors.teal.shade900 : Colors.red.shade900,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // 次级关键指标网格
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: constraints.maxWidth > 500 ? 3 : 2,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          children: [
                            MetricCard(
                              title: '单笔基础毛利',
                              value: '¥${rec.grossProfit.toStringAsFixed(2)}',
                              subtitle: '毛利率 ${rec.grossMargin.toStringAsFixed(1)}%',
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                            MetricCard(
                              title: '保本投产比 (ROI)',
                              value: rec.breakevenRoi > 0
                                  ? rec.breakevenRoi.toStringAsFixed(2)
                                  : '不可保本',
                              subtitle: rec.breakevenRoi > 0
                                  ? '广告ROI高于此值即盈利'
                                  : '毛利不足覆盖运费',
                              valueColor: rec.breakevenRoi > 0 ? Colors.indigo.shade800 : Colors.red.shade700,
                              icon: Icons.track_changes_rounded,
                              isHighlight: true,
                            ),
                            MetricCard(
                              title: '单单平台扣点',
                              value: '¥${rec.commissionAmount.toStringAsFixed(2)}',
                              subtitle: '比例 ${rec.commissionRate.toStringAsFixed(1)}%',
                              icon: Icons.pie_chart_outline_rounded,
                            ),
                            MetricCard(
                              title: '最大可承受广告费',
                              value: rec.maxAllowableAdSpend > 0
                                  ? '¥${rec.maxAllowableAdSpend.toStringAsFixed(2)}'
                                  : '¥0.00',
                              subtitle: '单单推广费上限',
                              icon: Icons.campaign_outlined,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 3. 详细参数表单
            Text(
              '测算参数输入',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // 商品名称
            _buildTextField(
              controller: _nameCtrl,
              label: '商品名称',
              hint: '例如: 夏季透气T恤 (选填)',
              icon: Icons.shopping_bag_outlined,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 10),

            // 售价与成本 (一行两列)
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _sellingPriceCtrl,
                    label: '销售定价',
                    suffix: '元',
                    icon: Icons.sell_outlined,
                    isNumeric: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    controller: _costPriceCtrl,
                    label: '拿货成本',
                    suffix: '元',
                    icon: Icons.inventory_2_outlined,
                    isNumeric: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 快递与包材
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _expressFeeCtrl,
                    label: '发货快递费',
                    suffix: '元',
                    icon: Icons.local_shipping_outlined,
                    isNumeric: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    controller: _packFeeCtrl,
                    label: '包材人工费',
                    suffix: '元',
                    icon: Icons.archive_outlined,
                    isNumeric: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 平台扣点与运费险
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _commissionRateCtrl,
                    label: '平台扣点比例',
                    suffix: '%',
                    icon: Icons.percent_outlined,
                    isNumeric: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    controller: _shippingInsuranceCtrl,
                    label: '运费险费',
                    suffix: '元/单',
                    icon: Icons.health_and_safety_outlined,
                    isNumeric: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 预估退货率与单单推广费
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _returnRateCtrl,
                    label: '预估退货率',
                    suffix: '%',
                    icon: Icons.replay_circle_filled_outlined,
                    isNumeric: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    controller: _promoFeeCtrl,
                    label: '单单推广花费',
                    suffix: '元/单',
                    icon: Icons.campaign_outlined,
                    isNumeric: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 4. 底部快捷操作按钮
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _copyBill,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('复制账单'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _saveRecord,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('保存到历史记录'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? suffix,
    IconData? icon,
    bool isNumeric = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType ?? (isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text),
      onChanged: (_) => _recalculate(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: icon != null ? Icon(icon, size: 19) : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}


