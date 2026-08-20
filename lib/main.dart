import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'l10n/locale_provider.dart';
import 'providers/app_state.dart';
import 'providers/chat_provider.dart';
import 'providers/mic_provider.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/language_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const GlideChinaApp());
}

class GlideChinaApp extends StatelessWidget {
  const GlideChinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => MicProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: MaterialApp(
        title: 'Glide China',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const LanguageScreen(),
      ),
    );
  }
}
