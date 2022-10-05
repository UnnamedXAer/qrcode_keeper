import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:qrcode_keeper/models/code.dart';
import 'package:qrcode_keeper/services/db_helpers.dart';
import 'package:sqflite/sqflite.dart';

class DBService {
  static late final DBService _instance = DBService._internal();
  late final Database _db;

  DBService._internal();

  factory DBService() {
    return _instance;
  }

  static Future<String> _dbPath() {
    return getDatabasesPath().then((dir) => '$dir/qrcodes_db.db');
  }

  /// use once before any database operation;
  static Future<void> initialize() async {
    // await _deleteDatabase();
    _instance._db = await openDatabase(await _dbPath(), version: 1,
        onCreate: (db, version) async {
      const createSql = '''CREATE TABLE
          ${QRCodeNS.table} (
            ${QRCodeNS.cId} INTEGER PRIMARY KEY, 
            ${QRCodeNS.cValue} TEXT NOT NULL,
            ${QRCodeNS.cCreatedAt} INTEGER NOT NULL,
            ${QRCodeNS.cUsedAt} INTEGER,
            ${QRCodeNS.cExpiresAt} INTEGER,
            ${QRCodeNS.cValidForMonth} INTEGER default 0
            )
            ''';

      debugPrint('creating tables... \n$createSql');

      await db.execute(
        createSql,
      );

      if (kDebugMode) {
        print('tables created.');
      }
    }, onOpen: (db) {
      debugPrint('db ${db.path} opened');
    });
  }

  Future<void> saveQrCodes({
    required List<String> codes,
    required Map<String, bool> usedCodes,
    required DateTime? expireAt,
    required bool validForMonth,
  }) async {
    if (codes.isEmpty) {
      return;
    }

    if (validForMonth) {
      expireAt = DateTime(expireAt!.year, expireAt.month + 1).subtract(
        const Duration(milliseconds: 1),
      );
    }

    final now = DateTime.now();
    final List<DataRow> data = List.generate(
      codes.length,
      (i) => QRCode(
        value: codes[i],
        createdAt: now,
        expiresAt: expireAt,
        usedAt: usedCodes[codes[i]] ?? false ? now : null,
        validForMonth: validForMonth,
      ).toMap(),
    );

    final batch = _db.batch();
    for (var row in data) {
      batch.insert(QRCodeNS.table, row);
    }

    final results = await batch.commit();
    debugPrint('inserted codes: ${results.length}');
  }

  Future<List<QRCode>> getCodesForMonth(
    DateTime expirationMonth, {
    bool includeExpired = false,
    bool includeUsed = false,
  }) async {
    final dateStart = DateTime(expirationMonth.year, expirationMonth.month);
    final dateEnd = DateTime(
      dateStart.year,
      dateStart.month + 1,
    ).subtract(
      const Duration(milliseconds: 1),
    );

    debugPrint('getCodesForMonth: $dateStart / $dateEnd, $includeExpired');

    String where =
        '((${QRCodeNS.cExpiresAt} >= ? and ${QRCodeNS.cExpiresAt} <= ?)';
    if (includeExpired) {
      where += ' or ${QRCodeNS.cExpiresAt} is null ';
    }
    where += ')';

    List<Object?> whereArgs = [
      dateStart.millisecondsSinceEpoch,
      dateEnd.millisecondsSinceEpoch,
    ];

    if (!includeUsed) {
      where += ' and ${QRCodeNS.cUsedAt} is null ';
    }

    final data = await _db.query(
      QRCodeNS.table,
      columns: [
        QRCodeNS.cId,
        QRCodeNS.cCreatedAt,
        QRCodeNS.cValue,
        QRCodeNS.cExpiresAt,
        QRCodeNS.cUsedAt,
        QRCodeNS.cValidForMonth,
      ],
      where: where,
      whereArgs: whereArgs,
      orderBy: QRCodeNS.cCreatedAt,
    );

    final List<QRCode> qrCodes = data.map((e) => QRCode.fromMap(e)).toList();
    // deleteQRCodes(qrCodes.map((e) => e.id).toList());

    debugPrint('codes for: $expirationMonth, cnt: ${qrCodes.length}');

    return qrCodes;
  }

  Future<void> deleteQRCodes(List<num> ids) async {
    final result = await _db.rawDelete(
        'DELETE FROM ${QRCodeNS.table} WHERE ${QRCodeNS.cId} IN (?)', [ids]);

    debugPrint('deleting codes with ids: $ids, result: $result');
  }

  Future<void> toggleCodeUsed(int id, DateTime? date) async {
    final result = await _db.rawUpdate(
        'UPDATE ${QRCodeNS.table} SET ${QRCodeNS.cUsedAt} = ? WHERE ${QRCodeNS.cId} = ?',
        [date?.millisecondsSinceEpoch, id]);

    if (result == 0) {
      throw Exception(
          'failed to toggle as used for code with id: $id, date: $date');
    }
  }

  static Future<void> _deleteDatabase() async {
    if (!kDebugMode) {
      return;
    }
    final path = await _dbPath();
    await deleteDatabase(path);
    log('your db at path "$path" deleted');
  }
}
