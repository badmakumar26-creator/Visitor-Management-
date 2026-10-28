import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/visitor_provider.dart';
import 'screens/home_shell.dart';
import 'services/visitor_api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VisitorApp());
}

class VisitorApp extends StatelessWidget {
  const VisitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VisitorProvider(VisitorApiService())..loadVisitors(),
      child: MaterialApp(
        title: 'Visitor Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const HomeShell(),
      ),
    );
  }
}
