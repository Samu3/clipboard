import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class LocalVideoPlayer extends StatefulWidget {
  const LocalVideoPlayer({super.key, required this.path});

  final String path;

  @override
  State<LocalVideoPlayer> createState() => _LocalVideoPlayerState();
}

class _LocalVideoPlayerState extends State<LocalVideoPlayer> {
  late VideoPlayerController controller;
  late Future<void> initialized;
  String status = '正在加载视频…';

  @override
  void initState() {
    super.initState();
    initialized = _initialize(widget.path, allowConversion: true);
  }

  Future<void> _initialize(String path, {required bool allowConversion}) async {
    controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize().timeout(const Duration(seconds: 8));
      controller.addListener(_refresh);
      status = '';
      if (mounted) setState(() {});
    } catch (_) {
      await controller.dispose();
      if (!allowConversion || !path.toLowerCase().endsWith('.mov')) rethrow;
      status = '正在兼容 MOV 格式，较大的视频需要一些时间…';
      if (mounted) setState(() {});
      final channel = MethodChannel(
          Platform.isMacOS ? 'com.clipboard/channel' : 'com.clipboard/ios');
      final converted = await channel.invokeMethod<String>(
          'convertVideoForPlayback',
          {'path': path}).timeout(const Duration(minutes: 3));
      if (converted == null || converted.isEmpty) rethrow;
      status = '正在打开兼容视频…';
      if (mounted) setState(() {});
      await _initialize(converted, allowConversion: false);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: initialized,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child:
                  Text('视频无法播放：${snapshot.error}', textAlign: TextAlign.center),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(status, textAlign: TextAlign.center),
                ],
              ),
            );
          }
          final value = controller.value;
          return LayoutBuilder(builder: (context, constraints) {
            final screen = MediaQuery.sizeOf(context);
            final availableWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : screen.width;
            final maxVideoHeight = screen.height * (Platform.isIOS ? .34 : .62);
            final aspect = value.aspectRatio > 0 ? value.aspectRatio : 16 / 9;
            final videoWidth =
                availableWidth.clamp(1.0, maxVideoHeight * aspect);
            final videoHeight = videoWidth / aspect;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: SizedBox(
                    width: videoWidth,
                    height: videoHeight,
                    child: ColoredBox(
                      color: Colors.black,
                      child: Stack(children: [
                        Positioned.fill(child: VideoPlayer(controller)),
                        if (!value.isPlaying)
                          Positioned.fill(
                            child: Center(
                              child: IconButton.filled(
                                iconSize: 34,
                                onPressed: _togglePlayback,
                                icon: Icon(value.position >= value.duration
                                    ? Icons.replay
                                    : Icons.play_arrow),
                              ),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 48,
                  child: Row(children: [
                    IconButton(
                      tooltip: value.isPlaying ? '暂停' : '播放',
                      onPressed: _togglePlayback,
                      icon: Icon(
                          value.isPlaying ? Icons.pause : Icons.play_arrow),
                    ),
                    Expanded(
                      child: VideoProgressIndicator(
                        controller,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${_time(value.position)} / ${_time(value.duration)}'),
                  ]),
                ),
              ],
            );
          });
        },
      );

  Future<void> _togglePlayback() async {
    if (controller.value.position >= controller.value.duration) {
      await controller.seekTo(Duration.zero);
    }
    controller.value.isPlaying
        ? await controller.pause()
        : await controller.play();
  }

  String _time(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
