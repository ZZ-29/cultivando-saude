import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../domain/atividade.dart';
import '../../patients/data/paciente_atual.dart';
import 'atividades_repositorio.dart';

/// Atividades em **SQLite** (Android).
class AtividadesSqlite implements AtividadesRepo {
  Database? _db;

  Future<Database> _abrir() async {
    final Database? pronto = _db;
    if (pronto != null && pronto.isOpen) return pronto;

    final String caminho = '${await getDatabasesPath()}/atividades${sufixoPaciente()}.db';
    final Database db = await openDatabase(
      caminho,
      version: 1,
      onCreate: (Database db, int _) async {
        await db.execute('''
          CREATE TABLE atividades (
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
  Future<List<Atividade>> listar() async {
    final Database db = await _abrir();
    final List<Map<String, Object?>> linhas =
        await db.query('atividades', orderBy: 'quando DESC');

    return linhas.map((Map<String, Object?> linha) {
      final Object? cru = jsonDecode((linha['json'] as String?) ?? '{}');
      final Map<String, Object?> mapa =
          (cru is Map) ? cru.cast<String, Object?>() : <String, Object?>{};
      return Atividade.doJson(mapa).copiarCom(id: linha['id'] as int?);
    }).toList(growable: false);
  }

  @override
  Future<int> salvar(Atividade atividade) async {
    final Database db = await _abrir();
    return db.insert('atividades', <String, Object?>{
      'json': jsonEncode(atividade.paraJson()),
      'quando': atividade.quando.toIso8601String(),
    });
  }

  @override
  Future<void> remover(int id) async {
    final Database db = await _abrir();
    await db.delete('atividades', where: 'id = ?', whereArgs: <Object?>[id]);
  }
}
