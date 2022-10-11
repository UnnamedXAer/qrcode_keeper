import 'package:flutter/material.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:qrcode_keeper/layout/bottom_tabs_layout.dart';

class MyApp extends StatelessWidget {
  const MyApp({required this.flavor, Key? key}) : super(key: key);
  final String flavor;

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
      title: 'QR Keeper  ${flavor != 'production' ? flavor : ''}',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const BottomTabsLayout(),
    );
  }
}
