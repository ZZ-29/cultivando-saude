import 'package:flutter/material.dart';

import '../data/repositorio.dart';
import '../domain/medicamento.dart';
import '../domain/motor.dart';

/// Detalhe do tratamento: doses de hoje, fases e inclusão de fase nova
/// (com o cálculo do Hermes: última dose + intervalo, e aviso de madrugada).
class RemedioDetalhePage extends StatefulWidget {
  const RemedioDetalhePage({required this.medicamento, super.key});

  final Medicamento medicamento;

  @override
  State<RemedioDetalhePage> createState() => _RemedioDetalhePageState();
}

class _RemedioDetalhePageState extends State<RemedioDetalhePage> {
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
      appBar: AppBar(title: Text(_med.nome)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            '${_resumoDuracao(_med)}${_med.dosagem.isEmpty ? '' : ' · ${_med.dosagem}'}',
            style: const TextStyle(fontSize: 16),
          ),
          const Divider(height: 32),

          // --- Doses de hoje ---------------------------------------------
          Text(
            'Hoje — ${ddmmyyyy(agora)}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (_med.duracao == TipoDuracao.sos)
            FilledButton(
              onPressed: _registrarSos,
              child: const Text('Registrar dose SOS agora'),
            )
          else if (_carregando)
            const Text('Carregando…')
          else if (hoje.isEmpty)
            const Text(
              'Nenhuma dose hoje (pausa, dia da semana ou fora da fase).',
              style: TextStyle(fontSize: 16),
            )
          else
            ...hoje.map((Ocorrencia o) => _linhaDose(o, agora)),

          const Divider(height: 32),

          // --- Fases ------------------------------------------------------
          const Text(
            'Fases do tratamento',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ..._med.fases.asMap().entries.map(
                (MapEntry<int, Fase> e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Fase ${e.key + 1}: ${MotorRemedios.descreverFase(e.value)}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _adicionarFase,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar fase'),
          ),
        ],
      ),
    );
  }

  Widget _linhaDose(Ocorrencia o, DateTime agora) {
    final EstadoDose estado = MotorRemedios.estadoDe(o, agora, _tomadas);
    final String rotulo = switch (estado) {
      EstadoDose.tomado => 'Tomado',
      EstadoDose.atrasado => 'Atrasado',
      EstadoDose.agendado => 'Agendado',
      EstadoDose.suspenso => 'Suspenso',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 64,
            child: Text(
              hhmm(o.quando),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(rotulo, style: const TextStyle(fontSize: 16)),
          ),
          if (estado == EstadoDose.atrasado || estado == EstadoDose.agendado)
            TextButton(
              onPressed: () => _marcarTomada(o.chave),
              child: const Text('Tomei'),
            ),
        ],
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
