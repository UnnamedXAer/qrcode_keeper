import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:qrcode_keeper/models/code.dart';
import 'package:qrcode_keeper/models/code_unmarked.dart';
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
    _instance._db = await openDatabase(
      await _dbPath(),
      version: 1,
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

        debugPrint('tables created.');
      },
      onOpen: (db) {
        debugPrint('db ${db.path} opened');
      },
      onUpgrade: (db, oldVer, newVer) async {
        debugPrint("onUpgrade: Migrating from: $oldVer to $newVer");

        if (oldVer == 1) {
          debugPrint('enabling foreign keys...');
          await db.execute(
            'PRAGMA foreign_keys = ON',
          );
          debugPrint('foreign keys ENABLED');

          const createSql = '''CREATE TABLE
          ${QRCodeUnmarkedNS.table} (
            ${QRCodeUnmarkedNS.cId} INTEGER PRIMARY KEY, 
            ${QRCodeUnmarkedNS.cCodeId} INTEGER NOT NULL,
            ${QRCodeUnmarkedNS.cCreatedAt} INTEGER NOT NULL,
            ${QRCodeUnmarkedNS.fcExpiresAt} INTEGER,

            CONSTRAINT fk_${QRCodeUnmarkedNS.table}
            FOREIGN KEY (${QRCodeUnmarkedNS.cCodeId}) REFERENCES ${QRCodeNS.table}(${QRCodeNS.cId}) ON DELETE CASCADE
            )
            ''';

          debugPrint('creating tables... \n$createSql');

          await db.execute(
            createSql,
          );

          if (kDebugMode) {
            print('Table ${QRCodeUnmarkedNS.table} created.');
          }
        }
      },
    );
  }

  Future<void> saveQRCodes({
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

  /// returns list of `QRCode` that will expire in the given month
  Future<List<QRCode>> getQRCodesForMonth(
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

  Future<void> deleteQRCode(num id) async {
    final result = await _db.rawDelete(
        'DELETE FROM ${QRCodeNS.table} WHERE ${QRCodeNS.cId} = (?)', [id]);

    debugPrint('deleting codes with ids: $id, result: $result');
  }

  /// Marks code as used or unmark it depending on the `date` param
  ///
  /// `date` - if not null marks given code as used, otherwise
  /// if null it will unmark it.
  Future<void> toggleCodeUsed(int id, DateTime? date) async {
    final result = await _db.rawUpdate(
        'UPDATE ${QRCodeNS.table} SET ${QRCodeNS.cUsedAt} = ? WHERE ${QRCodeNS.cId} = ?',
        [date?.millisecondsSinceEpoch, id]);

    if (result == 0) {
      throw Exception(
          'failed to toggle as used for code with id: $id, date: $date');
    }
  }

  /// only one records should exists, prune table before creating new one.
  Future<int> createUnmarkedCodeWarn(QRCode code) {
    final QrCodeUnmarked unmarkedCode = QrCodeUnmarked.fromCode(code);
    final data = unmarkedCode.toMap();

    return _db.transaction<int>(
      (trx) async {
        await trx.rawDelete('DELETE FROM ${QRCodeUnmarkedNS.table}');
        final id = await trx.insert(QRCodeUnmarkedNS.table, data);

        return id;
      },
    );
  }

  /// it's expected that at most one record will be present in QrCodeUnmarkedNS table
  /// but in case we always want to fetch the latest and greatest one.
  /// It's guaranteed that this function will not throw, in case of an error
  /// null will be returned.
  Future<QrCodeUnmarked?> getPossibleUnmarkedQRCode() async {
    try {
      final data = await _db.query(
        '${QRCodeUnmarkedNS.table} umc join ${QRCodeNS.table} c on umc.${QRCodeUnmarkedNS.cCodeId} = c.${QRCodeNS.cId}',
        columns: [
          'umc.${QRCodeUnmarkedNS.cId}',
          'umc.${QRCodeUnmarkedNS.cCodeId}',
          'c.${QRCodeNS.cValue} as ${QRCodeUnmarkedNS.fcCodeValue}',
          'umc.${QRCodeUnmarkedNS.cCreatedAt}',
          'umc.${QRCodeUnmarkedNS.fcExpiresAt}',
        ],
        orderBy: 'umc.${QRCodeUnmarkedNS.cCreatedAt} desc',
        limit: 1,
      );

      if (data.isEmpty) {
        return null;
      }

      final unmarkedCode = QrCodeUnmarked.fromMap(data[0]);

      return unmarkedCode;
    } catch (err) {
      debugPrint('getPossibleUnmarkedQRCode: err: $err');
      return null;
    }
  }

  /// the expected behaviour is to always keep at max 1 code,
  /// so when we want to delete a record it seems ok to not specify "where".
  Future<void> deleteQRUnmarkedCodes() async {
    final deleteCnt = await _db.rawDelete(
      'DELETE FROM ${QRCodeUnmarkedNS.table}',
    );

    assert(deleteCnt == 0 || deleteCnt == 1,
        '${QRCodeUnmarkedNS.table}: at most 1 record should exists at the given time');

    debugPrint('deleting ${QRCodeUnmarkedNS.table}, count: $deleteCnt');
  }

  static Future<void> _unsafe_deleteDatabase() async {
    if (!kDebugMode) {
      return;
    }
    final path = await _dbPath();
    await deleteDatabase(path);
    log('your db at path "$path" deleted');
  }
}
