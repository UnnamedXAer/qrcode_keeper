import 'package:qrcode_keeper/services/db_helpers.dart';

class QRCode {
  final int id;
  final String value;
  final DateTime createdAt;
  final DateTime? usedAt;
  final DateTime? expiresAt;
  final bool validForMonth;
  final bool favorite;

  QRCode({
    this.id = 0,
    required this.value,
    required this.createdAt,
    this.usedAt,
    this.expiresAt,
    this.validForMonth = false,
    this.favorite = false,
  });

  /// works only for setting new values, does not work for setting `null`'s
  QRCode copyWith(
          {final int? id,
          final String? value,
          final DateTime? createdAt,
          final DateTime? usedAt,
          final DateTime? expiresAt,
          final bool? validForMonth,
          final bool? favorite}) =>
      QRCode(
        id: id ?? this.id,
        value: value ?? this.value,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
        usedAt: usedAt ?? this.usedAt,
        validForMonth: validForMonth ?? this.validForMonth,
        favorite: favorite ?? this.favorite,
      );

  Map<String, Object?> toMap() {
    final Map<String, Object?> data = {
      QRCodeNS.cValue: value,
      QRCodeNS.cCreatedAt: createdAt.millisecondsSinceEpoch as num,
      QRCodeNS.cUsedAt: usedAt?.millisecondsSinceEpoch as num?,
      QRCodeNS.cExpiresAt: expiresAt?.millisecondsSinceEpoch as num?,
      QRCodeNS.cValidForMonth: (validForMonth ? 1 : 0) as num?,
      QRCodeNS.cFavorite: (favorite ? 1 : 0) as num?,
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
        usedAt = data[QRCodeNS.cUsedAt] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                data[QRCodeNS.cUsedAt] as int),
        expiresAt = data[QRCodeNS.cExpiresAt] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                data[QRCodeNS.cExpiresAt] as int),
        validForMonth = data[QRCodeNS.cValidForMonth] == 1 ? true : false,
        favorite = data[QRCodeNS.cFavorite] == 1 ? true : false;
}
