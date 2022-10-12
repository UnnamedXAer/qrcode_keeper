import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qrcode_keeper/services/local_notifications_service.dart';
import 'package:qrcode_keeper/services/database.dart';

Future<void> initializeApp() {
  WidgetsFlutterBinding.ensureInitialized();

  return Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    initializeDateFormatting(),
    DBService.initialize(),
    LocalNotificationsService.initialize(),
  ]);
}
