import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/navigation/barra_inferior.dart';
import '../../../core/theme/card_config.dart';
import '../../../core/widgets/cartao_dashboard.dart';
import '../../../core/widgets/cartao_grade.dart';
import '../../../core/widgets/cartao_remedios.dart';
import '../../../core/widgets/cartao_sos.dart';
import '../../../core/widgets/cartao_usuario.dart';
import '../../../core/widgets/toque_escala.dart';
import '../../agenda/data/agenda_repositorio.dart';
import '../../agenda/domain/compromisso.dart';
import '../../agenda/presentation/agenda_page.dart';
import '../../exams/data/exames_repositorio.dart';
import '../../exams/domain/exame.dart';
import '../../exams/presentation/exames_page.dart';
import '../../medications/presentation/remedios_page.dart';
import '../../nutrition/data/plano_repositorio.dart';
import '../../nutrition/domain/refeicao.dart';
import '../../nutrition/presentation/alimentacao_page.dart';
import '../../patients/data/pacientes_repositorio.dart';
import '../../patients/presentation/pacientes_page.dart';
import '../../pressure/data/pressao_repositorio.dart';
import '../../pressure/domain/medicao.dart';
import '../../pressure/presentation/pressao_page.dart';
import '../../profile/data/perfil_repositorio.dart';
import '../../profile/domain/perfil.dart';
import '../../profile/presentation/perfil_page.dart';
import '../../rehab/data/reabilitacao_repositorio.dart';
import '../../rehab/domain/exercicio.dart';
import '../../rehab/presentation/reabilitacao_page.dart';
import '../../safety/presentation/seguranca_page.dart';
import '../../safety/presentation/sos_page.dart';
import '../../sports/data/atividades_repositorio.dart';
import '../../sports/domain/atividade.dart';
import '../../sports/presentation/esportes_page.dart';
import '../../vitamins/data/vitaminas_repositorio.dart';
import '../../vitamins/domain/vitamina.dart';
import '../../vitamins/presentation/vitaminas_page.dart';
import '../../wellness/data/bem_estar_repositorio.dart';
import '../../wellness/domain/registro_bem_estar.dart';
import '../../wellness/presentation/bem_estar_page.dart';

