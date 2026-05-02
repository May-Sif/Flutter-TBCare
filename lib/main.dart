import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tbc_app/services/auth_service.dart';
import 'package:tbc_app/pages/authentication/authentication.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    )
  );

  await AuthService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AuthScreen(),
    );
  }
}