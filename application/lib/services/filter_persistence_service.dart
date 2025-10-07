import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 筛选持久化服务
class FilterPersistenceService {
  static const String _filterPresetsKey = 'filter_presets';
  static const String _lastUsedFiltersKey = 'last_used_filters';
  static const int _maxPresets = 10;

  /// 保存筛选预设
  Future<void> saveFilterPreset(String name, Map<String, dynamic> filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = prefs.getString(_filterPresetsKey) ?? '{}';
      final presets = Map<String, dynamic>.from(json.decode(presetsJson));
      
      presets[name] = {
        'filters': filters,
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      // 限制预设数量
      if (presets.length > _maxPresets) {
        final sortedEntries = presets.entries.toList()
          ..sort((a, b) => DateTime.parse(a.value['createdAt'])
              .compareTo(DateTime.parse(b.value['createdAt'])));
        
        // 删除最旧的预设
        for (int i = 0; i < presets.length - _maxPresets; i++) {
          presets.remove(sortedEntries[i].key);
        }
      }
      
      await prefs.setString(_filterPresetsKey, json.encode(presets));
    } catch (e) {
      print('Error saving filter preset: $e');
    }
  }

  /// 获取所有筛选预设
  Future<Map<String, Map<String, dynamic>>> getFilterPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = prefs.getString(_filterPresetsKey) ?? '{}';
      final presets = Map<String, dynamic>.from(json.decode(presetsJson));
      
      return presets.map((key, value) => MapEntry(
        key,
        Map<String, dynamic>.from(value['filters']),
      ));
    } catch (e) {
      print('Error getting filter presets: $e');
      return {};
    }
  }

  /// 删除筛选预设
  Future<void> deleteFilterPreset(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = prefs.getString(_filterPresetsKey) ?? '{}';
      final presets = Map<String, dynamic>.from(json.decode(presetsJson));
      
      presets.remove(name);
      await prefs.setString(_filterPresetsKey, json.encode(presets));
    } catch (e) {
      print('Error deleting filter preset: $e');
    }
  }

  /// 保存最后使用的筛选条件
  Future<void> saveLastUsedFilters(Map<String, dynamic> filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUsedFiltersKey, json.encode(filters));
    } catch (e) {
      print('Error saving last used filters: $e');
    }
  }

  /// 获取最后使用的筛选条件
  Future<Map<String, dynamic>?> getLastUsedFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filtersJson = prefs.getString(_lastUsedFiltersKey);
      if (filtersJson != null) {
        return Map<String, dynamic>.from(json.decode(filtersJson));
      }
    } catch (e) {
      print('Error getting last used filters: $e');
    }
    return null;
  }

  /// 清除所有筛选数据
  Future<void> clearAllFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_filterPresetsKey);
      await prefs.remove(_lastUsedFiltersKey);
    } catch (e) {
      print('Error clearing all filters: $e');
    }
  }
}
