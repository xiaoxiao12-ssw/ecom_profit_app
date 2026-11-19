import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    HapticFeedback.mediumImpact();
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
    final isDark = theme.brightness == Brightness.dark;

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
                    content: const Text('清空后本地测算数据将彻底清除。'),
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
          // 搜索与平台筛选栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: '搜索历史商品名称或平台...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _platforms.map((p) {
                      final isSelected = _selectedPlatform == p;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(p, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          selected: isSelected,
                          selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                          onSelected: (_) => setState(() => _selectedPlatform = p),
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
                          return _buildDismissibleItem(item, isDark);
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
                  ? '在「利润测算」页面点击保存方案，即可在此随时回填重新编辑！'
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

  Widget _buildDismissibleItem(ProfitRecord item, bool isDark) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onSelectRecord?.call(item);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已回填方案「${item.productName.isEmpty ? "未命名商品" : item.productName}」到测算器'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.platform,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.productName.isEmpty ? '未命名商品' : item.productName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.healthBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.healthBadgeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: item.healthColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _dataCol("售价", "¥${item.sellingPrice.toStringAsFixed(1)}", isDark),
                    _dataCol("拿货成本", "¥${item.costPrice.toStringAsFixed(1)}", isDark),
                    _dataCol("真实净利", "¥${item.realNetProfit.toStringAsFixed(1)}", isDark, color: item.healthColor),
                    _dataCol("净利率", "${item.netMargin.toStringAsFixed(1)}%", isDark, color: item.healthColor),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "保本 ROI: ${item.breakevenRoi > 0 ? item.breakevenRoi.toStringAsFixed(2) : '不可保本'} · 退货损耗: ¥${item.returnLossPerOrder.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    Text(
                      "${item.createdAt.month}-${item.createdAt.day} ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}",
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[500] : Colors.grey[500]),
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

  Widget _dataCol(String label, String val, bool isDark, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}
