import 'package:flutter/material.dart';
import 'package:tuition/screens/splash_screen.dart';

import 'core/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tuition App',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
