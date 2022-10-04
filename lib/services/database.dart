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

  /// use once to open database;
  static Future<void> initialize() async {
    var databasesPath = await getDatabasesPath();
    String path = '$databasesPath/qrcodes_db.db';

    _instance._db =
        await openDatabase(path, version: 1, onCreate: (db, version) async {
      const createSql =
          '''CREATE TABLE
          ${QRCodeNS.table} (
            ${QRCodeNS.cId} INTEGER PRIMARY KEY, 
            ${QRCodeNS.cValue} TEXT NOT NULL,
            ${QRCodeNS.cCreatedAt} INTEGER NOT NULL,
            ${QRCodeNS.cUsedAt} INTEGER,
            ${QRCodeNS.cExpiresAt} INTEGER
            )
            ''';

      if (kDebugMode) {
        print('create sql: "$createSql"');
      }

      await db.execute(
        createSql,
      );
    }, onOpen: (db) {
      print('db ${db.path} opened');
    });
  }

  Future<void> saveQrCodes(
    List<String> codes,
    Map<String, bool> usedCodes,
  ) async {
    if (codes.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final List<DataRow> data = List.generate(
      codes.length,
      (i) => QRCode(
        value: codes[i],
        createdAt: now,
        expiresAt: null,
        usedAt: usedCodes[codes[i]] ?? false ? now : null,
      ).toMap(),
    );

    final batch = _db.batch();
    for (var row in data) {
      batch.insert(QRCodeNS.table, row);
    }

    final results = await batch.commit();
    if (kDebugMode) {
      print('inserted codes: ${results.length}');
    }
  }

  Future<List<QRCode>> getCodesForMonth(
    DateTime expirationMonth, [
    bool showExpired = false,
  ]) async {
    final dateStart = DateTime(expirationMonth.year, expirationMonth.month);
    final dateEnd = DateTime(dateStart.year, dateStart.month + 1, 1);

    log('$dateStart');
    log('$dateEnd');

    String where =
        '${QRCodeNS.cExpiresAt} >= ? and ${QRCodeNS.cExpiresAt} <= ?';
    List<Object?> whereArgs = [
      dateStart.millisecondsSinceEpoch,
      dateEnd.microsecondsSinceEpoch
    ];

    if (!showExpired) {
      where += ' and ${QRCodeNS.cExpiresAt} is null';
    }

    final data = await _db.query(
      QRCodeNS.table,
      columns: [
        QRCodeNS.cId,
        QRCodeNS.cCreatedAt,
        QRCodeNS.cValue,
        QRCodeNS.cExpiresAt,
        QRCodeNS.cUsedAt
      ],
      // where: where,
      // whereArgs: whereArgs,
      orderBy: QRCodeNS.cCreatedAt,
    );

    final List<QRCode> qrCodes = data.map((e) => QRCode.fromMap(e)).toList();
    deleteQRCodes(qrCodes.map((e) => e.id).toList());

    if (kDebugMode) {
      print('codes for: $expirationMonth, cnt: ${qrCodes.length}');
    }

    return qrCodes;
  }

  Future<void> deleteQRCodes(List<int> ids) async {
    final result = await _db.rawDelete(
        'DELETE FROM ${QRCodeNS.table} WHERE ${QRCodeNS.cId} IN (?)', [ids]);

    if (kDebugMode) {
      print('deleting codes with ids: $ids, result: $result');
    }
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
}
