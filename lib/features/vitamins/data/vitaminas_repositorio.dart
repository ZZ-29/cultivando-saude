import '../domain/vitamina.dart';

/// Armazenamento das vitaminas (Dart puro — sem plugin).
abstract class VitaminasRepo {
  Future<List<Vitamina>> listar();
  Future<int> salvar(Vitamina vitamina);
  Future<void> remover(int id);
}

class VitaminasMemoria implements VitaminasRepo {
  final List<Vitamina> _itens = <Vitamina>[];
  int _proximoId = 1;

  @override
  Future<List<Vitamina>> listar() async {
    final List<Vitamina> copia = List<Vitamina>.from(_itens);
    copia.sort((Vitamina a, Vitamina b) => a.horario.compareTo(b.horario));
    return copia;
  }

  @override
  Future<int> salvar(Vitamina vitamina) async {
    final int id = vitamina.id ?? _proximoId++;
    _itens.removeWhere((Vitamina v) => v.id == id);
    _itens.add(vitamina.copiarCom(id: id));
    return id;
  }

  @override
  Future<void> remover(int id) async =>
      _itens.removeWhere((Vitamina v) => v.id == id);
}

/// Repositório ativo nesta execução.
VitaminasRepo vitaminasRepo = VitaminasMemoria();

/// Troca a implementação (chamado uma vez, na inicialização).
void usarVitaminasRepo(VitaminasRepo novo) => vitaminasRepo = novo;
