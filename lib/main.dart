import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:qrcode_keeper/layout/bottom_tabs_layout.dart';
import 'package:qrcode_keeper/services/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBService.initialize();

  await initializeDateFormatting();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        // GlobalMaterialLocalizations.delegate,
        MonthYearPickerLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
      ],
      locale: const Locale.fromSubtags(languageCode: 'en', countryCode: 'US'),
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const BottomTabsLayout(),
    );
  }
}
