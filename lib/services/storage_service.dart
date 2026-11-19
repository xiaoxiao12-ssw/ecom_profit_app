import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profit_record.dart';

class StorageService {
  static const String _storageKey = 'ecom_profit_records_v1';

  /// 获取所有保存的历史测算记录（绝无任何预置虚假数据，初始必为空列表）
  static Future<List<ProfitRecord>> getRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey);
    if (jsonList == null || jsonList.isEmpty) {
      return [];
    }

    try {
      return jsonList
          .map((item) => ProfitRecord.fromJson(item))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      return [];
    }
  }

  /// 保存或更新一条记录
  static Future<bool> saveRecord(ProfitRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getRecords();

    final existingIndex = records.indexWhere((r) => r.id == record.id);
    if (existingIndex >= 0) {
      records[existingIndex] = record;
    } else {
      records.insert(0, record);
    }

    final jsonList = records.map((r) => r.toJson()).toList();
    return prefs.setStringList(_storageKey, jsonList);
  }

  /// 删除一条记录
  static Future<bool> deleteRecord(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getRecords();
    records.removeWhere((r) => r.id == id);
    final jsonList = records.map((r) => r.toJson()).toList();
    return prefs.setStringList(_storageKey, jsonList);
  }

  /// 清空所有历史记录
  static Future<bool> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_storageKey);
  }
}
