import 'package:qrcode_keeper/services/db_helpers.dart';

class QRCode {
  final int id;
  final String value;
  final DateTime createdAt;
  final DateTime? usedAt;
  final DateTime? expiresAt;

  QRCode({
    this.id = 0,
    required this.value,
    required this.createdAt,
    this.usedAt,
    this.expiresAt,
  });

  QRCode copyWith({
    final int? id,
    final String? value,
    final DateTime? createdAt,
    final bool? used,
    final DateTime? usedAt,
    final DateTime? expiresAt,
  }) =>
      QRCode(
        id: id ?? this.id,
        value: value ?? this.value,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
        usedAt: usedAt ?? this.usedAt,
      );

  Map<String, Object?> toMap() {
    final Map<String, Object?> data = {
      QRCodeNS.cValue: value,
      QRCodeNS.cCreatedAt: createdAt.millisecondsSinceEpoch,
      QRCodeNS.cUsedAt: usedAt?.millisecondsSinceEpoch,
      QRCodeNS.cExpiresAt: expiresAt?.millisecondsSinceEpoch,
    };

    if (id != 0) {
      data[QRCodeNS.cId] = id;
    }

    return data;
  }

  QRCode.fromMap(DataRow data)
      : id = data[QRCodeNS.cId] as int,
        value = data[QRCodeNS.cValue] as String,
        createdAt = DateTime.fromMillisecondsSinceEpoch(
            data[QRCodeNS.cCreatedAt] as int),
        expiresAt = data[QRCodeNS.cExpiresAt] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                data[QRCodeNS.cExpiresAt] as int),
        usedAt = data[QRCodeNS.cUsedAt] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                data[QRCodeNS.cUsedAt] as int);
}
