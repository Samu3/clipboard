import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:unique_health/core/channel/native_channel.dart';
import 'package:unique_health/core/router/app_router.dart';
import 'package:unique_health/core/theme/app_colors.dart';
import 'package:unique_health/core/widgets/custom_app_bar.dart';
import 'package:unique_health/core/widgets/input_dialog.dart';
import 'package:unique_health/core/widgets/rounded_trapezoid.dart';
import 'package:unique_health/core/locale/utils/translation_helper.dart';
import 'package:unique_health/features/water/domain/entities/water_setting.dart';
import 'package:unique_health/features/water/widget/water_line_chart.dart';
import '../providers/water_provider.dart';

class WaterPage extends ConsumerStatefulWidget {
  const WaterPage({super.key});

  @override
  ConsumerState<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends ConsumerState<WaterPage> {
  @override
  void initState() {
    super.initState();

    // 只在初始化时添加一次 listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(goRouterProvider);
      router.routerDelegate.addListener(_onRouteChanged);
    });
  }

  void _onRouteChanged() {
    final router = ref.read(goRouterProvider);
    final matches = router.routerDelegate.currentConfiguration.matches;
    final depth = matches.length;
    AppChannel.hybridChannel.invokeMethod("updateStackDepth", depth);
  }

  @override
  void dispose() {
    final router = ref.read(goRouterProvider);
    router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(waterNotifierProvider.notifier);
    final waterSetting = ref.watch(waterSettingNotifierProvider);

    return Scaffold(
      body: waterSetting.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text("错误:$e")),
        data: (setting) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                // begin 底部，end顶部 = 从下往上渐变
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: [0.0, 1.0],
                colors: [
                  context.color.bg_gray,
                  Color(0xFFC3D0FA),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomAppBar(
                  title: ref.tr("HE_SHUI", tag: "喝水"),
                  onBackPressed: () {
                    AppChannel().closeFlutterVC();
                  },
                  actions: [
                    AppBarAction(
                      icon: Icons.more_vert,
                      onTap: () => context.push('/water/record'),
                    )
                  ],
                ),
                _waterTopMainContainer(context, ref, notifier, setting),
                Expanded(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.only(left: 12, right: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: ShapeDecoration(
                        color: context.color.white100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                  "assets/images/drink/ic_drink_record.svg"),
                              const SizedBox(width: 12),
                              Text(
                                ref.tr("HE_SHUI_JI_LU", tag: "喝水记录"),
                                style: TextStyle(
                                  color: context.color.black08,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 1.38,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Expanded(
                            child: WaterLineChart(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  child: Container(
                    height: 45,
                    width: MediaQuery.of(context).size.width,
                    margin: EdgeInsets.only(
                        bottom: 27, left: 27, right: 27, top: 15),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 12),
                    decoration: ShapeDecoration(
                      color: context.color.L04,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(86),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '+${setting.waterCpu}ml',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.color.white100,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      ],
                    ),
                  ),
                  onTap: () {
                    notifier.addDrink(setting.waterCpu);
                  },
                )
              ],
            ),
          );
          ;
        },
      ),
    );
  }

  Widget _waterTopMainContainer(BuildContext context, WidgetRef ref,
      WaterNotifier noti, WaterSetting setting) {
    final asyncRecords = ref.watch(waterNotifierProvider);
    final waterSettingNoti = ref.watch(waterSettingNotifierProvider.notifier);

    return asyncRecords.when(
        loading: () => Container(),
        error: (error, stackTrace) => Container(),
        data: (records) {
          final total = noti.getTotalMl(records);
          final waterRaido = total.toDouble() / setting.waterTarget.toDouble();

          return Container(
            height: 200,
            margin: EdgeInsets.only(left: 25, right: 25, top: 13, bottom: 20),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // 上方饮水目标
                    GestureDetector(
                      onTap: () async {
                        final result = await WaterInputDialog.showNumber(
                            context: context,
                            title: ref.tr("SHE_ZHI_YIN_SHUI_MU_BIAO",
                                tag: '设置饮水目标'),
                            hintText: ref.tr("SHU_RU_YIN_SHUI_MU_BIAO",
                                tag: '请输入目标饮水量'),
                            initialValue: '${setting.waterTarget}',
                            unit: 'ml',
                            maxLength: 5,
                            cancelText: ref.tr("QU_XIAO"),
                            confirmText: ref.tr("confirm"));
                        final value = int.tryParse(result ?? '');
                        if (value != null && value > 0) {
                          waterSettingNoti.updateWaterTarget(value);
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${setting.waterTarget}",
                                style: TextStyle(
                                  height: 1,
                                  color: context.color.black10,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(
                                width: 4,
                              ),
                              Text(
                                'ml',
                                style: TextStyle(
                                  height: 1.5,
                                  color: context.color.black10,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              )
                            ],
                          ),
                          Text(
                            '${ref.tr("YIN_SHUI_MU_BIAO", tag: "饮水目标")}  >',
                            style: TextStyle(
                              color: context.color.black06,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // 下方饮水目标
                    GestureDetector(
                      onTap: () async {
                        final result = await WaterInputDialog.showNumber(
                            context: context,
                            title: ref.tr("SHE_ZHI_SHUI_BEI_RONG_LIANG",
                                tag: "设置水杯容量"),
                            hintText: ref.tr("SHU_RU_YIN_SHUI_MU_BIAO",
                                tag: "请输入水杯容量"),
                            initialValue: '${setting.waterCpu}',
                            unit: 'ml',
                            maxLength: 5,
                            cancelText: ref.tr("QU_XIAO"),
                            confirmText: ref.tr("confirm"));
                        if (result != null) {
                          // TODO: 保存饮水目标
                          waterSettingNoti.updateWaterCpu(int.parse(result));
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${setting.waterCpu}",
                                style: TextStyle(
                                  height: 1,
                                  color: context.color.black10,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(
                                width: 4,
                              ),
                              Text(
                                'ml',
                                style: TextStyle(
                                  height: 1.5,
                                  color: context.color.black10,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              )
                            ],
                          ),
                          Text(
                            '${ref.tr("SHUI_BEI_RONG_LIANG", tag: "水杯容量")}  >',
                            style: TextStyle(
                              color: context.color.black06,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: 136,
                  height: 210,
                  child: Stack(
                    children: [
                      // 背景梯形 - 白色（空杯子）

                      Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: SvgPicture.asset(
                              "assets/images/drink/ic_drink_cup_shadow.svg")),

                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 6,
                        child: RoundedTrapezoid(
                          width: 136,
                          height: 200,
                          color: context.color.white100,
                          topWidth: 136, // 上宽
                          bottomWidth: 100, // 下窄
                          cornerRadius: 12,
                        ),
                      ),

                      // 前景梯形 - 蓝色（水位，从底部开始填充）
                      waterRaido == 0
                          ? Container()
                          : Positioned(
                              bottom: 6,
                              left: 0,
                              right: 0,
                              child: RoundedTrapezoid(
                                width: 136,
                                height: 200 * waterRaido, // 20% 的水位
                                color: context.color.L04,
                                topWidth: 136 -
                                    (136 - 100) * (1 - waterRaido), // 按比例计算上宽
                                bottomWidth: 100, // 底部与杯底对齐
                                cornerRadius: 12,
                              ),
                            ),
                      // 文字显示
                      waterRaido == 0
                          ? Container()
                          : Positioned(
                              bottom: waterRaido >= 0.8
                                  ? 170
                                  : 200 * waterRaido + 8 + 6,
                              left: 27,
                              right: 27,
                              child: Center(
                                child: Text(
                                  '${total}ml',
                                  style: TextStyle(
                                    color: context.color.black10,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                )
              ],
            ),
          );
        });
  }
}
