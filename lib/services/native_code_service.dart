import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeCodeService {
  const NativeCodeService._();

  static const platform = MethodChannel('kt.qrcodekeeper');

  /// Returns os version.
  ///
  /// It will return `null` if could not determine or en PlatformException occurs.
  static Future<double?> getOsVersion() async {
    try {
      final res = await platform.invokeMethod('getOsVersion');
      return res;
    } on PlatformException catch (ex) {
      debugPrint('getOsVersion: ex: $ex');
      return null;
    }
  }
}
