import 'package:flutter/material.dart';
import '../models/profit_record.dart';
import '../services/storage_service.dart';

class HistoryPage extends StatefulWidget {
  final Function(ProfitRecord record)? onSelectRecord;

  const HistoryPage({super.key, this.onSelectRecord});

  @override
  State<HistoryPage> createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage> {
  List<ProfitRecord> _allRecords = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedPlatform = '全部';

  final List<String> _platforms = ['全部', '淘宝/天猫', '拼多多', '抖音', '自定义'];

  @override
  void initState() {
    super.initState();
    refreshRecords();
  }

  Future<void> refreshRecords() async {
    setState(() => _isLoading = true);
    final list = await StorageService.getRecords();
    setState(() {
      _allRecords = list;
      _isLoading = false;
    });
  }

  Future<void> _deleteRecord(ProfitRecord record) async {
    await StorageService.deleteRecord(record.id);
    await refreshRecords();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已删除: ${record.productName.isEmpty ? "未命名商品" : record.productName}'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () async {
            await StorageService.saveRecord(record);
            await refreshRecords();
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  List<ProfitRecord> get _filteredRecords {
    return _allRecords.where((item) {
      final matchesPlatform = _selectedPlatform == '全部' || item.platform == _selectedPlatform;
      final matchesQuery = _searchQuery.isEmpty ||
          item.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.platform.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesPlatform && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('历史测算方案'),
        elevation: 0,
        actions: [
          if (_allRecords.isNotEmpty)
            IconButton(
              tooltip: '清空历史',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('确认清空所有历史？'),
                    content: const Text('清空后数据无法恢复，请谨慎操作。'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('清空'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await StorageService.clearAll();
                  await refreshRecords();
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // 搜索与筛选区域
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: '搜索商品名称或平台...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _platforms.map((p) {
                      final isSelected = _selectedPlatform == p;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(p),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedPlatform = p),
                          selectedColor: theme.colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 列表视图
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecords.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredRecords.length,
                        itemBuilder: (context, index) {
                          final item = _filteredRecords[index];
                          return _buildDismissibleItem(item, theme);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.colorScheme.outline.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _allRecords.isEmpty ? '暂无历史测算记录' : '未找到符合条件的方案',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _allRecords.isEmpty
                  ? '在「利润测算」页面点击右上角或底部的保存方案，即可在此随时回填与对比！'
                  : '请尝试更换搜索词或筛选标签',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissibleItem(ProfitRecord item, ThemeData theme) {
    final isPositive = item.realNetProfit >= 0;
    final profitColor = isPositive ? Colors.teal.shade700 : Colors.red.shade700;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 24),
            SizedBox(width: 6),
            Text('左滑删除', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      onDismissed: (_) => _deleteRecord(item),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.6)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            widget.onSelectRecord?.call(item);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已回填方案: ${item.productName.isEmpty ? "未命名商品" : item.productName}'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.productName.isEmpty ? '未命名商品' : item.productName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.platform,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '售价: ¥${item.sellingPrice.toStringAsFixed(2)} | 成本: ¥${item.costPrice.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                    Row(
                      children: [
                        Text(
                          '净利: ',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                        ),
                        Text(
                          '¥${item.realNetProfit.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: profitColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '退货率: ${item.returnRate.toStringAsFixed(1)}% | 扣点: ${item.commissionRate.toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontSize: 11),
                    ),
                    Text(
                      '保本ROI: ${item.breakevenRoi > 0 ? item.breakevenRoi.toStringAsFixed(2) : "不可保本"}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item.breakevenRoi > 0 ? Colors.indigo.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
