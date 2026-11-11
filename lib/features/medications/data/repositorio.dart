import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';

import '../domain/medicamento.dart';

/// Armazenamento dos remédios.
///
/// Duas implementações:
///   • [RepoSqlite]  — Android. Duas tabelas: `medicamentos` (o JSON do
///                     tratamento) e `doses` (o que já foi tomado).
///   • [RepoMemoria] — Chrome, onde o sqflite não existe. Serve para testar a
///                     lógica; recarregar a página apaga.
abstract class MedicamentosRepo {
  String get descricao;

  Future<List<Medicamento>> listar();

  /// Grava (insert ou update) e devolve o id.
  Future<int> salvar(Medicamento medicamento);

  Future<void> remover(int id);

  /// Chaves ("AAAA-MM-DD|HH:MM") já registradas como tomadas.
  Future<Set<String>> tomadas(int medicamentoId);

  Future<void> marcarTomada(int medicamentoId, String chave);
}

// ---------------------------------------------------------------------------
// SQLite
// ---------------------------------------------------------------------------

class RepoSqlite implements MedicamentosRepo {
  Database? _db;

  Future<Database> _abrir() async {
    final Database? pronto = _db;
    if (pronto != null && pronto.isOpen) return pronto;

    final String caminho = '${await getDatabasesPath()}/medicamentos.db';
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

// ---------------------------------------------------------------------------
// Memória (Chrome)
// ---------------------------------------------------------------------------

class RepoMemoria implements MedicamentosRepo {
  final Map<int, Medicamento> _itens = <int, Medicamento>{};
  final Map<int, Set<String>> _tomadas = <int, Set<String>>{};
  int _proximoId = 1;

  @override
  String get descricao => 'Memória (Chrome — recarregar apaga)';

  @override
  Future<List<Medicamento>> listar() async {
    final List<int> ids = _itens.keys.toList()..sort();
    return ids.map((int id) => _itens[id]!).toList(growable: false);
  }

  @override
  Future<int> salvar(Medicamento medicamento) async {
    final int id = medicamento.id ?? _proximoId++;
    _itens[id] = medicamento.copiarCom(id: id);
    return id;
  }

  @override
  Future<void> remover(int id) async {
    _itens.remove(id);
    _tomadas.remove(id);
  }

  @override
  Future<Set<String>> tomadas(int medicamentoId) async =>
      Set<String>.from(_tomadas[medicamentoId] ?? <String>{});

  @override
  Future<void> marcarTomada(int medicamentoId, String chave) async {
    _tomadas.putIfAbsent(medicamentoId, () => <String>{}).add(chave);
  }
}

/// Implementação ativa nesta execução.
final MedicamentosRepo medicamentosRepo =
    kIsWeb ? RepoMemoria() : RepoSqlite();
