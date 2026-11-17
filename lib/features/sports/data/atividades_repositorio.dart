import '../domain/atividade.dart';

/// Armazenamento das atividades (Dart puro — sem plugin).
abstract class AtividadesRepo {
  Future<List<Atividade>> listar();
  Future<int> salvar(Atividade atividade);
  Future<void> remover(int id);
}

class AtividadesMemoria implements AtividadesRepo {
  final List<Atividade> _itens = <Atividade>[];
  int _proximoId = 1;

  @override
  Future<List<Atividade>> listar() async {
    final List<Atividade> copia = List<Atividade>.from(_itens);
    copia.sort((Atividade a, Atividade b) => b.quando.compareTo(a.quando));
    return copia;
  }

  @override
  Future<int> salvar(Atividade atividade) async {
    final int id = atividade.id ?? _proximoId++;
    _itens.removeWhere((Atividade a) => a.id == id);
    _itens.add(atividade.copiarCom(id: id));
    return id;
  }

  @override
  Future<void> remover(int id) async =>
      _itens.removeWhere((Atividade a) => a.id == id);
}

/// Repositório ativo nesta execução.
AtividadesRepo atividadesRepo = AtividadesMemoria();

/// Troca a implementação (chamado uma vez, na inicialização).
void usarAtividadesRepo(AtividadesRepo novo) => atividadesRepo = novo;
