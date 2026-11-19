import 'package:flutter/material.dart';
import '../models/profit_record.dart';

class ComparisonPage extends StatefulWidget {
  final ProfitRecord? baseRecord;

  const ComparisonPage({super.key, this.baseRecord});

  @override
  State<ComparisonPage> createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> {
  // 基础成本参数 (继承自测算或默认值)
  final _costCtrl = TextEditingController(text: '35.0');
  final _expressCtrl = TextEditingController(text: '3.5');
  final _packCtrl = TextEditingController(text: '1.5');
  final _commissionCtrl = TextEditingController(text: '5.0');
  final _insuranceCtrl = TextEditingController(text: '1.5');
  final _returnRateCtrl = TextEditingController(text: '15.0');
  final _promoCtrl = TextEditingController(text: '10.0');

  // 三个定价方案
  final _planAName = '日常标价';
  final _planAPriceCtrl = TextEditingController(text: '99.0');

  final _planBName = '大促活动价';
  final _planBPriceCtrl = TextEditingController(text: '79.0');

  final _planCName = '秒杀冲量价';
  final _planCPriceCtrl = TextEditingController(text: '59.0');

  @override
  void initState() {
    super.initState();
    if (widget.baseRecord != null) {
      final b = widget.baseRecord!;
      _costCtrl.text = b.costPrice.toStringAsFixed(2);
      _expressCtrl.text = b.expressFee.toStringAsFixed(2);
      _packCtrl.text = b.packFee.toStringAsFixed(2);
      _commissionCtrl.text = b.commissionRate.toStringAsFixed(1);
      _insuranceCtrl.text = b.shippingInsurance.toStringAsFixed(2);
      _returnRateCtrl.text = b.returnRate.toStringAsFixed(1);
      _promoCtrl.text = b.promoFee.toStringAsFixed(2);

      if (b.sellingPrice > 0) {
        _planAPriceCtrl.text = b.sellingPrice.toStringAsFixed(2);
        _planBPriceCtrl.text = (b.sellingPrice * 0.85).toStringAsFixed(2);
        _planCPriceCtrl.text = (b.sellingPrice * 0.70).toStringAsFixed(2);
      }
    }
  }

  double _val(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0.0;

  ProfitRecord _calculateForPrice(String planName, double price) {
    return ProfitRecord(
      id: planName,
      productName: planName,
      platform: '定价对比',
      sellingPrice: price,
      costPrice: _val(_costCtrl),
      expressFee: _val(_expressCtrl),
      packFee: _val(_packCtrl),
      commissionRate: _val(_commissionCtrl),
      shippingInsurance: _val(_insuranceCtrl),
      returnRate: _val(_returnRateCtrl),
      promoFee: _val(_promoCtrl),
      createdAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final recA = _calculateForPrice(_planAName, _val(_planAPriceCtrl));
    final recB = _calculateForPrice(_planBName, _val(_planBPriceCtrl));
    final recC = _calculateForPrice(_planCName, _val(_planCPriceCtrl));

    return Scaffold(
      appBar: AppBar(
        title: const Text('多阶梯定价收益对比'),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 提示栏
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '在相同成本结构下，对比不同售价区间的净利润与保本ROI，辅助确定最优大促定价。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 三个方案卡片
            _buildPlanCard(
              context: context,
              title: _planAName,
              badge: '高毛利方案',
              badgeColor: Colors.teal,
              priceCtrl: _planAPriceCtrl,
              record: recA,
            ),
            const SizedBox(height: 14),

            _buildPlanCard(
              context: context,
              title: _planBName,
              badge: '走量主力方案',
              badgeColor: Colors.indigo,
              priceCtrl: _planBPriceCtrl,
              record: recB,
            ),
            const SizedBox(height: 14),

            _buildPlanCard(
              context: context,
              title: _planCName,
              badge: '引流清仓方案',
              badgeColor: Colors.orange.shade800,
              priceCtrl: _planCPriceCtrl,
              record: recC,
            ),
            const SizedBox(height: 20),

            // 折叠面板：微调基础成本
            ExpansionTile(
              initiallyExpanded: false,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.25),
              collapsedBackgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.25),
              title: Text(
                '调整底层通用成本参数',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '拿货成本 ¥${_costCtrl.text} · 快递 ¥${_expressCtrl.text} · 退货率 ${_returnRateCtrl.text}%',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
              childrenPadding: const EdgeInsets.all(12),
              children: [
                Row(
                  children: [
                    Expanded(child: _miniInput(_costCtrl, '拿货成本(元)')),
                    const SizedBox(width: 8),
                    Expanded(child: _miniInput(_expressCtrl, '发货快递(元)')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _miniInput(_packCtrl, '包材人工(元)')),
                    const SizedBox(width: 8),
                    Expanded(child: _miniInput(_commissionCtrl, '平台扣点(%)')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _miniInput(_insuranceCtrl, '运费险(元)')),
                    const SizedBox(width: 8),
                    Expanded(child: _miniInput(_returnRateCtrl, '退货率(%)')),
                  ],
                ),
                const SizedBox(height: 8),
                _miniInput(_promoCtrl, '单单推广花费(元)'),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required String badge,
    required Color badgeColor,
    required TextEditingController priceCtrl,
    required ProfitRecord record,
  }) {
    final theme = Theme.of(context);
    final isPositive = record.realNetProfit >= 0;
    final statusColor = isPositive ? Colors.teal.shade700 : Colors.red.shade700;

    String healthTag;
    Color healthColor;
    if (record.realNetProfit <= 0) {
      healthTag = '成本倒挂亏损';
      healthColor = Colors.red.shade700;
    } else if (record.netMargin < 8.0) {
      healthTag = '薄利冲量';
      healthColor = Colors.orange.shade800;
    } else if (record.netMargin < 20.0) {
      healthTag = '健康盈利';
      healthColor = Colors.teal.shade700;
    } else {
      healthTag = '超高暴利';
      healthColor = Colors.purple.shade700;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: healthColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  healthTag,
                  style: TextStyle(color: healthColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 价格输入行
          Row(
            children: [
              const Text('拟定售价：', style: TextStyle(fontWeight: FontWeight.w500)),
              Expanded(
                child: TextFormField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixText: '¥ ',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // 指标对比行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricItem(
                label: '真实净利润',
                val: '¥${record.realNetProfit.toStringAsFixed(2)}',
                color: statusColor,
                isBold: true,
              ),
              _metricItem(
                label: '净利率',
                val: '${record.netMargin.toStringAsFixed(1)}%',
                color: statusColor,
              ),
              _metricItem(
                label: '单笔毛利',
                val: '¥${record.grossProfit.toStringAsFixed(2)}',
                color: theme.colorScheme.onSurface,
              ),
              _metricItem(
                label: '保本 ROI',
                val: record.breakevenRoi > 0 ? record.breakevenRoi.toStringAsFixed(2) : '无法保本',
                color: record.breakevenRoi > 0 ? Colors.indigo.shade700 : Colors.red.shade700,
                isBold: record.breakevenRoi > 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricItem({
    required String label,
    required String val,
    required Color color,
    bool isBold = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 3),
        Text(
          val,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _miniInput(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
