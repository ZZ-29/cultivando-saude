import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/navigation/barra_inferior.dart';
import '../../../../core/config/config_repositorio.dart';
import '../data/alarmes_remedios.dart';
import '../data/lembretes_remedios.dart';
import '../data/repositorio.dart';
import '../domain/medicamento.dart';
import '../domain/motor.dart';
import '../domain/periodos.dart';
import 'formulario_remedio_page.dart';
import 'remedio_detalhe_page.dart';

/// Remédios — **modelo Hermes**: o dia antes da lista.
///
/// A tela abre mostrando as doses de HOJE agrupadas por período (madrugada,
/// manhã, tarde, noite), com contador "X de Y tomadas" em cada período e o
/// período atual já aberto. Depois vêm:
///
///   • **SOS** — remédios sem horário, registrados quando acontecem;
///   • **Outros remédios** — os que não caem hoje (dia da semana, pausa do
///     ciclo) ou cujo tratamento terminou.
///
/// A casca é a do app (cartões tintados, Nunito, botões grandes); a estrutura
/// é a do Hermes.
class RemediosPage extends StatefulWidget {
  const RemediosPage({super.key});

  @override
  State<RemediosPage> createState() => _RemediosPageState();
}

class _RemediosPageState extends State<RemediosPage> {
  static const Color _azul = Color(0xFF2962FF);
  static const Color _azulEscuro = Color(0xFF1B45C9);

  List<Medicamento> _meds = <Medicamento>[];
  final Map<int, Set<String>> _tomadas = <int, Set<String>>{};
  bool _carregando = true;
  final Set<PeriodoDia> _abertos = <PeriodoDia>{};

  /// Alarmes das doses ligados? (preferência salva)
  bool _alarmesLigados = false;
  bool _alarmesExatos = true;

