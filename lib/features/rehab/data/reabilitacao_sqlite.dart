import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../patients/data/paciente_atual.dart';
import '../domain/exercicio.dart';
import 'reabilitacao_repositorio.dart';

/// Reabilitação em **SQLite** (Android), um banco por paciente.
class ReabilitacaoSqlite implements ReabilitacaoRepo {
  Database? _db;

  Future<Database> _abrir() async {
    final Database? pronto = _db;
    if (pronto != null && pronto.isOpen) return pronto;

    final String caminho =
        '${await getDatabasesPath()}/reabilitacao${sufixoPaciente()}.db';
    final Database db = await openDatabase(
      caminho,
      version: 1,
      onCreate: (Database db, int _) async {
        await db.execute('''
          CREATE TABLE exercicios (
            id   INTEGER PRIMARY KEY AUTOINCREMENT,
            json TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE feitos (
            exercicio_id INTEGER NOT NULL,
            dia          TEXT NOT NULL,
            PRIMARY KEY (exercicio_id, dia)
          )
        ''');
      },
    );
    _db = db;
    return db;
  }

  @override
  Future<List<Exercicio>> listar() async {
    final Database db = await _abrir();
    final List<Map<String, Object?>> linhas =
        await db.query('exercicios', orderBy: 'id ASC');

    return linhas.map((Map<String, Object?> linha) {
      final Object? cru = jsonDecode((linha['json'] as String?) ?? '{}');
      final Map<String, Object?> mapa =
          (cru is Map) ? cru.cast<String, Object?>() : <String, Object?>{};
      return Exercicio.doJson(mapa).copiarCom(id: linha['id'] as int?);
    }).toList(growable: false);
  }

  @override
  Future<int> salvar(Exercicio exercicio) async {
    final Database db = await _abrir();
    final String texto = jsonEncode(exercicio.paraJson());

    final int? id = exercicio.id;
    if (id == null) {
      return db.insert('exercicios', <String, Object?>{'json': texto});
    }
    await db.update(
      'exercicios',
      <String, Object?>{'json': texto},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
    return id;
  }

  @override
  Future<void> remover(int id) async {
    final Database db = await _abrir();
    await db.delete('exercicios', where: 'id = ?', whereArgs: <Object?>[id]);
    await db.delete('feitos',
        where: 'exercicio_id = ?', whereArgs: <Object?>[id]);
  }

  @override
  Future<Set<int>> feitosNoDia(DateTime dia) async {
    final Database db = await _abrir();
    final List<Map<String, Object?>> linhas = await db.query(
      'feitos',
      columns: <String>['exercicio_id'],
      where: 'dia = ?',
      whereArgs: <Object?>[chaveDoDia(dia)],
    );
    return linhas
        .map((Map<String, Object?> l) => (l['exercicio_id'] as num).toInt())
        .toSet();
  }

  @override
  Future<void> marcarFeito(int exercicioId, DateTime dia, bool feito) async {
    final Database db = await _abrir();
    final String chave = chaveDoDia(dia);

    if (feito) {
      await db.insert(
        'feitos',
        <String, Object?>{'exercicio_id': exercicioId, 'dia': chave},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } else {
      await db.delete(
        'feitos',
        where: 'exercicio_id = ? AND dia = ?',
        whereArgs: <Object?>[exercicioId, chave],
      );
    }
  }
}
