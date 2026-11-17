import '../domain/paciente.dart';
import 'pacientes_repositorio.dart';
import 'reset_memoria.dart';

/// Identificador do paciente ativo (1 quando ainda não escolheu).
int get pacienteIdAtual => pacienteAtualId ?? 1;

/// Sufixo usado nos nomes de arquivo do banco.
///
/// **Por que um banco por paciente:** em vez de acrescentar `paciente_id` em
/// nove tabelas (e migrar tudo), cada pessoa tem sua própria família de bancos
/// (`medicamentos_p2.db`, `pressao_p2.db`…). Isolamento garantido pelo arquivo,
/// zero risco de dado de um aparecer no outro, e trocar de paciente é trocar o
/// nome do arquivo.
String sufixoPaciente() => '_p$pacienteIdAtual';

/// Troca o paciente ativo e limpa o que estiver em memória (preview/testes).
///
/// No Android nada precisa ser limpo: os repositórios SQLite passam a apontar
/// para outro arquivo na próxima leitura.
void trocarPaciente(Paciente paciente) {
  selecionarPaciente(paciente.id!, paciente.nome);
  reiniciarDadosEmMemoria();
}
