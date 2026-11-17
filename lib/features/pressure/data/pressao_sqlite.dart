import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../domain/medicao.dart';
import '../../patients/data/paciente_atual.dart';
import 'pressao_repositorio.dart';

/// Medidas de pressão em **SQLite** (Android).
class PressaoSqlite implements PressaoRepo {
  Database? _db;

  Future<Database> _abrir() async {
    final Database? pronto = _db;
    if (pronto != null && pronto.isOpen) return pronto;

    final String caminho = '${await getDatabasesPath()}/pressao${sufixoPaciente()}.db';
    final Database db = await openDatabase(
      caminho,
      version: 1,
      onCreate: (Database db, int _) async {
        await db.execute('''
          CREATE TABLE medidas (
            id    INTEGER PRIMARY KEY AUTOINCREMENT,
            json  TEXT NOT NULL,
            quando TEXT NOT NULL
          )
        ''');
      },
    );
    _db = db;
    return db;
  }

  @override
  Future<List<Medicao>> listar() async {
    final Database db = await _abrir();
    final List<Map<String, Object?>> linhas =
        await db.query('medidas', orderBy: 'quando DESC');

    return linhas.map((Map<String, Object?> linha) {
      final Object? cru = jsonDecode((linha['json'] as String?) ?? '{}');
      final Map<String, Object?> mapa =
          (cru is Map) ? cru.cast<String, Object?>() : <String, Object?>{};
      return Medicao.doJson(mapa).copiarCom(id: linha['id'] as int?);
    }).toList(growable: false);
  }

  @override
  Future<int> salvar(Medicao medicao) async {
    final Database db = await _abrir();
    return db.insert('medidas', <String, Object?>{
      'json': jsonEncode(medicao.paraJson()),
      'quando': medicao.quando.toIso8601String(),
    });
  }

  @override
  Future<void> remover(int id) async {
    final Database db = await _abrir();
    await db.delete('medidas', where: 'id = ?', whereArgs: <Object?>[id]);
  }
}
