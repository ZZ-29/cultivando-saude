import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../domain/vitamina.dart';
import '../../patients/data/paciente_atual.dart';
import 'vitaminas_repositorio.dart';

/// Vitaminas em **SQLite** (Android).
class VitaminasSqlite implements VitaminasRepo {
  Database? _db;

  Future<Database> _abrir() async {
    final Database? pronto = _db;
    if (pronto != null && pronto.isOpen) return pronto;

    final String caminho = '${await getDatabasesPath()}/vitaminas${sufixoPaciente()}.db';
    final Database db = await openDatabase(
      caminho,
      version: 1,
      onCreate: (Database db, int _) async {
        await db.execute('''
          CREATE TABLE vitaminas (
            id   INTEGER PRIMARY KEY AUTOINCREMENT,
            json TEXT NOT NULL
          )
        ''');
      },
    );
    _db = db;
    return db;
  }

  @override
  Future<List<Vitamina>> listar() async {
    final Database db = await _abrir();
    final List<Map<String, Object?>> linhas =
        await db.query('vitaminas', orderBy: 'id ASC');

    return linhas.map((Map<String, Object?> linha) {
      final Object? cru = jsonDecode((linha['json'] as String?) ?? '{}');
      final Map<String, Object?> mapa =
          (cru is Map) ? cru.cast<String, Object?>() : <String, Object?>{};
      return Vitamina.doJson(mapa).copiarCom(id: linha['id'] as int?);
    }).toList(growable: false);
  }

  @override
  Future<int> salvar(Vitamina vitamina) async {
    final Database db = await _abrir();
    final String texto = jsonEncode(vitamina.paraJson());

    final int? id = vitamina.id;
    if (id == null) {
      return db.insert('vitaminas', <String, Object?>{'json': texto});
    }
    await db.update(
      'vitaminas',
      <String, Object?>{'json': texto},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
    return id;
  }

  @override
  Future<void> remover(int id) async {
    final Database db = await _abrir();
    await db.delete('vitaminas', where: 'id = ?', whereArgs: <Object?>[id]);
  }
}
