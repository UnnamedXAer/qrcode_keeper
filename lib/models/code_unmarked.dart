import 'package:qrcode_keeper/models/code.dart';
import 'package:qrcode_keeper/services/db_helpers.dart';

class QrCodeUnmarked {
  final int id;
  final int codeId;
  final String codeValue;
  final DateTime createdAt;
  final DateTime? expiresAt;

  QrCodeUnmarked({
    this.id = 0,
    required this.codeId,
    required this.codeValue,
    required this.createdAt,
    this.expiresAt,
  }) : assert(codeId > 0);

  /// works only for setting new values, does NOT work for setting `null`'s
  QrCodeUnmarked copyWith({
    final int? id,
    final int? codeId,
    final String? codeValue,
    final DateTime? createdAt,
    final DateTime? expiresAt,
  }) =>
      QrCodeUnmarked(
        id: id ?? this.id,
        codeId: id ?? this.codeId,
        codeValue: codeValue ?? this.codeValue,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
      );

  Map<String, Object?> toMap() {
    final Map<String, Object?> data = {
      QRCodeUnmarkedNS.cCodeId: codeId,
      QRCodeUnmarkedNS.cCreatedAt: createdAt.millisecondsSinceEpoch,
      QRCodeUnmarkedNS.fcExpiresAt: expiresAt?.millisecondsSinceEpoch,
    };

    if (id != 0) {
      data[QRCodeUnmarkedNS.cId] = id;
    }

    return data;
  }

  QrCodeUnmarked.fromMap(DataRow data)
      : id = data[QRCodeUnmarkedNS.cId] as int,
        codeId = data[QRCodeUnmarkedNS.cCodeId] as int,
        codeValue = data[QRCodeUnmarkedNS.fcCodeValue] as String,
        createdAt = DateTime.fromMillisecondsSinceEpoch(
            data[QRCodeUnmarkedNS.cCreatedAt] as int),
        expiresAt = data[QRCodeUnmarkedNS.fcExpiresAt] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                data[QRCodeUnmarkedNS.fcExpiresAt] as int);

  QrCodeUnmarked.fromCode(QRCode code)
      : assert(code.id > 0),
        id = 0,
        codeId = code.id,
        codeValue = code.value,
        createdAt = DateTime.now(),
        expiresAt = code.expiresAt;
}
