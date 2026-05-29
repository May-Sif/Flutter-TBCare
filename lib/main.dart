import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tbc_app/services/auth_service.dart';
import 'package:tbc_app/pages/authentication/authentication.dart';
import 'package:tbc_app/pages/form_screening.dart';
import 'package:tbc_app/providers/home_provider.dart';
import 'package:tbc_app/database/database_helper.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await AuthService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HomeProvider(DatabaseHelper().getCurrentUserId()),
        ),
      ],
      child: MaterialApp(
        title: 'TBC Care',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const AuthScreen(),
      ),
    );
  }
}