import '../domain/contato.dart';

/// Armazenamento dos contatos de emergência (Dart puro — sem plugin).
abstract class ContatosRepo {
  Future<List<Contato>> listar();
  Future<int> salvar(Contato contato);
  Future<void> remover(int id);
}

class ContatosMemoria implements ContatosRepo {
  final List<Contato> _itens = <Contato>[];
  int _proximoId = 1;

  @override
  Future<List<Contato>> listar() async =>
      List<Contato>.from(_itens)..sort((Contato a, Contato b) =>
          a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

  @override
  Future<int> salvar(Contato contato) async {
    final int id = contato.id ?? _proximoId++;
    _itens.removeWhere((Contato c) => c.id == id);
    _itens.add(contato.copiarCom(id: id));
    return id;
  }

  @override
  Future<void> remover(int id) async =>
      _itens.removeWhere((Contato c) => c.id == id);
}

/// Repositório ativo nesta execução.
ContatosRepo contatosRepo = ContatosMemoria();

/// Troca a implementação (chamado uma vez, na inicialização).
void usarContatosRepo(ContatosRepo novo) => contatosRepo = novo;
