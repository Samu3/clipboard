import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';
import '../utils/translation_helper.dart';

class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLangAsync = ref.watch(currentLanguageProvider);

    return Scaffold(
        appBar: AppBar(
          title: Text(ref.tr('language_settings')),
        ),
        body: Container());
  }
}
