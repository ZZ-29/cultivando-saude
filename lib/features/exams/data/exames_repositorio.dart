import '../domain/exame.dart';

/// Armazenamento dos exames (Dart puro — sem plugin).
abstract class ExamesRepo {
  Future<List<Exame>> listar();
  Future<int> salvar(Exame exame);
  Future<void> remover(int id);
}

class ExamesMemoria implements ExamesRepo {
  final List<Exame> _itens = <Exame>[];
  int _proximoId = 1;

  @override
  Future<List<Exame>> listar() async {
    final List<Exame> copia = List<Exame>.from(_itens);
    copia.sort((Exame a, Exame b) => b.quando.compareTo(a.quando));
    return copia;
  }

  @override
  Future<int> salvar(Exame exame) async {
    final int id = exame.id ?? _proximoId++;
    _itens.removeWhere((Exame e) => e.id == id);
    _itens.add(exame.copiarCom(id: id));
    return id;
  }

  @override
  Future<void> remover(int id) async =>
      _itens.removeWhere((Exame e) => e.id == id);
}

/// Repositório ativo nesta execução.
ExamesRepo examesRepo = ExamesMemoria();

/// Troca a implementação (chamado uma vez, na inicialização).
void usarExamesRepo(ExamesRepo novo) => examesRepo = novo;
