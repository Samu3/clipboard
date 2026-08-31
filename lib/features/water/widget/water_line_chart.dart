import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:unique_health/core/theme/app_colors.dart';
import 'package:unique_health/core/locale/utils/translation_helper.dart';
import 'package:unique_health/features/water/providers/water_provider.dart';
import 'package:intl/intl.dart';

class WaterLineChart extends ConsumerStatefulWidget {
  const WaterLineChart({super.key});

  @override
  ConsumerState<WaterLineChart> createState() => _WaterLineChartState();
}

class _WaterLineChartState extends ConsumerState<WaterLineChart> {
  // 选中索引（自动选中最后一条数据）
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    // 获取最近7天的每日总量数据
    final asyncDailyTotals = ref.watch(waterDailyTotalsProvider(days: 7));

    return asyncDailyTotals.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('加载失败: $e')),
      data: (dailyTotals) {
        // 构建最近7天的数据
        final dailyData = _buildDailyData(dailyTotals);

        if (dailyData.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset("assets/images/drink/ic_drink_empty.svg"),
                Text(ref.tr("ZAN_WU_SHU_JU", tag: "暂无数据"))
              ],
            ),
          );
        }

        // 自动选中最后一条数据
        touchedIndex ??= dailyData.length - 1;

        // 构建图表数据点
        final dataSpots = dailyData.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value['total'].toDouble());
        }).toList();

        // X轴日期标签
        final xLabels =
            dailyData.map((data) => data['label'] as String).toList();

        // 计算 Y 轴最大值（向上取整到500的倍数）
        final maxY = _calculateMaxY(dailyData);

        // 创建曲线数据配置
        final lineBarData = LineChartBarData(
          spots: dataSpots,
          isCurved: true,
          curveSmoothness: 0.45,
          color: context.color.L04,
          barWidth: 3,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, size, barData, index) {
              bool isSelect = index == touchedIndex;
              return FlDotCirclePainter(
                radius: isSelect ? 6 : 3,
                color: context.color.L04,
                strokeWidth: isSelect ? 2 : 0,
                strokeColor: context.color.white100,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.color.L04.withOpacity(0.22),
                context.color.L04.withOpacity(0.01),
              ],
            ),
          ),
        );

        return Padding(
          padding: const EdgeInsets.only(right: 0, top: 8, bottom: 0),
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                enabled: true,
                touchCallback: (event, response) {
                  if (response != null && response.lineBarSpots != null) {
                    setState(() {
                      touchedIndex = response.lineBarSpots!.first.spotIndex;
                    });
                  }
                },
                touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 10,
                  tooltipPadding: const EdgeInsets.all(8),
                  tooltipBorder: const BorderSide(color: Colors.transparent),
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  rotateAngle: 0,
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      return LineTooltipItem(
                        "${spot.y.toInt()}ml",
                        const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.w500),
                      );
                    }).toList();
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (x, meta) {
                      int idx = x.toInt();
                      if (idx >= 0 && idx < xLabels.length) {
                        return Text(xLabels[idx],
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 10));
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 500,
                    reservedSize: 45,
                    getTitlesWidget: (val, meta) {
                      if (val == 0 || val == maxY) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Text("${val.toInt()}",
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 10)),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 500,
                checkToShowHorizontalLine: (value) => true,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: context.color.black10.withOpacity(0.1),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: maxY,
              lineBarsData: [lineBarData],
              showingTooltipIndicators: touchedIndex != null
                  ? [
                      ShowingTooltipIndicators([
                        LineBarSpot(
                          lineBarData,
                          touchedIndex!,
                          lineBarData.spots[touchedIndex!],
                        ),
                      ])
                    ]
                  : [],
            ),
          ),
        );
      },
    );
  }

  /// 构建有数据的日期列表（只显示有记录的日期）
  List<Map<String, dynamic>> _buildDailyData(Map<String, int> dailyTotals) {
    if (dailyTotals.isEmpty) return [];

    final result = <Map<String, dynamic>>[];

    // 将数据库返回的日期按顺序排列
    final sortedDates = dailyTotals.keys.toList()..sort();

    for (var dateKey in sortedDates) {
      final date = DateTime.parse(dateKey);
      final label = DateFormat('M-d').format(date);

      result.add({
        'date': dateKey,
        'label': label,
        'total': dailyTotals[dateKey]!,
      });
    }

    return result;
  }

  /// 计算 Y 轴最大值（向上取整到500的倍数）
  double _calculateMaxY(List<Map<String, dynamic>> dailyData) {
    if (dailyData.isEmpty) return 2000;

    final maxTotal =
        dailyData.map((d) => d['total'] as int).reduce((a, b) => a > b ? a : b);

    // 向上取整到500的倍数，最小2000
    final maxY = ((maxTotal / 500).ceil() * 500).toDouble();
    return maxY < 2000 ? 2000 : maxY + 500;
  }
}
