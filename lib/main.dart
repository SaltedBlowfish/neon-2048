import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/game_screen.dart';
import 'theme/neon_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: NeonTheme.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const NeonApp());
}

class NeonApp extends StatelessWidget {
  const NeonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon 2048',
      debugShowCheckedModeBanner: false,
      theme: NeonTheme.themeData(),
      home: const GameScreen(),
    );
  }
}
