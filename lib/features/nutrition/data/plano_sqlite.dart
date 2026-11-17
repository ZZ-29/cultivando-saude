import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../patients/data/paciente_atual.dart';
import '../domain/refeicao.dart';
import 'plano_repositorio.dart';

/// Plano alimentar em **SQLite** (Android), um banco por paciente.
///
/// Uma linha só (`id = 1`) com a lista de refeições em JSON: o plano é um
/// documento, não uma tabela de registros.
class PlanoSqlite implements PlanoRepo {
  Database? _db;

  Future<Database> _abrir() async {
    final Database? pronto = _db;
    if (pronto != null && pronto.isOpen) return pronto;

    final String caminho =
        '${await getDatabasesPath()}/plano${sufixoPaciente()}.db';
    final Database db = await openDatabase(
      caminho,
      version: 1,
      onCreate: (Database db, int _) async {
        await db.execute('''
          CREATE TABLE plano (
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
  Future<List<Refeicao>> ler() async {
    final Database db = await _abrir();
    final List<Map<String, Object?>> linhas =
        await db.query('plano', where: 'id = ?', whereArgs: <Object?>[1]);
    if (linhas.isEmpty) return <Refeicao>[];

    final Object? cru = jsonDecode((linhas.first['json'] as String?) ?? '[]');
    return refeicoesDoJson(cru);
  }

  @override
  Future<void> salvar(List<Refeicao> refeicoes) async {
    final Database db = await _abrir();
    final String texto =
        jsonEncode(refeicoes.map((Refeicao r) => r.paraJson()).toList());
    await db.insert(
      'plano',
      <String, Object?>{'id': 1, 'json': texto},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
