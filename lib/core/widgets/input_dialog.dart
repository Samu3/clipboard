import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clipboard/core/theme/app_colors.dart';
import 'package:clipboard/core/locale/utils/translation_helper.dart';

/// 通用输入弹窗
///
/// 用于弹出输入框，支持数字键盘、文本输入等
class WaterInputDialog extends StatefulWidget {
  /// 标题
  final String title;

  /// 输入框提示文本
  final String? hintText;

  /// 初始值
  final String? initialValue;

  /// 输入框类型（数字/文本）
  final TextInputType keyboardType;

  /// 输入格式限制
  final List<TextInputFormatter>? inputFormatters;

  /// 确认按钮文本
  final String confirmText;

  /// 取消按钮文本
  final String cancelText;

  /// 单位文字（显示在输入框后面）
  final String? unit;

  /// 最大输入长度
  final int? maxLength;

  const WaterInputDialog({
    super.key,
    required this.title,
    this.hintText,
    this.initialValue,
    this.keyboardType = TextInputType.number,
    this.inputFormatters,
    this.confirmText = '确认',
    this.cancelText = '取消',
    this.unit,
    this.maxLength,
  });

  @override
  State<WaterInputDialog> createState() => _InputDialogState();

  /// 显示数字输入弹窗
  static Future<String?> showNumber({
    required BuildContext context,
    required String title,
    String? hintText,
    String? initialValue,
    String? unit,
    int? maxLength,
    String confirmText = '确认',
    String cancelText = '取消',
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => WaterInputDialog(
        title: title,
        hintText: hintText,
        initialValue: initialValue,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        unit: unit,
        maxLength: maxLength,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }

  /// 显示文本输入弹窗
  static Future<String?> showText({
    required BuildContext context,
    required String title,
    String? hintText,
    String? initialValue,
    int? maxLength,
    String confirmText = '确认',
    String cancelText = '取消',
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => WaterInputDialog(
        title: title,
        hintText: hintText,
        initialValue: initialValue,
        keyboardType: TextInputType.text,
        maxLength: maxLength,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }
}

class _InputDialogState extends State<WaterInputDialog> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();

    // 延迟聚焦，确保弹窗动画完成后再弹出键盘
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      // 输入为空时，可以选择不关闭弹窗或给出提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入内容')),
      );
      return;
    }
    Navigator.of(context).pop(value);
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      insetPadding: EdgeInsets.only(
        left: 0,
        right: 0,
        bottom: 0, // 贴合键盘
      ),
      alignment: Alignment.bottomCenter, // 对齐到底部
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Center(
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.color.black10,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.38,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 输入框
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    keyboardType: widget.keyboardType,
                    inputFormatters: widget.inputFormatters,
                    maxLength: widget.maxLength,
                    decoration: InputDecoration(
                      fillColor: context.color.button_gray,
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        color: context.color.black06,
                        fontSize: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.lightDivider),
                      ),

                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      counterText: '', // 隐藏字符计数
                    ),
                    style: TextStyle(
                      color: context.color.black10,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // 单位
              ],
            ),
            const SizedBox(height: 24),

            // 按钮组
            Row(
              children: [
                // 取消按钮
                Expanded(
                  child: GestureDetector(
                    onTap: _handleCancel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: context.color.button_gray,
                        borderRadius: BorderRadius.circular(22.5),
                      ),
                      child: Center(
                        child: Text(
                          widget.cancelText,
                          style: TextStyle(
                            color: context.color.black08,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // 确认按钮
                Expanded(
                  child: GestureDetector(
                    onTap: _handleConfirm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: context.color.L04,
                        borderRadius: BorderRadius.circular(22.5),
                      ),
                      child: Center(
                        child: Text(
                          widget.confirmText,
                          style: TextStyle(
                            color: context.color.white100,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
