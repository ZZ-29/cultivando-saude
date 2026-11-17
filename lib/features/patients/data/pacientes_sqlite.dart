import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../domain/paciente.dart';
import 'pacientes_repositorio.dart';

/// Pacientes em **SQLite** (Android). Um único banco, sem sufixo de paciente —
/// é o índice de todos (cada um tem seus próprios bancos de dados).
class PacientesSqlite implements PacientesRepo {
  Database? _db;

  Future<Database> _abrir() async {
    final Database? pronto = _db;
    if (pronto != null && pronto.isOpen) return pronto;

    final String caminho = '${await getDatabasesPath()}/pacientes.db';
    final Database db = await openDatabase(
      caminho,
      version: 1,
      onCreate: (Database db, int _) async {
        await db.execute('''
          CREATE TABLE pacientes (
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
  Future<List<Paciente>> listar() async {
    final Database db = await _abrir();
    final List<Map<String, Object?>> linhas =
        await db.query('pacientes', orderBy: 'id ASC');

    if (linhas.isEmpty) {
      final Paciente inicial = await salvar(const Paciente(nome: 'Eu'));
      return <Paciente>[inicial];
    }

    return linhas.map((Map<String, Object?> linha) {
      final Object? cru = jsonDecode((linha['json'] as String?) ?? '{}');
      final Map<String, Object?> mapa =
          (cru is Map) ? cru.cast<String, Object?>() : <String, Object?>{};
      return Paciente.doJson(mapa).copiarCom(id: linha['id'] as int?);
    }).toList(growable: false);
  }

  @override
  Future<Paciente> salvar(Paciente paciente) async {
    final Database db = await _abrir();
    final String texto = jsonEncode(paciente.paraJson());

    final int? id = paciente.id;
    if (id == null) {
      final int novo = await db.insert('pacientes', <String, Object?>{'json': texto});
      return paciente.copiarCom(id: novo);
    }
    await db.update(
      'pacientes',
      <String, Object?>{'json': texto},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
    return paciente;
  }

  @override
  Future<void> remover(int id) async {
    final Database db = await _abrir();
    await db.delete('pacientes', where: 'id = ?', whereArgs: <Object?>[id]);
  }
}
