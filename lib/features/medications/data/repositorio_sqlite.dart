import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../domain/medicamento.dart';
import '../../patients/data/paciente_atual.dart';
import 'repositorio.dart';

/// Armazenamento dos remédios em **SQLite** (Android).
///
/// Vive fora de `patch-v13` de propósito: é o único arquivo do módulo que
/// depende de plugin, e mantê-lo separado deixa o resto do módulo puro — o que
/// permite a preview sem plugins usar `RepoMemoria`.
///
/// Duas tabelas:
///   • `medicamentos` — o JSON do tratamento;
///   • `doses`        — o que já foi tomado (chave "AAAA-MM-DD|HH:MM").
class RepoSqlite implements MedicamentosRepo {
  Database? _db;

  Future<Database> _abrir() async {
    final Database? pronto = _db;
    if (pronto != null && pronto.isOpen) return pronto;

    final String caminho = '${await getDatabasesPath()}/medicamentos${sufixoPaciente()}.db';
    final Database db = await openDatabase(
      caminho,
      version: 1,
      onCreate: (Database db, int _) async {
        await db.execute('''
          CREATE TABLE medicamentos (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            json      TEXT NOT NULL,
            criado_em TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE doses (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            medicamento_id  INTEGER NOT NULL,
            chave           TEXT    NOT NULL,
            tomada_em       TEXT    NOT NULL,
            UNIQUE (medicamento_id, chave)
          )
        ''');
      },
    );
    _db = db;
    return db;
  }

  @override
  String get descricao => 'SQLite (medicamentos.db)';

  @override
  Future<List<Medicamento>> listar() async {
    final Database db = await _abrir();
    final List<Map<String, Object?>> linhas =
        await db.query('medicamentos', orderBy: 'id ASC');

    return linhas.map((Map<String, Object?> linha) {
      final Object? cru = jsonDecode((linha['json'] as String?) ?? '{}');
      final Map<String, Object?> mapa =
          (cru is Map) ? cru.cast<String, Object?>() : <String, Object?>{};
      return Medicamento.doJson(mapa).copiarCom(id: linha['id'] as int?);
    }).toList(growable: false);
  }

  @override
  Future<int> salvar(Medicamento medicamento) async {
    final Database db = await _abrir();
    final Map<String, Object?> json = medicamento.paraJson()..remove('id');
    final String texto = jsonEncode(json);

    final int? id = medicamento.id;
    if (id == null) {
      return db.insert('medicamentos', <String, Object?>{
        'json': texto,
        'criado_em': medicamento.criadoEm.toIso8601String(),
      });
    }

    await db.update(
      'medicamentos',
      <String, Object?>{'json': texto},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
    return id;
  }

  @override
  Future<void> remover(int id) async {
    final Database db = await _abrir();
    await db.delete('doses',
        where: 'medicamento_id = ?', whereArgs: <Object?>[id]);
    await db.delete('medicamentos', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  @override
  Future<Set<String>> tomadas(int medicamentoId) async {
    final Database db = await _abrir();
    final List<Map<String, Object?>> linhas = await db.query(
      'doses',
      columns: <String>['chave'],
      where: 'medicamento_id = ?',
      whereArgs: <Object?>[medicamentoId],
    );
    return linhas
        .map((Map<String, Object?> l) => (l['chave'] as String?) ?? '')
        .where((String c) => c.isNotEmpty)
        .toSet();
  }

  @override
  Future<void> marcarTomada(int medicamentoId, String chave) async {
    final Database db = await _abrir();
    await db.insert(
      'doses',
      <String, Object?>{
        'medicamento_id': medicamentoId,
        'chave': chave,
        'tomada_em': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}
