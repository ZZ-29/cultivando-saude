import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../domain/compromisso.dart';
import '../../patients/data/paciente_atual.dart';
import 'agenda_repositorio.dart';

/// Compromissos em **SQLite** (Android).
class AgendaSqlite implements AgendaRepo {
  Database? _db;

  Future<Database> _abrir() async {
    final Database? pronto = _db;
    if (pronto != null && pronto.isOpen) return pronto;

    final String caminho = '${await getDatabasesPath()}/agenda${sufixoPaciente()}.db';
    final Database db = await openDatabase(
      caminho,
      version: 1,
      onCreate: (Database db, int _) async {
        await db.execute('''
          CREATE TABLE compromissos (
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
  Future<List<Compromisso>> listar() async {
    final Database db = await _abrir();
    final List<Map<String, Object?>> linhas =
        await db.query('compromissos', orderBy: 'quando ASC');

    return linhas.map((Map<String, Object?> linha) {
      final Object? cru = jsonDecode((linha['json'] as String?) ?? '{}');
      final Map<String, Object?> mapa =
          (cru is Map) ? cru.cast<String, Object?>() : <String, Object?>{};
      return Compromisso.doJson(mapa).copiarCom(id: linha['id'] as int?);
    }).toList(growable: false);
  }

  @override
  Future<int> salvar(Compromisso compromisso) async {
    final Database db = await _abrir();
    return db.insert('compromissos', <String, Object?>{
      'json': jsonEncode(compromisso.paraJson()),
      'quando': compromisso.quando.toIso8601String(),
    });
  }

  @override
  Future<void> remover(int id) async {
    final Database db = await _abrir();
    await db.delete('compromissos', where: 'id = ?', whereArgs: <Object?>[id]);
  }
}
