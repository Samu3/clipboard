import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:unique_health/core/locale/utils/translation_helper.dart';
import 'package:unique_health/core/theme/app_colors.dart';
import 'package:unique_health/core/widgets/custom_app_bar.dart';
import '../domain/entities/water_record.dart';
import '../providers/water_provider.dart';

class WaterRecordPage extends ConsumerWidget {
  const WaterRecordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRecords = ref.watch(waterAllRecordTotalsProvider);

    return Scaffold(
      body: asyncRecords.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text("错误:$e")),
        data: (records) {
          // 按日期分组
          final groupedRecords = _groupRecordsByDate(records);

          return Container(
            color: context.color.bg_gray,
            child: Column(
              children: [
                CustomAppBar(title: ref.tr("QUAN_BU_JI_LU", tag: "全部记录")),
                Expanded(
                  child: groupedRecords.isEmpty
                      ? Center(
                          child: Text(
                            ref.tr("ZAN_WU_SHU_JU", tag: "暂无数据"),
                            style: TextStyle(
                              color: context.color.black06,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: groupedRecords.length + 1,
                          itemBuilder: (context, index) {
                            // 最后一项显示"没有更多数据"
                            if (index == groupedRecords.length) {
                              return Container(
                                margin: const EdgeInsets.all(20),
                                child: Center(
                                  child: Text(
                                    ref.tr("MEI_YOU_GENG_DUO", tag: "没有更多数据了"),
                                    style: TextStyle(
                                      color: context.color.black06,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final dateGroup = groupedRecords[index];
                            final date = dateGroup['date'] as String;
                            final records =
                                dateGroup['records'] as List<WaterRecord>;

                            return _buildDateGroup(context, ref, date, records);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建分组后的列表（转换为 List 以便 ListView 使用）
  List<Map<String, dynamic>> _groupRecordsByDate(List<WaterRecord> records) {
    final Map<String, List<WaterRecord>> grouped = {};

    for (var record in records) {
      final dateKey = DateFormat('yyyy-MM-dd').format(record.drinkAt);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(record);
    }

    // 转换为 List 并按日期倒序排列
    final result = grouped.entries.map((entry) {
      return {
        'date': entry.key,
        'records': entry.value,
      };
    }).toList();

    result.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

    return result;
  }

  /// 构建日期分组
  Widget _buildDateGroup(
    BuildContext context,
    WidgetRef ref,
    String date,
    List<WaterRecord> records,
  ) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期标题
          Text(
            _formatDate(date),
            style: TextStyle(
              color: context.color.black06,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          // 该日期下的所有记录
          ...records.map((record) => _buildRecordItem(context, ref, record)),
        ],
      ),
    );
  }

  /// 构建单条记录
  Widget _buildRecordItem(
    BuildContext context,
    WidgetRef ref,
    WaterRecord record,
  ) {
    return Slidable(
      key: ValueKey(record.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.22,
        children: [
          CustomSlidableAction(
            onPressed: (_) {
              ref.read(waterNotifierProvider.notifier).delete(record.id);
            },
            backgroundColor: const Color(0xFFFF4D4F),
            borderRadius: BorderRadius.circular(12),
            padding: EdgeInsets.zero,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, color: Colors.white, size: 22),
              ],
            ),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 6, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: ShapeDecoration(
          color: context.color.white100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.tr("HE_SHUI", tag: "喝水"),
                  style: TextStyle(
                    color: context.color.black10,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(record.drinkAt),
                  style: TextStyle(
                    color: context.color.black06,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${record.ml}',
                  style: TextStyle(
                    height: 1,
                    color: context.color.black10,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  'ml',
                  style: TextStyle(
                    height: 1.5,
                    color: context.color.black10,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  /// 格式化日期显示
  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
