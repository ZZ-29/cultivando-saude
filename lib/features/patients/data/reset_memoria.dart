import '../../agenda/data/agenda_repositorio.dart';
import '../../exams/data/exames_repositorio.dart';
import '../../medications/data/repositorio.dart';
import '../../pressure/data/pressao_repositorio.dart';
import '../../rehab/data/reabilitacao_repositorio.dart';
import '../../profile/data/perfil_repositorio.dart';
import '../../safety/data/contatos_repositorio.dart';
import '../../sports/data/atividades_repositorio.dart';
import '../../vitamins/data/vitaminas_repositorio.dart';
import '../../wellness/data/bem_estar_repositorio.dart';

/// Zera os dados em memória ao trocar de paciente (preview e testes).
///
/// No Android isso não é necessário: cada paciente já tem seus próprios
/// arquivos SQLite. Aqui, como a preview guarda tudo em memória, recriar os
/// repositórios é o equivalente a "abrir a pasta do outro paciente".
void reiniciarDadosEmMemoria() {
  usarRepositorio(RepoMemoria());
  // O perfil NÃO é recriado: ele já é separado por paciente (mapa com chave),
  // então recriar apagaria o perfil de quem estava em uso antes.
  usarPressaoRepo(PressaoMemoria());
  usarAgendaRepo(AgendaMemoria());
  usarContatosRepo(ContatosMemoria());
  usarVitaminasRepo(VitaminasMemoria());
  usarAtividadesRepo(AtividadesMemoria());
  usarBemEstarRepo(BemEstarMemoria());
  usarExamesRepo(ExamesMemoria());
  usarReabilitacaoRepo(ReabilitacaoMemoria());
}
