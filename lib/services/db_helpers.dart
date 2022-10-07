// table - table name
// prefix `c` - column name
// prefix `fc` - alias for column from another table

typedef DataRow = Map<String, Object?>;

class QRCodeNS {
  static const table = 'QrCode';
  static const cId = 'id';
  static const cValue = 'value';
  static const cCreatedAt = 'createdAt';
  static const cUsedAt = 'usedAt';
  static const cExpiresAt = 'expiresAt';
  static const cValidForMonth = 'validForMonth';
}

/// `QRCodeUnmarkedNS` represents db table
/// We expect at most one record will exists at given time but that is not guaranteed,
/// if some delete operation fails it will be ignored, therefore client code
/// should always take the newest record.
class QRCodeUnmarkedNS {
  static const table = 'QrCodeUnmarked';
  static const cId = 'id';
  static const cCodeId = 'codeId';
  static const cCreatedAt = 'createdAt';
  static const fcExpiresAt = 'expiresAt';

  /// value used as an alias when referencing the `QrCode.value` column
  static const fcCodeValue = 'codeValue';
}
