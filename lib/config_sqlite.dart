import 'package:sqflite/sqflite.dart';

import 'features/patients/data/paciente_atual.dart';
import 'core/config/config_repositorio.dart';

/// Configurações em **SQLite** (Android), um banco por paciente.
class ConfigSqlite implements ConfigRepo {
  Database? _db;

  Future<Database> _abrir() async {
    final Database? pronto = _db;
    if (pronto != null && pronto.isOpen) return pronto;

    final String caminho =
        '${await getDatabasesPath()}/config${sufixoPaciente()}.db';
    final Database db = await openDatabase(
      caminho,
      version: 1,
      onCreate: (Database db, int _) async {
        await db.execute('''
          CREATE TABLE config (
            chave TEXT PRIMARY KEY,
            valor TEXT NOT NULL
          )
        ''');
      },
    );
    _db = db;
    return db;
  }

  @override
  Future<String?> ler(String chave) async {
    final Database db = await _abrir();
    final List<Map<String, Object?>> linhas = await db.query(
      'config',
      where: 'chave = ?',
      whereArgs: <Object?>[chave],
      limit: 1,
    );
    if (linhas.isEmpty) return null;
    return linhas.first['valor'] as String?;
  }

  @override
  Future<void> salvar(String chave, String valor) async {
    final Database db = await _abrir();
    await db.insert(
      'config',
      <String, Object?>{'chave': chave, 'valor': valor},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> remover(String chave) async {
    final Database db = await _abrir();
    await db.delete('config', where: 'chave = ?', whereArgs: <Object?>[chave]);
  }
}
