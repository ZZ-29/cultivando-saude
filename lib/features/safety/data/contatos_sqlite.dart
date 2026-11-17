import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../domain/contato.dart';
import '../../patients/data/paciente_atual.dart';
import 'contatos_repositorio.dart';

/// Contatos de emergência em **SQLite** (Android).
class ContatosSqlite implements ContatosRepo {
  Database? _db;

  Future<Database> _abrir() async {
    final Database? pronto = _db;
    if (pronto != null && pronto.isOpen) return pronto;

    final String caminho = '${await getDatabasesPath()}/contatos${sufixoPaciente()}.db';
    final Database db = await openDatabase(
      caminho,
      version: 1,
      onCreate: (Database db, int _) async {
        await db.execute('''
          CREATE TABLE contatos (
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
  Future<List<Contato>> listar() async {
    final Database db = await _abrir();
    final List<Map<String, Object?>> linhas =
        await db.query('contatos', orderBy: 'id ASC');

    return linhas.map((Map<String, Object?> linha) {
      final Object? cru = jsonDecode((linha['json'] as String?) ?? '{}');
      final Map<String, Object?> mapa =
          (cru is Map) ? cru.cast<String, Object?>() : <String, Object?>{};
      return Contato.doJson(mapa);
    }).toList(growable: false);
  }

  @override
  Future<int> salvar(Contato contato) async {
    final Database db = await _abrir();
    final String texto = jsonEncode(contato.paraJson());

    final int? id = contato.id;
    if (id == null) {
      return db.insert('contatos', <String, Object?>{'json': texto});
    }
    await db.update(
      'contatos',
      <String, Object?>{'json': texto},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
    return id;
  }

  @override
  Future<void> remover(int id) async {
    final Database db = await _abrir();
    await db.delete('contatos', where: 'id = ?', whereArgs: <Object?>[id]);
  }
}
