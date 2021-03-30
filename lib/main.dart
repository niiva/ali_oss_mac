import 'package:ali_oss_mac/main_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 滚动性能优化
  // 根据所涉及的频率差异, 启用此标志可以使滚动时的颤动减少多达97%
  GestureBinding.instance.resamplingEnabled = true;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
      ],
      supportedLocales: [
        // English, no country code],
        const Locale('en', ''),
      ],
      home: MainPage(),
      builder: EasyLoading.init(),
    );
  }
}
