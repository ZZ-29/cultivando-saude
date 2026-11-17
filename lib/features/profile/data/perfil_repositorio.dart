import '../../patients/data/pacientes_repositorio.dart';
import '../domain/perfil.dart';

/// Armazenamento do perfil.
///
/// Dart puro (sem plugin): no Android é trocado por SQLite no `main()`.
abstract class PerfilRepo {
  Future<Perfil> ler();
  Future<void> salvar(Perfil perfil);
}

/// Implementação em memória — some ao fechar o app.
///
/// Um perfil por paciente: no Android o SQLite já separa por arquivo; aqui a
/// separação é por chave no mapa.
class PerfilMemoria implements PerfilRepo {
  final Map<int, Perfil> _porPaciente = <int, Perfil>{};

  int _chave() => pacienteAtualId ?? 1;

  @override
  Future<Perfil> ler() async => _porPaciente[_chave()] ?? const Perfil();

  @override
  Future<void> salvar(Perfil perfil) async => _porPaciente[_chave()] = perfil;
}

/// Perfil ativo nesta execução.
PerfilRepo perfilRepo = PerfilMemoria();

/// Troca a implementação (chamado uma vez, na inicialização).
void usarPerfilRepo(PerfilRepo novo) => perfilRepo = novo;
