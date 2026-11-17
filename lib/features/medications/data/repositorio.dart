import '../domain/medicamento.dart';

/// Armazenamento dos remédios.
///
/// Este arquivo é **Dart puro** — não importa sqflite. É o que permite a
/// preview (sem plugins) abrir a tela de remédios usando [RepoMemoria], e o
/// app Android usar o SQLite de lá (`repositorio_sqlite.dart`, que só existe
/// no projeto com plugins).
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

/// Implementação em memória — some quando o app fecha.
///
/// É o padrão seguro: qualquer plataforma roda. O app Android troca por
/// SQLite no `main()`, chamando [usarRepositorio].
class RepoMemoria implements MedicamentosRepo {
  final Map<int, Medicamento> _itens = <int, Medicamento>{};
  final Map<int, Set<String>> _tomadas = <int, Set<String>>{};
  int _proximoId = 1;

  @override
  String get descricao => 'Memória (some ao fechar o app)';

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

/// Repositório ativo nesta execução.
///
/// Começa em memória; o `main()` do app troca por SQLite quando a plataforma
/// tem banco (`usarRepositorio(RepoSqlite())`).
MedicamentosRepo medicamentosRepo = RepoMemoria();

/// Troca a implementação ativa (chamado uma vez, na inicialização).
void usarRepositorio(MedicamentosRepo novo) => medicamentosRepo = novo;
