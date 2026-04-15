import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/database_service.dart';
import 'services/cloud_service.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final dbService = DatabaseService();
  await dbService.init();

  final cloudService = CloudService();
  await CloudService.initialize();

  final notificationService = NotificationService();
  await notificationService.init();

  final themeService = ThemeService();

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: dbService),
        Provider<CloudService>.value(value: cloudService),
        ChangeNotifierProvider<ThemeService>.value(value: themeService),
      ],
      child: const MonoApp(),
    ),
  );
}
