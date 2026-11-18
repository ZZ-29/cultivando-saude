import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/navigation/app_shell.dart';
import 'core/theme/app_colors.dart';
import 'features/agenda/data/agenda_repositorio.dart';
import 'features/agenda/data/agenda_sqlite.dart';
import 'features/agenda/data/notificacoes.dart';
import 'features/agenda/domain/compromisso.dart';
// No Android vale o plugin de notificações; na web (preview) entra a versão
// vazia, porque o plugin não existe em navegador.
import 'compartilhar_android.dart'
    if (dart.library.js_interop) 'compartilhar_vazio.dart';
import 'notificacoes_android.dart'
    if (dart.library.js_interop) 'notificacoes_vazio.dart';
import 'features/exams/data/exames_repositorio.dart';
import 'features/exams/data/exames_sqlite.dart';
import 'features/medications/data/repositorio.dart';
import 'features/medications/data/repositorio_sqlite.dart';
import 'features/nutrition/data/plano_repositorio.dart';
import 'features/nutrition/data/plano_sqlite.dart';
import 'features/patients/data/pacientes_repositorio.dart';
import 'features/patients/data/pacientes_sqlite.dart';
import 'features/pressure/data/compartilhar.dart';
import 'features/pressure/data/pressao_repositorio.dart';
import 'features/pressure/data/pressao_sqlite.dart';
import 'features/profile/data/perfil_repositorio.dart';
import 'features/profile/data/perfil_repositorio_sqlite.dart';
import 'features/rehab/data/reabilitacao_repositorio.dart';
import 'features/rehab/data/reabilitacao_sqlite.dart';
import 'features/safety/data/contatos_repositorio.dart';
import 'features/safety/data/contatos_sqlite.dart';
import 'features/sports/data/atividades_repositorio.dart';
import 'features/sports/data/atividades_sqlite.dart';
import 'features/vitamins/data/vitaminas_repositorio.dart';
import 'features/vitamins/data/vitaminas_sqlite.dart';
import 'features/wellness/data/bem_estar_repositorio.dart';
import 'features/wellness/data/bem_estar_sqlite.dart';

/// Cultivando Saúde — casca visual + módulo de remédios.
///
/// **Responsividade (v12):** o app é desenhado para celular. No desktop, o
/// conteúdo inteiro fica centralizado numa coluna de no máximo 600 px, como um
/// "celular virtual" no meio da janela. No celular a largura já é menor que
/// 600, então nada muda.
///
/// A moldura é aplicada no `builder` do MaterialApp — assim vale para TODAS as
/// rotas (dashboard, lista, formulário, detalhe), sem repetir código em cada
/// tela.
///
/// **Armazenamento:** no Android, SQLite (remédios e perfil). Na web/preview,
/// memória. A escolha acontece aqui, uma vez — as telas só conhecem as
/// interfaces dos repositórios.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    usarPacientesRepo(PacientesSqlite());
    usarRepositorio(RepoSqlite());
    usarPerfilRepo(PerfilSqlite());
    usarPressaoRepo(PressaoSqlite());
    usarAgendaRepo(AgendaSqlite());
    usarContatosRepo(ContatosSqlite());
    usarVitaminasRepo(VitaminasSqlite());
    usarAtividadesRepo(AtividadesSqlite());
    usarBemEstarRepo(BemEstarSqlite());
    usarPlanoRepo(PlanoSqlite());
    usarExamesRepo(ExamesSqlite());
    usarNotificacoesCompromissos(NotificacoesAndroid());
    usarCompartilharWhatsapp(CompartilharWhatsappAndroid());
    usarReabilitacaoRepo(ReabilitacaoSqlite());
  }
  // Garante que exista um paciente ativo antes da primeira tela: os nomes de
  // arquivo do banco dependem dele.
  await garantirPacienteAtual();

  // Reagenda os avisos dos compromissos futuros (o celular pode ter
  // reiniciado, ou a permissao de notificacao pode ter sido dada depois).
  if (!kIsWeb) {
    try {
      final List<Compromisso> agenda = await agendaRepo.listar();
      for (final Compromisso c in agenda) {
        if (c.quando.isAfter(DateTime.now())) {
          await notificacoesCompromissos.agendar(c);
        }
      }
    } catch (_) {/* sem banco ainda */}
  }
  runApp(const CultivandoSaudeApp());
}

/// Largura máxima do conteúdo em telas grandes.
const double kLarguraMaximaConteudo = 600;

class CultivandoSaudeApp extends StatelessWidget {
  const CultivandoSaudeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cultivando Saúde',
      locale: const Locale('pt', 'BR'),
      supportedLocales: const <Locale>[Locale('pt', 'BR')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.fundo,
        // Nada de NoSplash: o ripple é justamente o retorno de toque.
        splashColor: Colors.white.withValues(alpha: 0.35),
        highlightColor: Colors.white.withValues(alpha: 0.10),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF007F),
          brightness: Brightness.light,
        ).copyWith(
          surface: AppColors.card,
          onSurface: AppColors.texto,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.texto,
          contentTextStyle: TextStyle(fontSize: 18, color: Colors.white),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      builder: (BuildContext context, Widget? child) {
        // Fundo igual ao do app preenche a janela; o conteúdo fica centrado.
        return ColoredBox(
          color: AppColors.fundo,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: kLarguraMaximaConteudo,
              ),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      home: const AppShell(),
    );
  }
}
