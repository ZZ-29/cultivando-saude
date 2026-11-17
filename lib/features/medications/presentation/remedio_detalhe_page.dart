import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/repositorio.dart';
import '../domain/medicamento.dart';
import '../domain/motor.dart';

/// Detalhe do tratamento, no padrão visual da Dashboard.
///
/// Lógica intacta: doses de hoje, fases e inclusão de fase nova (cálculo do
/// Hermes + regra da madrugada). A casca é que mudou.
class RemedioDetalhePage extends StatefulWidget {
  const RemedioDetalhePage({required this.medicamento, super.key});

  final Medicamento medicamento;

  @override
  State<RemedioDetalhePage> createState() => _RemedioDetalhePageState();
}

class _RemedioDetalhePageState extends State<RemedioDetalhePage> {
  static const Color _azul = Color(0xFF2962FF);
  static const Color _verde = Color(0xFF2E9E4F);
  static const Color _vermelho = Color(0xFFE53935);
  static const Color _indigo = Color(0xFF5E35B1);

  late Medicamento _med = widget.medicamento;
  Set<String> _tomadas = <String>{};
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final int? id = _med.id;
    if (id != null) {
      _tomadas = await medicamentosRepo.tomadas(id);
    }
    if (!mounted) return;
    setState(() => _carregando = false);
  }

  Future<void> _marcarTomada(String chave) async {
    final int? id = _med.id;
    if (id == null) return;
    await medicamentosRepo.marcarTomada(id, chave);
    await _carregar();
  }

  Future<void> _registrarSos() async {
    final int? id = _med.id;
    if (id == null) return;
    final DateTime agora = DateTime.now();
    await medicamentosRepo.marcarTomada(id, '${isoDia(agora)}|${hhmm(agora)}');
    await _carregar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dose SOS registrada às ${hhmm(agora)}.')),
    );
  }

  // ------------------------------------------------------- Adicionar fase --

  Future<void> _adicionarFase() async {
    final TextEditingController diasCtrl = TextEditingController(text: '7');
    TipoFrequencia tipo = TipoFrequencia.umaAoDia;
    TimeOfDay horario = const TimeOfDay(hour: 8, minute: 0);

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setEstado) => AlertDialog(
          title: const Text('Nova fase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'A primeira dose é calculada a partir da última dose da fase '
                'anterior.',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  ChoiceChip(
                    label: const Text('1x ao dia'),
                    selected: tipo == TipoFrequencia.umaAoDia,
                    onSelected: (bool _) =>
                        setEstado(() => tipo = TipoFrequencia.umaAoDia),
                  ),
                  ChoiceChip(
                    label: const Text('de 8 em 8h'),
                    selected: tipo == TipoFrequencia.intervaloHoras,
                    onSelected: (bool _) =>
                        setEstado(() => tipo = TipoFrequencia.intervaloHoras),
                  ),
                  ChoiceChip(
                    label: const Text('seg/qua/sex'),
                    selected: tipo == TipoFrequencia.diasSemana,
                    onSelected: (bool _) =>
                        setEstado(() => tipo = TipoFrequencia.diasSemana),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  final TimeOfDay? escolhido =
                      await showTimePicker(context: ctx, initialTime: horario);
                  if (escolhido != null) setEstado(() => horario = escolhido);
                },
                child: Text(
                  'Horário: ${horario.hour.toString().padLeft(2, '0')}:'
                  '${horario.minute.toString().padLeft(2, '0')}',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: diasCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duração desta fase (dias)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Calcular'),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true) {
      diasCtrl.dispose();
      return;
    }

    final String hh =
        '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}';

    final Frequencia freq = tipo == TipoFrequencia.intervaloHoras
        ? Frequencia(
            tipo: TipoFrequencia.intervaloHoras,
            intervaloHoras: 8,
            primeiraDose: hh,
          )
        : tipo == TipoFrequencia.diasSemana
            ? Frequencia(
                tipo: TipoFrequencia.diasSemana,
                horarios: <String>[hh],
                diasSemana: <int>[1, 3, 5],
              )
            : Frequencia(
                tipo: TipoFrequencia.umaAoDia,
                horarios: <String>[hh],
              );

    final int? dias = int.tryParse(diasCtrl.text.trim());
    diasCtrl.dispose();

    final CalculoNovaFase calculo =
        MotorRemedios.calcularNovaFase(_med, freq);

    DateTime inicio = calculo.inicio;

    // Regra da madrugada: 00:00 às 05:59 pede confirmação.
    if (calculo.caiuDeMadrugada && calculo.sugestao != null) {
      if (!mounted) return;
      final bool? aceitarSugestao = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('Horário de madrugada'),
          content: Text(
            'O horário calculado (${hhmm(calculo.inicio)}) é de madrugada.\n\n'
            'Sugerimos 06:00 para não interromper o sono. '
            'Deseja aceitar ou manter ${hhmm(calculo.inicio)}?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Manter ${hhmm(calculo.inicio)}'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Aceitar 06:00'),
            ),
          ],
        ),
      );
      if (aceitarSugestao == true) inicio = calculo.sugestao!;
    }

    final Fase nova = Fase(
      frequencia: freq,
      inicio: inicio,
      duracaoDias: dias,
    );

    final Medicamento atualizado = _med.copiarCom(
      fases: <Fase>[..._med.fases, nova],
    );

    try {
      await medicamentosRepo.salvar(atualizado);
      if (!mounted) return;
      setState(() => _med = atualizado);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fase adicionada. 1ª dose em '
              '${ddmmyyyy(inicio)} às ${hhmm(inicio)}.'),
        ),
      );
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não consegui salvar a fase: $erro')),
      );
    }
  }

  // ------------------------------------------------------------------ UI --

  @override
  Widget build(BuildContext context) {
    final DateTime agora = DateTime.now();
    final List<Ocorrencia> hoje =
        MotorRemedios.ocorrenciasDoDia(_med, agora);

    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _cabecalho(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: <Widget>[
                  if (_med.temPrescricao || _med.temMedico)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _azul.withValues(alpha: 0.28),
                          width: 1.1,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            _med.temPrescricao
                                ? Icons.photo_camera_rounded
                                : Icons.badge_rounded,
                            size: 17,
                            color: _azul,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _med.temMedico
                                      ? 'Prescrito por ${_med.medico}'
                                          '${(_med.crm ?? '').trim().isEmpty ? '' : ' · ${_med.crm}'}'
                                      : 'Prescrição anexada a este remédio',
                                  maxLines: 2,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.25,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.texto,
                                  ),
                                ),
                                if (_med.temPrescricao)
                                  Text(
                                    'foto da receita salva no celular',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: _azul.withValues(alpha: 0.8),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  // --- Hoje --------------------------------------------
                  _Bloco(
                    titulo: 'Hoje — ${ddmmyyyy(agora)}',
                    cor: _verde,
                    filho: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (_med.duracao == TipoDuracao.sos)
                          SizedBox(
                            height: 56,
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _registrarSos,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _vermelho,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.warning_amber_rounded,
                                  size: 22),
                              label: const Text(
                                'Registrar dose SOS agora',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          )
                        else if (_carregando)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Carregando…',
                                style: TextStyle(fontSize: 15)),
                          )
                        else if (hoje.isEmpty)
                          Text(
                            'Nenhuma dose hoje (pausa, dia da semana ou fora '
                            'da fase).',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.3,
                              color: AppColors.textoSuave,
                            ),
                          )
                        else
                          ...hoje.map(
                            (Ocorrencia o) => _linhaDose(o, agora),
                          ),
                      ],
                    ),
                  ),

                  // --- Fases -------------------------------------------
                  _Bloco(
                    titulo: 'Fases do tratamento',
                    cor: _indigo,
                    filho: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ..._med.fases.asMap().entries.map(
                              (MapEntry<int, Fase> e) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      margin:
                                          const EdgeInsets.only(top: 6, right: 8),
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: _indigo,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Fase ${e.key + 1}: '
                                        '${MotorRemedios.descreverFase(e.value)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.3,
                                          color: AppColors.texto,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _adicionarFase,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.card,
                              foregroundColor: _indigo,
                              side: BorderSide(
                                color: _indigo.withValues(alpha: 0.40),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 21),
                            label: const Text(
                              'Adicionar fase',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _cabecalho() {
    final String sub = '${_resumoDuracao(_med)}'
        '${_med.dosagem.isEmpty ? '' : ' · ${_med.dosagem}'}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Voltar',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.texto,
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _med.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 700),
                    ],
                    fontSize: 24,
                    height: 1.1,
                    color: AppColors.texto,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 420),
                    ],
                    fontSize: 12.5,
                    color: AppColors.textoApagado,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaDose(Ocorrencia o, DateTime agora) {
    final EstadoDose estado = MotorRemedios.estadoDe(o, agora, _tomadas);

    final (String rotulo, Color cor, IconData icone) = switch (estado) {
      EstadoDose.tomado => ('Tomado', _verde, Icons.check_circle_rounded),
      EstadoDose.atrasado => ('Atrasado', _vermelho, Icons.error_rounded),
      EstadoDose.agendado => ('Agendado', _azul, Icons.schedule_rounded),
      EstadoDose.suspenso => ('Suspenso', const Color(0xFF8A7F86),
          Icons.pause_circle_rounded),
    };

    final bool podeTomar =
        estado == EstadoDose.atrasado || estado == EstadoDose.agendado;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cor.withValues(alpha: 0.30), width: 1.1),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 56,
              child: Text(
                hhmm(o.quando),
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontVariations: <FontVariation>[
                    FontVariation('wght', 800),
                  ],
                  fontSize: 18,
                  height: 1.1,
                  color: AppColors.texto,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icone, color: cor, size: 17),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                rotulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontVariations: const <FontVariation>[
                    FontVariation('wght', 700),
                  ],
                  fontSize: 14,
                  color: cor,
                ),
              ),
            ),
            if (podeTomar)
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: () => _marcarTomada(o.chave),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tomei',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
        return 'Contínuo';
      case TipoDuracao.temporario:
        return 'Temporário · ${med.diasTratamento ?? '?'} dias';
      case TipoDuracao.ciclo:
        return 'Ciclo: ${med.cicloDias ?? 0} dias tomando + '
            '${med.cicloPausa ?? 0} de pausa';
      case TipoDuracao.sos:
        return 'SOS (só quando precisar)';
    }
  }
}

/// Cartão de seção: título colorido + conteúdo sobre fundo tintado.
class _Bloco extends StatelessWidget {
  const _Bloco({
    required this.titulo,
    required this.cor,
    required this.filho,
  });

  final String titulo;
  final Color cor;
  final Widget filho;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.tinta(cor, 0.07),
            AppColors.tinta(cor, 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withValues(alpha: 0.26), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontVariations: const <FontVariation>[
                      FontVariation('wght', 700),
                    ],
                    fontSize: 14.5,
                    color: cor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          filho,
        ],
      ),
    );
  }
}
