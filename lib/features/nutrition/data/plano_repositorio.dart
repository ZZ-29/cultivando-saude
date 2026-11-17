import '../../patients/data/paciente_atual.dart';
import '../domain/refeicao.dart';

/// Armazenamento do plano alimentar (Dart puro — sem plugin).
abstract class PlanoRepo {
  Future<List<Refeicao>> ler();
  Future<void> salvar(List<Refeicao> refeicoes);
}

/// Memória, separada por paciente (no Android o SQLite usa o sufixo do banco).
class PlanoMemoria implements PlanoRepo {
  final Map<int, List<Refeicao>> _porPaciente = <int, List<Refeicao>>{};

  @override
  Future<List<Refeicao>> ler() async {
    final List<Refeicao>? lista = _porPaciente[pacienteIdAtual];
    return lista == null ? <Refeicao>[] : List<Refeicao>.from(lista);
  }

  @override
  Future<void> salvar(List<Refeicao> refeicoes) async {
    _porPaciente[pacienteIdAtual] = List<Refeicao>.from(refeicoes);
  }
}

/// Repositório ativo nesta execução.
PlanoRepo planoRepo = PlanoMemoria();

/// Troca a implementação (chamado uma vez, na inicialização).
void usarPlanoRepo(PlanoRepo novo) => planoRepo = novo;
