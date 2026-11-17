import '../domain/paciente.dart';

/// Armazenamento dos pacientes (Dart puro — sem plugin).
abstract class PacientesRepo {
  Future<List<Paciente>> listar();
  Future<Paciente> salvar(Paciente paciente);
  Future<void> remover(int id);
}

class PacientesMemoria implements PacientesRepo {
  final List<Paciente> _itens = <Paciente>[
    const Paciente(id: 1, nome: 'Eu'),
  ];
  int _proximoId = 2;

  @override
  Future<List<Paciente>> listar() async =>
      List<Paciente>.from(_itens)..sort((Paciente a, Paciente b) => a.id!.compareTo(b.id!));

  @override
  Future<Paciente> salvar(Paciente paciente) async {
    final int id = paciente.id ?? _proximoId++;
    _itens.removeWhere((Paciente p) => p.id == id);
    final Paciente salvo = paciente.copiarCom(id: id);
    _itens.add(salvo);
    return salvo;
  }

  @override
  Future<void> remover(int id) async =>
      _itens.removeWhere((Paciente p) => p.id == id);
}

/// Repositório ativo nesta execução.
PacientesRepo pacientesRepo = PacientesMemoria();

/// Troca a implementação (chamado uma vez, na inicialização).
void usarPacientesRepo(PacientesRepo novo) => pacientesRepo = novo;

/// Paciente em uso agora. `null` até o app carregar a lista.
int? pacienteAtualId;

/// Nome do paciente atual, para mostrar no cabeçalho.
String nomePacienteAtual = 'Eu';

/// Troca o paciente em uso.
void selecionarPaciente(int id, String nome) {
  pacienteAtualId = id;
  nomePacienteAtual = nome;
}

/// Garante que exista um paciente ativo (o primeiro da lista).
Future<void> garantirPacienteAtual() async {
  if (pacienteAtualId != null) return;
  final List<Paciente> lista = await pacientesRepo.listar();
  if (lista.isEmpty) {
    final Paciente novo = await pacientesRepo.salvar(const Paciente(nome: 'Eu'));
    selecionarPaciente(novo.id!, novo.nome);
    return;
  }
  selecionarPaciente(lista.first.id!, lista.first.nome);
}