/// Tela principal — marca no topo e todos os cards em pares.
///
/// Cada card abre seu módulo e, ao voltar, a Dashboard recarrega o resumo
/// daquele módulo. Por isso a tela é stateful e guarda uma chave para o card
/// de remédios (que também se atualiza sozinho a cada minuto).
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<CartaoRemediosState> _chaveRemedios =
      GlobalKey<CartaoRemediosState>();

  Perfil _perfil = const Perfil();
  Medicao? _ultimaPressao;
  Compromisso? _proximo;
  int _vitaminasTomadas = 0;
  int _vitaminasTotal = 0;
  int _minutosSemana = 0;
  int _refeicoes = 0;
  int _exercicios = 0;
  int _exerciciosFeitos = 0;
  int _examesLab = 0;
  int _examesEsp = 0;
  List<Atividade> _itensAtividades = <Atividade>[];
  RegistroBemEstar? _bemEstarHoje;

  @override
  void initState() {
    super.initState();
    alturaBarraInferior.addListener(_aoMedirBarra);
    _carregarTudo();
  }

  Future<void> _carregarTudo() async {
    await Future.wait<void>(<Future<void>>[
      _carregarPerfil(),
      _carregarPressao(),
      _carregarAgenda(),
      _carregarVitaminas(),
      _carregarAtividades(),
      _carregarBemEstar(),
      _carregarPlano(),
      _carregarReabilitacao(),
      _carregarExames(),
    ]);
  }

  Future<void> _carregarExames() async {
    try {
      final List<Exame> lista = await examesRepo.listar();
      if (!mounted) return;
      setState(() {
        _examesLab = lista
            .where((Exame e) => e.categoria == CategoriaExame.laboratorial)
            .length;
        _examesEsp = lista
            .where((Exame e) => e.categoria == CategoriaExame.especialidade)
            .length;
      });
    } catch (_) {/* sem banco */}
  }

  Future<void> _carregarReabilitacao() async {
    try {
      final List<Exercicio> lista = await reabilitacaoRepo.listar();
      final Set<int> feitos = await reabilitacaoRepo.feitosNoDia(DateTime.now());
      if (!mounted) return;
      setState(() {
        _exercicios = lista.length;
        _exerciciosFeitos = feitos.length;
      });
    } catch (_) {/* sem banco */}
  }

  Future<void> _carregarPlano() async {
    try {
      final List<Refeicao> lista = await planoRepo.ler();
      if (!mounted) return;
      setState(() => _refeicoes = lista.length);
    } catch (_) {/* sem banco */}
  }

  Future<void> _carregarBemEstar() async {
    try {
      final RegistroBemEstar? hoje = await bemEstarRepo.deHoje();
      if (!mounted) return;
      setState(() => _bemEstarHoje = hoje);
    } catch (_) {/* sem banco */}
  }

  Future<void> _carregarPerfil() async {
    final Perfil p = await perfilRepo.ler();
    if (!mounted) return;
    setState(() => _perfil = p);
  }

  Future<void> _carregarPressao() async {
    try {
      final List<Medicao> lista = await pressaoRepo.listar();
      if (!mounted) return;
      setState(() => _ultimaPressao = lista.isEmpty ? null : lista.first);
    } catch (_) {/* sem banco: mantém o texto de exemplo */}
  }

  Future<void> _carregarAgenda() async {
    try {
      final List<Compromisso> lista = await agendaRepo.listar();
      final DateTime agora = DateTime.now();
      final List<Compromisso> futuros = lista
          .where((Compromisso c) => c.quando.isAfter(agora))
          .toList(growable: false);
      if (!mounted) return;
      setState(() => _proximo = futuros.isEmpty ? null : futuros.first);
    } catch (_) {/* idem */}
  }

  Future<void> _carregarVitaminas() async {
    try {
      final List<Vitamina> lista = await vitaminasRepo.listar();
      final DateTime hoje = DateTime.now();
      int doses = 0;
      int tomadas = 0;
      for (final Vitamina v in lista) {
        for (final String h in v.horariosDoDia) {
          doses++;
          if (v.tomadaNoHorario(h, hoje)) tomadas++;
        }
      }
      if (!mounted) return;
      setState(() {
        _vitaminasTotal = doses;
        _vitaminasTomadas = tomadas;
      });
    } catch (_) {/* idem */}
  }

  Future<void> _carregarAtividades() async {
    try {
      final List<Atividade> lista = await atividadesRepo.listar();
      if (!mounted) return;
      setState(() {
        _itensAtividades = lista;
        _minutosSemana = minutosNosUltimos(lista, 7);
      });
    } catch (_) {/* idem */}
  }

  void _aoMedirBarra() {
    if (mounted) setState(() {});
  }

  /// Espaço extra no fim da lista.
  ///
  /// Sem isso, a rolagem termina exatamente na última fileira: ao girar a roda,
  /// tudo para e o último card parece "fixo" — ele só está no fim da lista, sem
  /// espaço para continuar subindo.
  ///
  /// A folga é **discreta**: 10% da altura da tela (64 a 140px). Um valor
  /// grande (35%) resolvia o toque, mas deixava um vazio feio embaixo dos
  /// cards.
  double get _folgaFinal {
    final double altura = MediaQuery.sizeOf(context).height;
    return (altura * 0.10).clamp(64.0, 140.0);
  }

  @override
  Widget build(BuildContext context) {
    final CardConfig marca = cardsDoDashboard.firstWhere(
      (CardConfig c) => c.tipo == TipoCard.boasVindas,
    );
    final List<CardConfig> simples = cardsDoDashboard
        .where((CardConfig c) => c.tipo == TipoCard.simples)
        .toList(growable: false);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _carregarTudo,
        color: const Color(0xFF2962FF),
        // **CustomScrollView + SliverGrid**, não ListView com GridView dentro.
        //
        // Com a grade aninhada (`GridView(shrinkWrap: true)`), a lista
        // chutava a altura total do conteúdo: ao rolar, a altura "verdadeira"
        // aparecia e o fim da lista pulava alguns pixels para cima — o último
        // card parecia parado, porque a própria rolagem recuava embaixo dele.
        // Com slivers a altura é exata desde o primeiro quadro.
        child: CustomScrollView(
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    // Quem está sendo cuidado — multi-perfil.
                    ActionChip(
                      avatar: const Icon(Icons.person_rounded, size: 16),
                      label: Text(
                        nomePacienteAtual,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: _abrirPacientes,
                      backgroundColor: AppColors.card,
                      side: BorderSide(
                        color: AppColors.lilasMedio.withValues(alpha: 0.35),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(height: 4),
                    // A marca fica sempre no topo (identidade, não saudação).
                    CartaoDashboard(config: marca),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                // **Duas colunas sempre.** Com `maxCrossAxisExtent` o número
                // de colunas era calculado pela largura: em celular estreito
                // (ou com "tamanho da tela" aumentado nas configurações do
                // Android) sobrava 1 coluna só — cards empilhados e um vazio
                // enorme ao lado de cada um.
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 100,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int i) {
                    if (i == 0) {
                      return ToqueEscala(child: CartaoSos(aoTocar: _abrirSos));
                    }
                    if (i == 1) {
                      return ToqueEscala(
                        child: CartaoUsuario(
                          nome: _perfil.preenchido ? _perfil.nome : null,
                          idade: _perfil.idade,
                          tipoSanguineo: _perfil.tipoSanguineo,
                          aoTocar: _abrirPerfil,
                        ),
                      );
                    }
                    return _card(simples[i - 2]);
                  },
                  childCount: simples.length + 2,
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                14,
                16,
                respiroInferior + _folgaFinal,
              ),
              sliver: SliverToBoxAdapter(child: _rodape()),
            ),
          ],
        ),
      ),
    );
  }

  /// Rodapé da grade: privacidade, aviso médico e o atalho de Segurança.
  ///
  /// Estes três itens moravam dentro da barra fixa do rodapé, que saiu.
  Widget _rodape() {
    return Column(
      children: <Widget>[
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _abrirSeguranca,
            child: Container(
              padding: const EdgeInsets.fromLTRB(13, 11, 10, 11),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00897B).withValues(alpha: 0.30),
                  width: 1.1,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: const Color(0xFF00897B).withValues(alpha: 0.30),
                        width: 1,
                      ),
                    ),
                    child: const Icon(Icons.shield_rounded,
                        color: Color(0xFF00897B), size: 19),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Segurança',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontVariations: <FontVariation>[
                              FontVariation('wght', 800),
                            ],
                            fontSize: 15,
                            color: Color(0xFF00564C),
                          ),
                        ),
                        Text(
                          'contatos de emergência e telefones',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textoSuave,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF00897B), size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.lock_outline_rounded,
                size: 12, color: AppColors.textoApagado),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'Nada é enviado para a internet: seus dados ficam só neste '
                'celular.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.25,
                  color: AppColors.textoApagado,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.info_outline_rounded,
                size: 12, color: AppColors.textoApagado),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'Este app não substitui orientação médica.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.25,
                  color: AppColors.textoApagado,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _abrirSeguranca() =>
      _abrir(const SegurancaPage(), _carregarTudo);

  /// Abre a tela de exames da categoria e, ao voltar, atualiza a contagem.
  Future<void> _abrirExames(CategoriaExame categoria) => _abrir(
        ExamesPage(categoria: categoria),
        _carregarExames,
      );

  /// Cada card simples: texto real (quando há dado) e a tela que abre.
  Widget _card(CardConfig config) {
    switch (config.id) {
      case 'exames_lab':
        return ToqueEscala(
          child: CartaoGrade(
            config: config,
            texto: _examesLab == 0
                ? 'nenhum resultado'
                : '$_examesLab ${_examesLab == 1 ? 'guardado' : 'guardados'}',
            aoTocar: () => _abrirExames(CategoriaExame.laboratorial),
          ),
        );
      case 'exames_especialidade':
        return ToqueEscala(
          child: CartaoGrade(
            config: config,
            texto: _examesEsp == 0
                ? 'nenhum exame'
                : '$_examesEsp ${_examesEsp == 1 ? 'guardado' : 'guardados'}',
            aoTocar: () => _abrirExames(CategoriaExame.especialidade),
          ),
        );
      case 'remedios':
        return ToqueEscala(
          child: CartaoRemedios(
            key: _chaveRemedios,
            config: config,
            aoTocar: _abrirRemedios,
          ),
        );
      case 'pressao':
        return ToqueEscala(
          child: CartaoGrade(
            config: config,
            texto: _ultimaPressao == null
                ? 'sem medida'
                : 'Última: ${_ultimaPressao!.sistolica}/'
                    '${_ultimaPressao!.diastolica}',
            aoTocar: _abrirPressao,
          ),
        );
      case 'agenda':
        return ToqueEscala(
          child: CartaoGrade(
            config: config,
            texto: _proximo == null
                ? 'sem compromisso'
                : quandoResumido(_proximo!.quando),
            aoTocar: _abrirAgenda,
          ),
        );
      case 'vitaminas':
        return ToqueEscala(
          child: CartaoGrade(
            config: config,
            texto: _vitaminasTotal == 0
                ? 'nenhuma cadastrada'
                : '$_vitaminasTomadas de $_vitaminasTotal hoje',
            aoTocar: _abrirVitaminas,
          ),
        );
      case 'esportes':
        final double? kcal = caloriasNosUltimos(_itensAtividades, 7, _perfil.peso);
        return ToqueEscala(
          child: CartaoGrade(
            config: config,
            texto: _minutosSemana == 0
                ? 'nenhuma atividade'
                : kcal == null
                    ? '$_minutosSemana min na semana'
                    : '$_minutosSemana min · ${kcal.round()} kcal',
            aoTocar: _abrirEsportes,
          ),
        );
      case 'alimentacao':
        return ToqueEscala(
          child: CartaoGrade(
            config: config,
            texto: _refeicoes == 0
                ? 'sem plano ainda'
                : '$_refeicoes ${_refeicoes == 1 ? 'refeição' : 'refeições'}',
            aoTocar: () => _abrir(const AlimentacaoPage(), _carregarPlano),
          ),
        );
      case 'reabilitacao':
        return ToqueEscala(
          child: CartaoGrade(
            config: config,
            texto: _exercicios == 0
                ? 'preencha o que foi orientado'
                : '$_exerciciosFeitos de $_exercicios feitos hoje',
            aoTocar: () => _abrir(
              const ReabilitacaoPage(),
              _carregarReabilitacao,
            ),
          ),
        );
      case 'bem_estar':
        final RegistroBemEstar? hoje = _bemEstarHoje;
        return ToqueEscala(
          child: CartaoGrade(
            config: config,
            texto: hoje == null || !hoje.temAlgo
                ? 'sem registro hoje'
                : hoje.resumo,
            aoTocar: () => _abrir(const BemEstarPage(), _carregarBemEstar),
          ),
        );
      default:
        return ToqueEscala(
          child: CartaoGrade(
            config: config,
            aoTocar: () => _aviso(context, config.titulo),
          ),
        );
    }
  }

  Future<void> _abrir(Widget tela, Future<void> Function() recarregar) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (BuildContext _) => tela),
    );
    await recarregar();
  }

  Future<void> _abrirPacientes() async {
    final bool? trocou = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext _) => const PacientesPage(),
      ),
    );
    if (trocou != true) return;
    await _carregarTudo();
    await _chaveRemedios.currentState?.recarregar();
  }

  Future<void> _abrirSos() => _abrir(const SosPage(), _carregarTudo);
  Future<void> _abrirPerfil() => _abrir(const PerfilPage(), _carregarPerfil);
  Future<void> _abrirPressao() => _abrir(const PressaoPage(), _carregarPressao);
  Future<void> _abrirAgenda() => _abrir(const AgendaPage(), _carregarAgenda);
  Future<void> _abrirVitaminas() =>
      _abrir(const VitaminasPage(), _carregarVitaminas);
  Future<void> _abrirEsportes() =>
      _abrir(const EsportesPage(), _carregarAtividades);

  Future<void> _abrirRemedios() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => const RemediosPage(),
      ),
    );
    await _chaveRemedios.currentState?.recarregar();
  }

  void _aviso(BuildContext context, String titulo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$titulo": função entra na próxima fase.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
