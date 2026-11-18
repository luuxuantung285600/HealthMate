import '../theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../theme/app_theme.dart';
import 'feature_page.dart';

class StartupErrorApp extends StatefulWidget {
  const StartupErrorApp({required this.onRetry, super.key});

  final Future<void> Function() onRetry;

  @override
  State<StartupErrorApp> createState() => _StartupErrorAppState();
}

class _StartupErrorAppState extends State<StartupErrorApp> {
  bool _busy = false;

  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: SafeArea(
          child: FeaturePage(
            title: 'Chưa thể khởi động HealthMate',
            subtitle:
                'Dịch vụ tài khoản chưa sẵn sàng. Kiểm tra kết nối rồi thử lại. '
                'Nếu lỗi vẫn tiếp diễn, vui lòng liên hệ người quản lý ứng dụng.',
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _retry,
                icon: const Icon(AppIcons.refreshCw),
                label: Text(_busy ? 'Đang thử lại…' : 'Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
