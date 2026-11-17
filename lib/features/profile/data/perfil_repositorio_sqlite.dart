import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../domain/perfil.dart';
import '../../patients/data/paciente_atual.dart';
import 'perfil_repositorio.dart';

/// Perfil em **SQLite** (Android).
///
/// Tabela de uma linha só (`id = 1`): o app tem um dono. O JSON guarda os
/// campos, então acrescentar um campo novo no futuro não exige migração de
/// coluna.
class PerfilSqlite implements PerfilRepo {
  Database? _db;

  Future<Database> _abrir() async {
    final Database? pronto = _db;
    if (pronto != null && pronto.isOpen) return pronto;

    final String caminho = '${await getDatabasesPath()}/perfil${sufixoPaciente()}.db';
    final Database db = await openDatabase(
      caminho,
      version: 1,
      onCreate: (Database db, int _) async {
        await db.execute('''
          CREATE TABLE perfil (
            id   INTEGER PRIMARY KEY,
            json TEXT NOT NULL
          )
        ''');
      },
    );
    _db = db;
    return db;
  }

  @override
  Future<Perfil> ler() async {
    final Database db = await _abrir();
    final List<Map<String, Object?>> linhas =
        await db.query('perfil', where: 'id = ?', whereArgs: <Object?>[1]);
    if (linhas.isEmpty) return const Perfil();

    final Object? cru = jsonDecode((linhas.first['json'] as String?) ?? '{}');
    final Map<String, Object?> mapa =
        (cru is Map) ? cru.cast<String, Object?>() : <String, Object?>{};
    return Perfil.doJson(mapa);
  }

  @override
  Future<void> salvar(Perfil perfil) async {
    final Database db = await _abrir();
    await db.insert(
      'perfil',
      <String, Object?>{'id': 1, 'json': jsonEncode(perfil.paraJson())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