  @override
  void initState() {
    super.initState();
    alturaBarraInferior.addListener(_aoMedirBarra);
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final List<Medicamento> lista = await medicamentosRepo.listar();
      final Map<int, Set<String>> tomadas = <int, Set<String>>{};
      for (final Medicamento m in lista) {
        final int? id = m.id;
        if (id != null) tomadas[id] = await medicamentosRepo.tomadas(id);
      }
      // Alarme é o coração do app: quando existe remédio cadastrado e a
      // preferência nunca foi definida, ele vem **ligado**. Foi a causa de um
      // alarme não tocar: a pessoa cadastrou o remédio e nunca ligou o bloco.
      final String? salvo = await configRepo.ler(chaveLembretesRemedios);
      final bool ligadoPorPadrao = salvo == null && lista.isNotEmpty;
      final bool alarmes = salvo == null ? ligadoPorPadrao : salvo == '1';
      if (ligadoPorPadrao) {
        await configRepo.salvar(chaveLembretesRemedios, '1');
      }
      if (!mounted) return;
      setState(() {
        _meds = lista;
        _tomadas
          ..clear()
          ..addAll(tomadas);
        _alarmesLigados = alarmes;
        _carregando = false;
        // Abre o período de agora (uma vez só).
        if (_abertos.isEmpty) {
          _abertos.add(periodoDaHora(DateTime.now().hour));
        }
      });
      // Mantém os alarmes alinhados com a lista de remédios.
      if (alarmes) await _sincronizarAlarmes();
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  /// (Re)agenda os alarmes das doses com a lista atual de remédios.
  Future<void> _sincronizarAlarmes() async {
    final List<AlarmeDose> alarmes = alarmesDe(_meds);
    if (!_alarmesLigados) {
      await lembretesRemedios.desligar();
      return;
    }
    final bool exato = await lembretesRemedios.sincronizar(alarmes);
    _alarmesExatos = exato;
  }

  /// Liga/desliga os alarmes das doses.
  Future<void> _alternarAlarmes(bool ligar) async {
    setState(() => _alarmesLigados = ligar);
    await configRepo.salvar(chaveLembretesRemedios, ligar ? '1' : '0');

    if (ligar) {
      final bool exato = await lembretesRemedios.sincronizar(alarmesDe(_meds));
      _alarmesExatos = exato;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            exato
                ? 'Alarmes ligados nos horários das doses.'
                : 'Alarmes ligados. O celular pode avisar com alguns minutos de '
                    'diferença.',
          ),
        ),
      );
    } else {
      await lembretesRemedios.desligar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarmes das doses desligados.')),
      );
    }
  }

  bool get _temSos => _meds.any((Medicamento m) => m.duracao == TipoDuracao.sos);

  List<DoseDoDia> get _dosesDeHoje {
    final DateTime hoje = DateTime.now();
    final List<DoseDoDia> saida = <DoseDoDia>[];

    for (final Medicamento m in _meds) {
      if (m.duracao == TipoDuracao.sos) continue;
      final Set<String> chaves = _tomadas[m.id] ?? <String>{};
      bool primeira = true;
      for (final Ocorrencia o in MotorRemedios.ocorrenciasDoDia(m, hoje)) {
        saida.add(
          DoseDoDia(
            remedio: m,
            ocorrencia: o,
            estado: MotorRemedios.estadoDe(o, hoje, chaves),
            primeiraDoDia: primeira,
          ),
        );
        primeira = false;
      }
    }

    saida.sort((DoseDoDia a, DoseDoDia b) {
      final int porHora = a.horaTexto.compareTo(b.horaTexto);
      return porHora != 0
          ? porHora
          : a.remedio.nome.toLowerCase().compareTo(b.remedio.nome.toLowerCase());
    });
    return saida;
  }

  Future<void> _marcarTomada(DoseDoDia d) async {
    final int? id = d.remedio.id;
    if (id == null) return;
    await medicamentosRepo.marcarTomada(id, d.ocorrencia.chave);
    await _carregar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${d.remedio.nome} · ${d.horaTexto} registrado.')),
    );
  }

  Future<void> _registrarSos(Medicamento m) async {
    final int? id = m.id;
    if (id == null) return;
    final DateTime agora = DateTime.now();
    await medicamentosRepo.marcarTomada(
      id,
      '${isoDia(agora)}|${hhmm(agora)}',
    );
    await _carregar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dose de ${m.nome} registrada às ${hhmm(agora)}.')),
    );
  }

  Future<void> _abrirCadastro() async {
    final bool? salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext _) => const FormularioRemedioPage(),
      ),
    );
    if (salvou == true) await _carregar();
  }

  Future<void> _abrirDetalhe(Medicamento m) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => RemedioDetalhePage(medicamento: m),
      ),
    );
    await _carregar();
  }

  void _aoMedirBarra() {
    if (mounted) setState(() {});
  }

  /// Agenda um alarme de teste (1 minuto) e diz o que aconteceu.
  ///
  /// Se falhar, a mensagem mostra **por quê** — é diagnóstico, não enfeite.
  Future<void> _testarAlarme() async {
    final bool permitidas = await lembretesRemedios.notificacoesPermitidas();
    if (!permitidas && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'As notificações estão bloqueadas. Autorize em Configurações → '
            'Apps → Cultivando Saúde → Notificações.',
          ),
          duration: Duration(seconds: 6),
        ),
      );
      return;
    }

    final String? erro = await lembretesRemedios.testar(segundos: 60);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Text(
          erro == null
              ? 'Alarme de teste agendado: deve tocar em 1 minuto.'
              : 'Falhou: $erro',
        ),
      ),
    );
  }

  /// Bloco do alarme das doses: o coração do app.
  Widget _blocoAlarmes() {
    final int quantidade = alarmesDe(_meds).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      padding: const EdgeInsets.fromLTRB(13, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _azul.withValues(alpha: 0.26),
          width: 1.1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.alarm_on_rounded, size: 19, color: _azulEscuro),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Avisar nos horários das doses',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 800),
                    ],
                    fontSize: 14.5,
                    color: AppColors.texto,
                  ),
                ),
                Text(
                  _alarmesLigados
                      ? (quantidade == 0
                          ? 'nenhuma dose para avisar'
                          : '$quantidade ${quantidade == 1 ? 'alarme' : 'alarmes'} '
                              'agendados')
                      : 'desligado',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textoSuave,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Switch(
                value: _alarmesLigados,
                activeThumbColor: _azul,
                onChanged: _alternarAlarmes,
              ),
              // Prova rápida: agenda um aviso para daqui a 1 minuto.
              if (_alarmesLigados)
                TextButton(
                  onPressed: _testarAlarme,
                  style: TextButton.styleFrom(
                    foregroundColor: _azul,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: const Text(
                    'testar',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<DoseDoDia> doses = _carregando ? <DoseDoDia>[] : _dosesDeHoje;
    final int tomadas = doses
        .where((DoseDoDia d) => d.estado == EstadoDose.tomado)
        .length;

    // Remédios sem dose hoje (dia da semana, pausa) e SOS.
    final Set<int?> idsComDoseHoje =
        doses.map((DoseDoDia d) => d.remedio.id).toSet();
    final List<Medicamento> outros = _meds
        .where((Medicamento m) =>
            m.duracao != TipoDuracao.sos && !idsComDoseHoje.contains(m.id))
        .toList(growable: false);
    final List<Medicamento> sos = _meds
        .where((Medicamento m) => m.duracao == TipoDuracao.sos)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.fundo,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-remedios',
        onPressed: _abrirCadastro,
        backgroundColor: _azul,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Cadastrar',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontVariations: <FontVariation>[FontVariation('wght', 700)],
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _cabecalho(tomadas, doses.length),
            _blocoAlarmes(),
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator(color: _azul))
                  : ListView(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, respiroInferior),
                      children: <Widget>[
                        if (doses.isEmpty && sos.isEmpty && outros.isEmpty)
                          _vazio()
                        else ...<Widget>[
                          if (doses.isEmpty)
                            _avisoSemDose()
                          else
                            ...PeriodoDia.values.map(
                              (PeriodoDia p) => _periodo(p, doses),
                            ),
                          if (sos.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 6),
                            _tituloSecao('SOS', 'só quando precisar'),
                            ...sos.map(_cartaoSos),
                          ],
                          if (outros.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 6),
                            _tituloSecao(
                              'Outros remédios',
                              'não caem hoje ou já terminaram',
                            ),
                            ...outros.map(_cartaoOutro),
                          ],
                        ],
                        const SizedBox(height: 16),
                        if (doses.isNotEmpty)
                          Center(
                            child: Text(
                              '🌸 $tomadas de ${doses.length} tomadas hoje 🌸',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _azulEscuro.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cabecalho(int tomadas, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: <Widget>[
          if (Navigator.of(context).canPop())
            IconButton(
              tooltip: 'Voltar',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.texto,
            ),
          const SizedBox(width: 2),
          const Expanded(
            child: Text(
              'Remédios',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontVariations: <FontVariation>[FontVariation('wght', 700)],
                fontSize: 26,
                height: 1.1,
                color: AppColors.texto,
              ),
            ),
          ),
          if (total > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _azul.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _azul.withValues(alpha: 0.30)),
              ),
              child: Text(
                '$tomadas de $total tomadas',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontVariations: <FontVariation>[
                    FontVariation('wght', 800),
                  ],
                  fontSize: 12.5,
                  color: _azulEscuro,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tituloSecao(String titulo, String dica) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            titulo,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontVariations: const <FontVariation>[
                FontVariation('wght', 800),
              ],
              fontSize: 14,
              color: _azulEscuro,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              dica,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textoApagado,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- período --

  Widget _periodo(PeriodoDia p, List<DoseDoDia> todas) {
    final List<DoseDoDia> doPeriodo =
        todas.where((DoseDoDia d) => periodoDe(d.ocorrencia.quando) == p).toList();
    if (doPeriodo.isEmpty) return const SizedBox.shrink();

    final int tomadas =
        doPeriodo.where((DoseDoDia d) => d.estado == EstadoDose.tomado).length;
    final bool aberto = _abertos.contains(p);
    final bool atual = periodoDaHora(DateTime.now().hour) == p;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.tinta(_azul, atual ? 0.14 : 0.08),
            AppColors.tinta(_azul, atual ? 0.24 : 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _azul.withValues(alpha: atual ? 0.40 : 0.22),
          width: atual ? 1.4 : 1.1,
        ),
      ),
      child: Column(
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() {
              if (aberto) {
                _abertos.remove(p);
              } else {
                _abertos.add(p);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 11, 11, 11),
              child: Row(
                children: <Widget>[
                  Text(p.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          p.nome,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontVariations: <FontVariation>[
                              FontVariation('wght', 800),
                            ],
                            fontSize: 16,
                            height: 1.1,
                            color: _azulEscuro,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$tomadas de ${doPeriodo.length} tomadas · ${p.faixa}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: _azulEscuro.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (atual && tomadas < doPeriodo.length)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _azul,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'AGORA',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Icon(
                    aberto
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _azulEscuro,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          if (aberto)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                children: <Widget>[
                  ...doPeriodo.map(_cartaoDose),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cartaoDose(DoseDoDia d) {
    final Color cor = switch (d.estado) {
      EstadoDose.tomado => const Color(0xFF2E9E4F),
      EstadoDose.atrasado => const Color(0xFFE53935),
      EstadoDose.agendado => _azul,
      EstadoDose.suspenso => const Color(0xFF8A7F86),
    };
    final bool podeTomar =
        d.estado == EstadoDose.atrasado || d.estado == EstadoDose.agendado;

    final String detalhe = <String>[
      if (d.remedio.dosagem.trim().isNotEmpty) d.remedio.dosagem,
      d.remedio.fases.isEmpty ? '' : d.remedio.fases.last.frequencia.resumo,
    ].where((String s) => s.isNotEmpty).join(' · ');

    return Container(
      margin: const EdgeInsets.only(top: 7),
      padding: const EdgeInsets.fromLTRB(11, 9, 7, 9),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withValues(alpha: 0.30), width: 1.1),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 52,
                child: Text(
                  d.horaTexto,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 800),
                    ],
                    fontSize: 17,
                    height: 1.1,
                    color: AppColors.texto,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    InkWell(
                      onTap: () => _abrirDetalhe(d.remedio),
                      child: Text(
                        d.remedio.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontVariations: <FontVariation>[
                            FontVariation('wght', 800),
                          ],
                          fontSize: 15.5,
                          height: 1.15,
                          color: AppColors.texto,
                        ),
                      ),
                    ),
                    if (detalhe.isNotEmpty)
                      Text(
                        detalhe,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          height: 1.2,
                          color: AppColors.textoSuave,
                        ),
                      ),
                  ],
                ),
              ),
              if (podeTomar)
                SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () => _marcarTomada(d),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: const Text(
                      'TOMEI',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        d.estado == EstadoDose.tomado
                            ? Icons.check_circle_rounded
                            : Icons.pause_circle_rounded,
                        size: 16,
                        color: cor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        d.estado == EstadoDose.tomado ? 'Tomado' : 'Suspenso',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (d.primeiraDoDia && d.remedio.fases.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  MotorRemedios.descreverFase(d.remedio.fases.last),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    color: AppColors.textoApagado,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------- SOS --

  Widget _cartaoSos(Medicamento m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.tinta(const Color(0xFFE53935), 0.08),
            AppColors.tinta(const Color(0xFFE53935), 0.16),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE53935).withValues(alpha: 0.26),
          width: 1.1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  m.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 800),
                    ],
                    fontSize: 15.5,
                    color: Color(0xFFB71C1C),
                  ),
                ),
                Text(
                  <String>[
                    if (m.dosagem.trim().isNotEmpty) m.dosagem,
                    'só quando precisar',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF7A5A5A)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: () => _registrarSos(m),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text(
                'REGISTREI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ outros dias --

  Widget _cartaoOutro(Medicamento m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.fromLTRB(12, 9, 6, 9),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textoApagado.withValues(alpha: 0.25),
          width: 1.1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  m.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 700),
                    ],
                    fontSize: 14.5,
                    color: AppColors.texto,
                  ),
                ),
                Text(
                  'Não caem hoje · ${_resumoDuracao(m)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textoApagado,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _abrirDetalhe(m),
            style: TextButton.styleFrom(foregroundColor: _azul),
            child: const Text(
              'Abrir',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avisoSemDose() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _azul.withValues(alpha: 0.20), width: 1.1),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline_rounded, color: _azul, size: 20),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'Hoje não há dose agendada (pausa do ciclo, dia da semana ou '
              'nenhum remédio cadastrado).',
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                color: AppColors.textoSuave,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _azul.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _azul.withValues(alpha: 0.30),
                  width: 1.2,
                ),
              ),
              child: const Icon(Icons.medication_rounded,
                  color: _azul, size: 34),
            ),
            const SizedBox(height: 14),
            const Text(
              'Nenhum remédio cadastrado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontVariations: <FontVariation>[FontVariation('wght', 700)],
                fontSize: 20,
                color: AppColors.texto,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Toque em Cadastrar para adicionar o primeiro.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.3,
                color: AppColors.textoSuave,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _resumoDuracao(Medicamento med) {
    switch (med.duracao) {
      case TipoDuracao.continuo:
        return 'contínuo';
      case TipoDuracao.temporario:
        return 'temporário · ${med.diasTratamento ?? '?'} dias';
      case TipoDuracao.ciclo:
        return 'ciclo ${med.cicloDias ?? 0}+${med.cicloPausa ?? 0}';
      case TipoDuracao.sos:
        return 'SOS';
    }
  }
}
