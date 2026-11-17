import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/captura_prescricao.dart';
import '../data/repositorio.dart';
import '../domain/medicamento.dart';

/// Cadastro de remédio, no padrão visual da Dashboard.
///
/// A lógica é a mesma de antes (regras do Hermes: duração, frequência e fase
/// inicial). O que mudou foi a casca: cabeçalho próprio, campos em cartões
/// arredondados, chips na cor do módulo e botão salvar grande.
class FormularioRemedioPage extends StatefulWidget {
  const FormularioRemedioPage({super.key});

  @override
  State<FormularioRemedioPage> createState() => _FormularioRemedioPageState();
}

class _FormularioRemedioPageState extends State<FormularioRemedioPage> {
  static const Color _azul = Color(0xFF2962FF);
  static const Color _azulEscuro = Color(0xFF1B45C9);
  static const Color _verde = Color(0xFF2E9E4F);

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

  String? _prescricao;
  final TextEditingController _medico = TextEditingController();
  final TextEditingController _crm = TextEditingController();
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
    _medico.dispose();
    _crm.dispose();
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
      prescricao: _prescricao,
      medico: _medico.text.trim().isEmpty ? null : _medico.text.trim(),
      crm: _crm.text.trim().isEmpty ? null : _crm.text.trim(),
    );

    try {
      await medicamentosRepo.salvar(med);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (erro) {
      setState(() => _erro = 'Não consegui salvar: $erro');
    }
  }

  // ------------------------------------------------------------------ UI --

  @override
  Widget build(BuildContext context) {
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
                  // --- Identificação -------------------------------------
                  _Bloco(
                    titulo: 'O remédio',
                    cor: _azul,
                    filho: Column(
                      children: <Widget>[
                        _campo(
                          controller: _nome,
                          rotulo: 'Nome do remédio',
                          dica: 'Ex.: Losartana',
                          icone: Icons.medication_rounded,
                        ),
                        const SizedBox(height: 10),
                        _campo(
                          controller: _dose,
                          rotulo: 'Dosagem',
                          dica: 'Ex.: 50 mg',
                          icone: Icons.straighten_rounded,
                        ),
                      ],
                    ),
                  ),

                  // --- Duração -------------------------------------------
                  _Bloco(
                    titulo: 'Duração do tratamento',
                    cor: _azul,
                    filho: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: <Widget>[
                            _chipDuracao(TipoDuracao.continuo, 'Contínuo'),
                            _chipDuracao(TipoDuracao.temporario, 'Temporário'),
                            _chipDuracao(TipoDuracao.ciclo, 'Ciclo'),
                            _chipDuracao(TipoDuracao.sos, 'SOS'),
                          ],
                        ),
                        if (_duracao == TipoDuracao.temporario) ...<Widget>[
                          const SizedBox(height: 12),
                          _campo(
                            controller: _dias,
                            rotulo: 'Duração em dias',
                            numero: true,
                          ),
                        ],
                        if (_duracao == TipoDuracao.ciclo) ...<Widget>[
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _campo(
                                  controller: _cicloDias,
                                  rotulo: 'Dias tomando',
                                  numero: true,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _campo(
                                  controller: _cicloPausa,
                                  rotulo: 'Dias de pausa',
                                  numero: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // --- Frequência ----------------------------------------
                  _Bloco(
                    titulo: 'Frequência',
                    cor: _azul,
                    filho: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (_duracao == TipoDuracao.sos)
                          Text(
                            'SOS: não agenda dose. A pessoa registra quando '
                            'tomar.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.3,
                              color: AppColors.textoSuave,
                            ),
                          )
                        else ...<Widget>[
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: <Widget>[
                              _chipFreq(
                                  TipoFrequencia.umaAoDia, '1x ao dia'),
                              _chipFreq(
                                  TipoFrequencia.variasAoDia, 'Múltiplas'),
                              _chipFreq(TipoFrequencia.intervaloHoras,
                                  'De X em X h'),
                              _chipFreq(
                                  TipoFrequencia.diasSemana, 'Dias da semana'),
                              _chipFreq(
                                  TipoFrequencia.semanal, '1x por semana'),
                              _chipFreq(TipoFrequencia.mensal, '1x por mês'),
                            ],
                          ),
                          ..._camposDaFrequencia(),
                        ],
                      ],
                    ),
                  ),

                  // --- Prescrição ---------------------------------------
                  _Bloco(
                    titulo: 'Prescrição',
                    cor: _azul,
                    filho: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _prescricao == null
                              ? 'Fotografe a receita para consultar depois, '
                                  'quando quiser.'
                              : 'Foto anexada. Ela fica salva com este '
                                  'remédio, no celular.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: AppColors.textoSuave,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 48,
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _anexarPrescricao,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.card,
                              foregroundColor: _azulEscuro,
                              side: BorderSide(
                                color: _azul.withValues(alpha: 0.35),
                                width: 1.1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: Icon(
                              _prescricao == null
                                  ? Icons.photo_camera_rounded
                                  : Icons.check_circle_rounded,
                              size: 19,
                            ),
                            label: Text(
                              _prescricao == null
                                  ? 'Tirar foto da prescrição'
                                  : 'Trocar foto',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (_prescricao != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () =>
                                  setState(() => _prescricao = null),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFB71C1C),
                              ),
                              icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 17),
                              label: const Text(
                                'Remover foto',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        _campo(
                          controller: _medico,
                          rotulo: 'Médico que prescreveu',
                          dica: 'Ex.: Dra. Helena Souza',
                          icone: Icons.badge_rounded,
                        ),
                        const SizedBox(height: 10),
                        _campo(
                          controller: _crm,
                          rotulo: 'CRM (opcional)',
                          dica: 'Ex.: CRM-SP 123456',
                          icone: Icons.verified_rounded,
                        ),
                      ],
                    ),
                  ),

                  if (_erro != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE53935).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.error_outline_rounded,
                              color: Color(0xFFB71C1C), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _erro!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFFB71C1C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _verde,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 22),
                      label: const Text(
                        'Salvar remédio',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontVariations: <FontVariation>[
                            FontVariation('wght', 800),
                          ],
                          fontSize: 18,
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
    );
  }

  Widget _cabecalho() {
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
          const Expanded(
            child: Text(
              'Novo remédio',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontVariations: <FontVariation>[FontVariation('wght', 700)],
                fontSize: 24,
                height: 1.1,
                color: AppColors.texto,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- campos --

  /// Abre a câmera (no Android) ou explica que só existe lá.
  Future<void> _anexarPrescricao() async {
    if (!capturaPrescricao.disponivel) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A foto da prescrição entra na próxima versão do app. Por '
            'enquanto, anote o médico e o CRM nos campos abaixo.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final String? caminho = await capturaPrescricao.capturar();
    if (caminho == null || !mounted) return;
    setState(() => _prescricao = caminho);
  }

  /// Campo com borda arredondada, fundo branco e ícone.
  Widget _campo({
    required TextEditingController controller,
    required String rotulo,
    String? dica,
    IconData? icone,
    bool numero = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: numero ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 16, color: AppColors.texto),
      decoration: InputDecoration(
        labelText: rotulo,
        hintText: dica,
        filled: true,
        fillColor: AppColors.card,
        prefixIcon: icone == null
            ? null
            : Icon(icone, color: _azulEscuro, size: 20),
        labelStyle: TextStyle(color: _azulEscuro.withValues(alpha: 0.75)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _azul.withValues(alpha: 0.30),
            width: 1.1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _azul, width: 1.8),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- controles --

  Widget _chipDuracao(TipoDuracao tipo, String rotulo) {
    return ChoiceChip(
      label: Text(rotulo),
      selected: _duracao == tipo,
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _duracao == tipo ? Colors.white : _azulEscuro,
      ),
      selectedColor: _azul,
      backgroundColor: AppColors.card,
      side: BorderSide(color: _azul.withValues(alpha: 0.30)),
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
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _freq == tipo ? Colors.white : _azulEscuro,
      ),
      selectedColor: _azul,
      backgroundColor: AppColors.card,
      side: BorderSide(color: _azul.withValues(alpha: 0.30)),
      onSelected: (bool _) => setState(() {
        _freq = tipo;
        _erro = null;
      }),
    );
  }

  /// Botão de horário, no formato de "pílula" branca com borda azul.
  Widget _botaoHorario(String rotulo, VoidCallback aoTocar) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: aoTocar,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.card,
          foregroundColor: _azulEscuro,
          side: BorderSide(color: _azul.withValues(alpha: 0.35), width: 1.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.schedule_rounded, size: 19),
        label: Text(
          rotulo,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  List<Widget> _camposDaFrequencia() {
    if (_duracao == TipoDuracao.sos) return const <Widget>[];

    switch (_freq) {
      case TipoFrequencia.umaAoDia:
        return <Widget>[
          const SizedBox(height: 12),
          _botaoHorario('Horário: ${_hh(_horarios[0])}',
              () => _escolherHorario(0)),
        ];

      case TipoFrequencia.variasAoDia:
        return <Widget>[
          const SizedBox(height: 12),
          ...List<Widget>.generate(
            _horarios.length,
            (int i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _botaoHorario(
                'Horário ${i + 1}: ${_hh(_horarios[i])}',
                () => _escolherHorario(i),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(
              () => _horarios.add(const TimeOfDay(hour: 20, minute: 0)),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Adicionar horário',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            style: TextButton.styleFrom(foregroundColor: _azul),
          ),
        ];

      case TipoFrequencia.intervaloHoras:
        return <Widget>[
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  controller: _intervaloCtrl,
                  onChanged: (String v) =>
                      _intervalo = int.tryParse(v) ?? _intervalo,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Intervalo (horas)',
                    filled: true,
                    fillColor: AppColors.card,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _azul.withValues(alpha: 0.30),
                        width: 1.1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _azul, width: 1.8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _botaoHorario(
                  '1ª: ${_hh(_primeira)}',
                  _escolherPrimeira,
                ),
              ),
            ],
          ),
        ];

      case TipoFrequencia.diasSemana:
        return <Widget>[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List<Widget>.generate(7, (int i) {
              final int dia = i + 1;
              final bool marcado = _diasSemana.contains(dia);
              return FilterChip(
                label: Text(_nomeDia(dia)),
                selected: marcado,
                labelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: marcado ? Colors.white : _azulEscuro,
                ),
                selectedColor: _azul,
                backgroundColor: AppColors.card,
                side: BorderSide(color: _azul.withValues(alpha: 0.30)),
                onSelected: (bool escolhido) {
                  setState(() {
                    if (escolhido) {
                      _diasSemana.add(dia);
                    } else {
                      _diasSemana.remove(dia);
                    }
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 10),
          _botaoHorario('Horário: ${_hh(_horarios[0])}',
              () => _escolherHorario(0)),
        ];

      case TipoFrequencia.semanal:
        return <Widget>[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List<Widget>.generate(7, (int i) {
              final int dia = i + 1;
              final bool marcado = _diaSemana == dia;
              return ChoiceChip(
                label: Text(_nomeDia(dia)),
                selected: marcado,
                labelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: marcado ? Colors.white : _azulEscuro,
                ),
                selectedColor: _azul,
                backgroundColor: AppColors.card,
                side: BorderSide(color: _azul.withValues(alpha: 0.30)),
                onSelected: (bool _) => setState(() => _diaSemana = dia),
              );
            }),
          ),
          const SizedBox(height: 10),
          _botaoHorario('Horário: ${_hh(_horarios[0])}',
              () => _escolherHorario(0)),
        ];

      case TipoFrequencia.mensal:
        return <Widget>[
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.number,
            controller: _diaMesCtrl,
            onChanged: (String v) => _diaMes = int.tryParse(v) ?? _diaMes,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Dia do mês (1 a 31)',
              filled: true,
              fillColor: AppColors.card,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _azul.withValues(alpha: 0.30),
                  width: 1.1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _azul, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _botaoHorario('Horário: ${_hh(_horarios[0])}',
              () => _escolherHorario(0)),
        ];

      case TipoFrequencia.sos:
        return const <Widget>[];
    }
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

/// Cartão de seção: título colorido + conteúdo sobre fundo branco.
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
                decoration: BoxDecoration(
                  color: cor,
                  shape: BoxShape.circle,
                ),
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
