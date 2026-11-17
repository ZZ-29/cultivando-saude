import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../domain/checkup_emocional.dart';
import '../domain/registro_bem_estar.dart';
import '../../patients/data/paciente_atual.dart';
import 'bem_estar_repositorio.dart';

/// Bem-estar em **SQLite** (Android). Uma linha por dia.
class BemEstarSqlite implements BemEstarRepo {
  Database? _db;

  Future<Database> _abrir() async {
    final Database? pronto = _db;
    if (pronto != null && pronto.isOpen) return pronto;

    final String caminho = '${await getDatabasesPath()}/bem_estar${sufixoPaciente()}.db';
    final Database db = await openDatabase(
      caminho,
      version: 1,
      onCreate: (Database db, int _) async {
        await db.execute('''
          CREATE TABLE checkups (
            id   INTEGER PRIMARY KEY AUTOINCREMENT,
            dia  TEXT NOT NULL,
            json TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE bem_estar (
            id   INTEGER PRIMARY KEY AUTOINCREMENT,
            dia  TEXT NOT NULL UNIQUE,
            json TEXT NOT NULL
          )
        ''');
      },
    );
    _db = db;
    return db;
  }

  static String _chave(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Future<List<RegistroBemEstar>> listar() async {
    final Database db = await _abrir();
    final List<Map<String, Object?>> linhas =
        await db.query('bem_estar', orderBy: 'dia DESC');

    return linhas.map((Map<String, Object?> linha) {
      final Object? cru = jsonDecode((linha['json'] as String?) ?? '{}');
      final Map<String, Object?> mapa =
          (cru is Map) ? cru.cast<String, Object?>() : <String, Object?>{};
      return RegistroBemEstar.doJson(mapa)
          .copiarCom(id: linha['id'] as int?);
    }).toList(growable: false);
  }

  @override
  Future<void> salvar(RegistroBemEstar registro) async {
    final Database db = await _abrir();
    await db.insert(
      'bem_estar',
      <String, Object?>{
        'dia': _chave(registro.dia),
        'json': jsonEncode(registro.paraJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<CheckupEmocional>> checkups() async {
    final Database db = await _abrir();
    final List<Map<String, Object?>> linhas =
        await db.query('checkups', orderBy: 'dia DESC');
    return linhas.map((Map<String, Object?> linha) {
      final Object? cru = jsonDecode((linha['json'] as String?) ?? '{}');
      final Map<String, Object?> mapa =
          (cru is Map) ? cru.cast<String, Object?>() : <String, Object?>{};
      return CheckupEmocional.doJson(mapa);
    }).toList(growable: false);
  }

  @override
  Future<void> salvarCheckup(CheckupEmocional checkup) async {
    final Database db = await _abrir();
    await db.insert('checkups', <String, Object?>{
      'dia': checkup.dia.toIso8601String(),
      'json': jsonEncode(checkup.paraJson()),
    });
  }

  @override
  Future<RegistroBemEstar?> deHoje() async {
    final Database db = await _abrir();
    final String chave = _chave(RegistroBemEstar.soData(DateTime.now()));
    final List<Map<String, Object?>> linhas = await db.query(
      'bem_estar',
      where: 'dia = ?',
      whereArgs: <Object?>[chave],
      limit: 1,
    );
    if (linhas.isEmpty) return null;

    final Object? cru = jsonDecode((linhas.first['json'] as String?) ?? '{}');
    final Map<String, Object?> mapa =
        (cru is Map) ? cru.cast<String, Object?>() : <String, Object?>{};
    return RegistroBemEstar.doJson(mapa)
        .copiarCom(id: linhas.first['id'] as int?);
  }
}
