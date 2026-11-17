import '../domain/compromisso.dart';

/// Armazenamento dos compromissos (Dart puro — sem plugin).
abstract class AgendaRepo {
  Future<List<Compromisso>> listar();
  Future<int> salvar(Compromisso compromisso);
  Future<void> remover(int id);
}

class AgendaMemoria implements AgendaRepo {
  final List<Compromisso> _itens = <Compromisso>[];
  int _proximoId = 1;

  @override
  Future<List<Compromisso>> listar() async {
    final List<Compromisso> copia = List<Compromisso>.from(_itens);
    copia.sort((Compromisso a, Compromisso b) => a.quando.compareTo(b.quando));
    return copia;
  }

  @override
  Future<int> salvar(Compromisso compromisso) async {
    final int id = compromisso.id ?? _proximoId++;
    _itens.removeWhere((Compromisso c) => c.id == id);
    _itens.add(compromisso.copiarCom(id: id));
    return id;
  }

  @override
  Future<void> remover(int id) async =>
      _itens.removeWhere((Compromisso c) => c.id == id);
}

/// Repositório ativo nesta execução.
AgendaRepo agendaRepo = AgendaMemoria();

/// Troca a implementação (chamado uma vez, na inicialização).
void usarAgendaRepo(AgendaRepo novo) => agendaRepo = novo;
