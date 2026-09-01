import 'package:flutter/material.dart';

class AppToast {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context, String msg,
      {Duration duration = const Duration(seconds: 1)}) {
    // 先移除旧toast
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }

    _overlayEntry = OverlayEntry(builder: (ctx) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    msg,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });

    Overlay.of(context).insert(_overlayEntry!);
    Future.delayed(duration, () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }
}
