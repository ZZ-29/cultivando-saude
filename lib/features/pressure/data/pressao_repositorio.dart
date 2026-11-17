import '../domain/medicao.dart';

/// Armazenamento das medidas de pressão (Dart puro — sem plugin).
abstract class PressaoRepo {
  Future<List<Medicao>> listar();
  Future<int> salvar(Medicao medicao);
  Future<void> remover(int id);
}

/// Memória: some ao fechar. Padrão seguro para a preview.
class PressaoMemoria implements PressaoRepo {
  final List<Medicao> _itens = <Medicao>[];
  int _proximoId = 1;

  @override
  Future<List<Medicao>> listar() async {
    final List<Medicao> copia = List<Medicao>.from(_itens);
    copia.sort((Medicao a, Medicao b) => b.quando.compareTo(a.quando));
    return copia;
  }

  @override
  Future<int> salvar(Medicao medicao) async {
    final int id = medicao.id ?? _proximoId++;
    _itens.removeWhere((Medicao m) => m.id == id);
    _itens.add(medicao.copiarCom(id: id));
    return id;
  }

  @override
  Future<void> remover(int id) async =>
      _itens.removeWhere((Medicao m) => m.id == id);
}

/// Repositório ativo nesta execução.
PressaoRepo pressaoRepo = PressaoMemoria();

/// Troca a implementação (chamado uma vez, na inicialização).
void usarPressaoRepo(PressaoRepo novo) => pressaoRepo = novo;
