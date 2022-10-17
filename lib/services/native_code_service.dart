import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:qrcode_keeper/models/versions_info.dart';

class NativeCodeService {
  const NativeCodeService._();

  static const _platform = MethodChannel('kt.qrcodekeeper');

  /// Returns app, os versions.
  ///
  /// It will return `VersionsInfo` with null values if could not determine or en PlatformException occurs.
  static Future<VersionsInfo> getVersionsInfo() async {
    try {
      final res =
          await _platform.invokeMethod<Map>('getVersionsInfo');
      if (res == null) {
        throw Exception('null response');
      }
      final info = VersionsInfo.fromMap(Map<String, dynamic>.from(res));
      return info;
    } on PlatformException catch (ex) {
      debugPrint('getVersionsInfo: ex: $ex');
      return VersionsInfo();
    }
  }
}
