import 'package:flutter/material.dart';

import '../data/repositorio.dart';
import '../domain/medicamento.dart';

/// Cadastro de remédio com as regras do Hermes: duração, frequência e fase
/// inicial. Interface simples (texto + chips), sem enfeite.
class FormularioRemedioPage extends StatefulWidget {
  const FormularioRemedioPage({super.key});

  @override
  State<FormularioRemedioPage> createState() => _FormularioRemedioPageState();
}

class _FormularioRemedioPageState extends State<FormularioRemedioPage> {
  final TextEditingController _nome = TextEditingController();
  final TextEditingController _dose = TextEditingController();
  final TextEditingController _dias = TextEditingController(text: '7');
  final TextEditingController _cicloDias = TextEditingController(text: '21');
  final TextEditingController _cicloPausa = TextEditingController(text: '7');
  final TextEditingController _intervaloCtrl =
      TextEditingController(text: '8');
  final TextEditingController _diaMesCtrl = TextEditingController(text: '1');

  TipoDuracao _duracao = TipoDuracao.continuo;
  TipoFrequencia _freq = TipoFrequencia.umaAoDia;

  List<TimeOfDay> _horarios = <TimeOfDay>[const TimeOfDay(hour: 8, minute: 0)];
  TimeOfDay _primeira = const TimeOfDay(hour: 8, minute: 0);
  int _intervalo = 8;
  Set<int> _diasSemana = <int>{1, 3, 5};
  int _diaSemana = 1;
  int _diaMes = 1;

  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _dose.dispose();
    _dias.dispose();
    _cicloDias.dispose();
    _cicloPausa.dispose();
    _intervaloCtrl.dispose();
    _diaMesCtrl.dispose();
    super.dispose();
  }

  static String _hh(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _escolherHorario(int indice) async {
    final TimeOfDay? escolhido = await showTimePicker(
      context: context,
      initialTime: _horarios[indice],
    );
    if (escolhido != null) {
      setState(() => _horarios[indice] = escolhido);
    }
  }

  Future<void> _escolherPrimeira() async {
    final TimeOfDay? escolhido = await showTimePicker(
      context: context,
      initialTime: _primeira,
    );
    if (escolhido != null) {
      setState(() => _primeira = escolhido);
    }
  }

  Frequencia _montarFrequencia() {
    final List<String> horarios = _horarios.map(_hh).toList();

    switch (_freq) {
      case TipoFrequencia.umaAoDia:
        return Frequencia(
          tipo: TipoFrequencia.umaAoDia,
          horarios: <String>[horarios.first],
        );
      case TipoFrequencia.variasAoDia:
        return Frequencia(
          tipo: TipoFrequencia.variasAoDia,
          horarios: horarios,
        );
      case TipoFrequencia.intervaloHoras:
        return Frequencia(
          tipo: TipoFrequencia.intervaloHoras,
          intervaloHoras: _intervalo,
          primeiraDose: _hh(_primeira),
        );
      case TipoFrequencia.diasSemana:
        return Frequencia(
          tipo: TipoFrequencia.diasSemana,
          horarios: <String>[horarios.first],
          diasSemana: _diasSemana.toList()..sort(),
        );
      case TipoFrequencia.semanal:
        return Frequencia(
          tipo: TipoFrequencia.semanal,
          horarios: <String>[horarios.first],
          diaSemana: _diaSemana,
        );
      case TipoFrequencia.mensal:
        return Frequencia(
          tipo: TipoFrequencia.mensal,
          horarios: <String>[horarios.first],
          diaMes: _diaMes,
        );
      case TipoFrequencia.sos:
        return const Frequencia(tipo: TipoFrequencia.sos);
    }
  }

  Future<void> _salvar() async {
    final String nome = _nome.text.trim();
    if (nome.isEmpty) {
      setState(() => _erro = 'Escreva o nome do remédio.');
      return;
    }

    int? dias;
    int? cicloDias;
    int? cicloPausa;

    if (_duracao == TipoDuracao.temporario) {
      dias = int.tryParse(_dias.text.trim());
      if (dias == null || dias < 1) {
        setState(() => _erro = 'Duração em dias inválida.');
        return;
      }
    }

    if (_duracao == TipoDuracao.ciclo) {
      cicloDias = int.tryParse(_cicloDias.text.trim());
      cicloPausa = int.tryParse(_cicloPausa.text.trim());
      if (cicloDias == null || cicloDias < 1) {
        setState(() => _erro = 'Dias tomando inválido.');
        return;
      }
      if (cicloPausa == null || cicloPausa < 0) {
        setState(() => _erro = 'Dias de pausa inválido.');
        return;
      }
    }

    if (_freq == TipoFrequencia.diasSemana && _diasSemana.isEmpty) {
      setState(() => _erro = 'Escolha ao menos um dia da semana.');
      return;
    }

    final Frequencia freq = _montarFrequencia();
    final DateTime hoje = DateTime.now();
    final Fase fase = Fase(
      frequencia: freq,
      inicio: DateTime(hoje.year, hoje.month, hoje.day),
      duracaoDias: _duracao == TipoDuracao.temporario ? dias : null,
    );

    final Medicamento med = Medicamento(
      nome: nome,
      dosagem: _dose.text.trim(),
      duracao: _duracao,
      diasTratamento: dias,
      cicloDias: cicloDias,
      cicloPausa: cicloPausa,
      fases: <Fase>[fase],
      criadoEm: DateTime.now(),
    );

    try {
      await medicamentosRepo.salvar(med);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (erro) {
      setState(() => _erro = 'Não consegui salvar: $erro');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo remédio')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            controller: _nome,
            decoration: const InputDecoration(
              labelText: 'Nome do remédio',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dose,
            decoration: const InputDecoration(
              labelText: 'Dosagem (ex.: 50 mg)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // --- Duração -----------------------------------------------------
          const _Rotulo('Duração do tratamento'),
          Wrap(
            spacing: 8,
            children: <Widget>[
              _chipDuracao(TipoDuracao.continuo, 'Contínuo'),
              _chipDuracao(TipoDuracao.temporario, 'Temporário'),
              _chipDuracao(TipoDuracao.ciclo, 'Ciclo'),
              _chipDuracao(TipoDuracao.sos, 'SOS'),
            ],
          ),
          if (_duracao == TipoDuracao.temporario) ...<Widget>[
            const SizedBox(height: 12),
            TextField(
              controller: _dias,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duração em dias',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          if (_duracao == TipoDuracao.ciclo) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _cicloDias,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Dias tomando',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cicloPausa,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Dias de pausa',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // --- Frequência --------------------------------------------------
          const _Rotulo('Frequência'),
          if (_duracao == TipoDuracao.sos)
            const Text(
              'SOS: não agenda dose. A pessoa registra quando tomar.',
              style: TextStyle(fontSize: 16),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: <Widget>[
                _chipFreq(TipoFrequencia.umaAoDia, '1x ao dia'),
                _chipFreq(TipoFrequencia.variasAoDia, 'Múltiplas'),
                _chipFreq(TipoFrequencia.intervaloHoras, 'De X em X h'),
                _chipFreq(TipoFrequencia.diasSemana, 'Dias da semana'),
                _chipFreq(TipoFrequencia.semanal, '1x por semana'),
                _chipFreq(TipoFrequencia.mensal, '1x por mês'),
              ],
            ),
          const SizedBox(height: 12),
          ..._camposDaFrequencia(),

          if (_erro != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              _erro!,
              style: const TextStyle(fontSize: 16, color: Color(0xFFB00020)),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _salvar,
              child: const Text('Salvar', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  List<Widget> _camposDaFrequencia() {
    if (_duracao == TipoDuracao.sos) return const <Widget>[];

    switch (_freq) {
      case TipoFrequencia.umaAoDia:
        return <Widget>[_linhaHorario(0, 'Horário')];

      case TipoFrequencia.variasAoDia:
        return <Widget>[
          ...List<Widget>.generate(
            _horarios.length,
            (int i) => _linhaHorario(i, 'Horário ${i + 1}'),
          ),
          TextButton.icon(
            onPressed: () => setState(
              () => _horarios.add(const TimeOfDay(hour: 20, minute: 0)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar horário'),
          ),
        ];

      case TipoFrequencia.intervaloHoras:
        return <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Intervalo (horas)',
                    border: OutlineInputBorder(),
                  ),
                  controller: _intervaloCtrl,
                  onChanged: (String v) =>
                      _intervalo = int.tryParse(v) ?? _intervalo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _escolherPrimeira,
                  child: Text('1ª dose: ${_hh(_primeira)}'),
                ),
              ),
            ],
          ),
        ];

      case TipoFrequencia.diasSemana:
        return <Widget>[
          Wrap(
            spacing: 6,
            children: List<Widget>.generate(7, (int i) {
              final int dia = i + 1;
              return FilterChip(
                label: Text(_nomeDia(dia)),
                selected: _diasSemana.contains(dia),
                onSelected: (bool marcado) {
                  setState(() {
                    if (marcado) {
                      _diasSemana.add(dia);
                    } else {
                      _diasSemana.remove(dia);
                    }
                  });
                },
              );
            }),
          ),
          _linhaHorario(0, 'Horário'),
        ];

      case TipoFrequencia.semanal:
        return <Widget>[
          Wrap(
            spacing: 6,
            children: List<Widget>.generate(7, (int i) {
              final int dia = i + 1;
              return ChoiceChip(
                label: Text(_nomeDia(dia)),
                selected: _diaSemana == dia,
                onSelected: (bool _) => setState(() => _diaSemana = dia),
              );
            }),
          ),
          _linhaHorario(0, 'Horário'),
        ];

      case TipoFrequencia.mensal:
        return <Widget>[
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Dia do mês (1 a 31)',
              border: OutlineInputBorder(),
            ),
            controller: _diaMesCtrl,
            onChanged: (String v) => _diaMes = int.tryParse(v) ?? _diaMes,
          ),
          _linhaHorario(0, 'Horário'),
        ];

      case TipoFrequencia.sos:
        return const <Widget>[];
    }
  }

  Widget _linhaHorario(int indice, String rotulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: () => _escolherHorario(indice),
        child: Text('$rotulo: ${_hh(_horarios[indice])}'),
      ),
    );
  }

  Widget _chipDuracao(TipoDuracao tipo, String rotulo) {
    return ChoiceChip(
      label: Text(rotulo),
      selected: _duracao == tipo,
      onSelected: (bool _) {
        setState(() {
          _duracao = tipo;
          _erro = null;
          if (tipo == TipoDuracao.sos) {
            _freq = TipoFrequencia.sos;
          } else if (_freq == TipoFrequencia.sos) {
            _freq = TipoFrequencia.umaAoDia;
          }
        });
      },
    );
  }

  Widget _chipFreq(TipoFrequencia tipo, String rotulo) {
    return ChoiceChip(
      label: Text(rotulo),
      selected: _freq == tipo,
      onSelected: (bool _) => setState(() {
        _freq = tipo;
        _erro = null;
      }),
    );
  }

  static String _nomeDia(int dia) {
    const List<String> nomes = <String>[
      'Seg',
      'Ter',
      'Qua',
      'Qui',
      'Sex',
      'Sáb',
      'Dom',
    ];
    return nomes[dia - 1];
  }
}

class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    );
  }
}
