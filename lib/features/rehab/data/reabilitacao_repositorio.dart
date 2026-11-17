import '../domain/exercicio.dart';

/// Armazenamento dos exercícios de reabilitação (Dart puro — sem plugin).
abstract class ReabilitacaoRepo {
  Future<List<Exercicio>> listar();
  Future<int> salvar(Exercicio exercicio);
  Future<void> remover(int id);

  /// Exercícios marcados como feitos no dia informado.
  Future<Set<int>> feitosNoDia(DateTime dia);
  Future<void> marcarFeito(int exercicioId, DateTime dia, bool feito);
}

class ReabilitacaoMemoria implements ReabilitacaoRepo {
  final List<Exercicio> _itens = <Exercicio>[];
  final Map<String, Set<int>> _feitos = <String, Set<int>>{};
  int _proximoId = 1;

  @override
  Future<List<Exercicio>> listar() async => List<Exercicio>.from(_itens);

  @override
  Future<int> salvar(Exercicio exercicio) async {
    final int id = exercicio.id ?? _proximoId++;
    _itens.removeWhere((Exercicio e) => e.id == id);
    _itens.add(exercicio.copiarCom(id: id));
    _itens.sort((Exercicio a, Exercicio b) => a.nome.compareTo(b.nome));
    return id;
  }

  @override
  Future<void> remover(int id) async =>
      _itens.removeWhere((Exercicio e) => e.id == id);

  @override
  Future<Set<int>> feitosNoDia(DateTime dia) async =>
      Set<int>.from(_feitos[chaveDoDia(dia)] ?? <int>{});

  @override
  Future<void> marcarFeito(int exercicioId, DateTime dia, bool feito) async {
    final String chave = chaveDoDia(dia);
    final Set<int> conjunto = _feitos.putIfAbsent(chave, () => <int>{});
    if (feito) {
      conjunto.add(exercicioId);
    } else {
      conjunto.remove(exercicioId);
    }
  }
}

/// Repositório ativo nesta execução.
ReabilitacaoRepo reabilitacaoRepo = ReabilitacaoMemoria();

/// Troca a implementação (chamado uma vez, na inicialização).
void usarReabilitacaoRepo(ReabilitacaoRepo novo) =>
    reabilitacaoRepo = novo;
