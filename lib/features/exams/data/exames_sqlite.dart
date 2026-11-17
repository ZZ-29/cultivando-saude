import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../patients/data/paciente_atual.dart';
import '../domain/exame.dart';
import 'exames_repositorio.dart';

/// Exames em **SQLite** (Android), um banco por paciente.
class ExamesSqlite implements ExamesRepo {
  Database? _db;

  Future<Database> _abrir() async {
    final Database? pronto = _db;
    if (pronto != null && pronto.isOpen) return pronto;

    final String caminho =
        '${await getDatabasesPath()}/exames${sufixoPaciente()}.db';
    final Database db = await openDatabase(
      caminho,
      version: 1,
      onCreate: (Database db, int _) async {
        await db.execute('''
          CREATE TABLE exames (
            id     INTEGER PRIMARY KEY AUTOINCREMENT,
            json   TEXT NOT NULL,
            quando TEXT NOT NULL
          )
        ''');
      },
    );
    _db = db;
    return db;
  }

  @override
  Future<List<Exame>> listar() async {
    final Database db = await _abrir();
    final List<Map<String, Object?>> linhas =
        await db.query('exames', orderBy: 'quando DESC');

    return linhas.map((Map<String, Object?> linha) {
      final Object? cru = jsonDecode((linha['json'] as String?) ?? '{}');
      final Map<String, Object?> mapa =
          (cru is Map) ? cru.cast<String, Object?>() : <String, Object?>{};
      return Exame.doJson(mapa).copiarCom(id: linha['id'] as int?);
    }).toList(growable: false);
  }

  @override
  Future<int> salvar(Exame exame) async {
    final Database db = await _abrir();
    return db.insert('exames', <String, Object?>{
      'json': jsonEncode(exame.paraJson()),
      'quando': exame.quando.toIso8601String(),
    });
  }

  @override
  Future<void> remover(int id) async {
    final Database db = await _abrir();
    await db.delete('exames', where: 'id = ?', whereArgs: <Object?>[id]);
  }
}
