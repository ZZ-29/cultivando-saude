import 'package:flutter/material.dart';

import '../../../core/navigation/barra_inferior.dart';
import '../../../core/theme/app_colors.dart';
import '../data/bem_estar_repositorio.dart';
import '../domain/checkup_emocional.dart';
import '../domain/registro_bem_estar.dart';

/// Bem-Estar: check-in de 4 toques + água + resumo da semana + WHO-5.
///
/// O que entra aqui foi escolhido pelo que a literatura em geriatria aponta
/// como decisivo aos 70+: **sono, humor, dor e convivência** — além da
/// hidratação, porque idoso sente menos sede.
class BemEstarPage extends StatefulWidget {
  const BemEstarPage({super.key});

  @override
  State<BemEstarPage> createState() => _BemEstarPageState();
}

class _BemEstarPageState extends State<BemEstarPage> {
  static const Color _terracota = Color(0xFFB07D5A);
  static const Color _terracotaEscuro = Color(0xFF6D4C34);
  static const int _metaAgua = 6;

  List<RegistroBemEstar> _historico = <RegistroBemEstar>[];
  RegistroBemEstar? _hoje;
  List<CheckupEmocional> _checkups = <CheckupEmocional>[];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    alturaBarraInferior.addListener(_aoMedirBarra);
    _carregar();
  }

  @override
  void dispose() {
    alturaBarraInferior.removeListener(_aoMedirBarra);
    super.dispose();
  }

  void _aoMedirBarra() {
    if (mounted) setState(() {});
  }

  Future<void> _carregar() async {
    try {
      final List<RegistroBemEstar> lista = await bemEstarRepo.listar();
      final RegistroBemEstar? hoje = await bemEstarRepo.deHoje();
      final List<CheckupEmocional> checkups = await bemEstarRepo.checkups();
      if (!mounted) return;
      setState(() {
        _historico = lista;
        _hoje = hoje;
        _checkups = checkups;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  /// Grava uma alteração do dia preservando o que já estava marcado.
  Future<void> _atualizar(RegistroBemEstar novo) async {
    await bemEstarRepo.salvar(novo);
    await _carregar();
  }

  RegistroBemEstar get _base =>
      _hoje ?? RegistroBemEstar(dia: RegistroBemEstar.soData(DateTime.now()));

  Future<void> _marcarHumor(Humor h) => _atualizar(_base.copiarCom(humor: h));
  Future<void> _marcarSono(QualidadeSono s) =>
      _atualizar(_base.copiarCom(sono: s));
  Future<void> _marcarDor(Dor d) => _atualizar(_base.copiarCom(dor: d));
  Future<void> _marcarConvivio(Convivio c) =>
      _atualizar(_base.copiarCom(convivio: c));

  Future<void> _mudarAgua(int delta) async {
    final int novo = (_base.agua + delta).clamp(0, 20);
    if (novo == _base.agua) return;
    await _atualizar(_base.copiarCom(agua: novo));
  }

  Future<void> _abrirCheckup() async {
    final CheckupEmocional? feito = await Navigator.of(context).push<CheckupEmocional>(
      MaterialPageRoute<CheckupEmocional>(
        builder: (BuildContext _) => const CheckupEmocionalPage(),
      ),
    );
    if (feito == null) return;
    await bemEstarRepo.salvarCheckup(feito);
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final CheckupEmocional? ultimo =
        _checkups.isEmpty ? null : _checkups.first;
    final int diasDesdeCheckup =
        ultimo == null ? 999 : DateTime.now().difference(ultimo.dia).inDays;

    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
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
                      'Bem-Estar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 700),
                        ],
                        fontSize: 26,
                        height: 1.1,
                        color: AppColors.texto,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _carregando
                  ? const Center(
                      child: CircularProgressIndicator(color: _terracota))
                  : ListView(
                      padding:
                          EdgeInsets.fromLTRB(16, 6, 16, respiroInferior),
                      children: <Widget>[
                        _bloco(
                          titulo: 'Como foi seu dia',
                          filho: Column(
                            children: <Widget>[
                              _linhaEscolha<QualidadeSono>(
                                rotulo: 'Sono',
                                opcoes: QualidadeSono.values,
                                selecionado: _hoje?.sono,
                                texto: (QualidadeSono v) => v.rotulo,
                                emoji: (QualidadeSono v) => v.emoji,
                                aoEscolher: _marcarSono,
                              ),
                              _linhaEscolha<Humor>(
                                rotulo: 'Humor',
                                opcoes: Humor.values,
                                selecionado: _hoje?.humor,
                                texto: (Humor v) => v.rotulo,
                                emoji: (Humor v) => v.emoji,
                                aoEscolher: _marcarHumor,
                              ),
                              _linhaEscolha<Dor>(
                                rotulo: 'Dor',
                                opcoes: Dor.values,
                                selecionado: _hoje?.dor,
                                texto: (Dor v) => v.rotulo,
                                emoji: (Dor v) => v.emoji,
                                aoEscolher: _marcarDor,
                              ),
                              _linhaEscolha<Convivio>(
                                rotulo: 'Convivência',
                                opcoes: Convivio.values,
                                selecionado: _hoje?.convivio,
                                texto: (Convivio v) => v.rotulo,
                                emoji: (Convivio v) => v.emoji,
                                aoEscolher: _marcarConvivio,
                              ),
                            ],
                          ),
                        ),
                        _bloco(
                          titulo: 'Água hoje',
                          filho: Row(
                            children: <Widget>[
                              _botaoAgua(
                                icone: Icons.remove_rounded,
                                aoTocar: () => _mudarAgua(-1),
                              ),
                              Expanded(
                                child: Column(
                                  children: <Widget>[
                                    Text(
                                      '${_hoje?.agua ?? 0}',
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontVariations: <FontVariation>[
                                          FontVariation('wght', 800),
                                        ],
                                        fontSize: 34,
                                        height: 1.0,
                                        color: Color(0xFF1B6BA8),
                                      ),
                                    ),
                                    Text(
                                      'de $_metaAgua copos',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textoApagado,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _botaoAgua(
                                icone: Icons.add_rounded,
                                aoTocar: () => _mudarAgua(1),
                              ),
                            ],
                          ),
                        ),
                        _bloco(
                          titulo: 'Sua semana',
                          filho: Column(
                            children: <Widget>[
                              _parResumo(
                                _resumo('Bom humor', diasComBomHumor(_historico, 7),
                                    Icons.sentiment_satisfied_alt_rounded),
                                _resumo('Dormiu bem', diasDormiuBem(_historico, 7),
                                    Icons.bedtime_rounded),
                              ),
                              const SizedBox(height: 8),
                              _parResumo(
                                _resumo('Com dor', diasComDor(_historico, 7),
                                    Icons.healing_rounded),
                                _resumo('Convivência',
                                    diasConversou(_historico, 7), Icons.people_alt_rounded),
                              ),
                              const SizedBox(height: 8),
                              _resumo(
                                'Água (6+ copos)',
                                diasBebeuAgua(_historico, 7, meta: _metaAgua),
                                Icons.water_drop_rounded,
                                largura: double.infinity,
                              ),
                            ],
                          ),
                        ),
                        _bloco(
                          titulo: 'Check-up emocional (WHO-5)',
                          filho: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (ultimo == null)
                                const Text(
                                  'Cinco perguntas sobre as duas últimas semanas. '
                                  'Serve para você perceber como está e levar o '
                                  'resultado ao médico — não é diagnóstico.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.3,
                                    color: AppColors.textoSuave,
                                  ),
                                )
                              else
                                Text(
                                  'Último resultado: ${ultimo.nota}/100 · '
                                  '${ultimo.leitura} · '
                                  '${diasDesdeCheckup == 0 ? 'hoje' : 'há $diasDesdeCheckup dias'}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.3,
                                    color: AppColors.textoSuave,
                                  ),
                                ),
                              const SizedBox(height: 9),
                              SizedBox(
                                height: 46,
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _abrirCheckup,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: AppColors.card,
                                    foregroundColor: _terracotaEscuro,
                                    side: BorderSide(
                                      color: _terracota.withValues(alpha: 0.40),
                                      width: 1.1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.psychology_alt_rounded,
                                      size: 19),
                                  label: Text(
                                    ultimo == null
                                        ? 'Responder as 5 perguntas'
                                        : 'Responder de novo',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _bloco(
                          titulo: 'Para hoje',
                          filho: Column(
                            children: _dicas().map(_dica).toList(),
                          ),
                        ),
                        if (_historico.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(
                            'Últimos dias',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontVariations: const <FontVariation>[
                                FontVariation('wght', 700),
                              ],
                              fontSize: 13.5,
                              color: _terracotaEscuro,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._historico.take(14).map(_linhaHistorico),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dicas que mudam conforme o que foi registrado — sem prescrever.
  List<String> _dicas() {
    final List<String> saida = <String>[];
    if (diasComDor(_historico, 7) >= 2) {
      saida.add('Alongamento leve antes de sair da cama ajuda a dor a ceder.');
    }
    if (diasDormiuBem(_historico, 7) <= 3) {
      saida.add('Tente acordar no mesmo horário todos os dias, mesmo após '
          'uma noite ruim.');
    }
    if (diasConversou(_historico, 7) <= 3) {
      saida.add('Uma ligação de cinco minutos por dia já conta como convivência.');
    }
    if (diasBebeuAgua(_historico, 7) <= 3) {
      saida.add('Deixe uma garrafa à vista: a sede aparece menos depois dos 70.');
    }
    if (saida.isEmpty) {
      saida.add('Respirar fundo: 4 segundos inspirando, 4 segurando, '
          '4 soltando. Três vezes.');
    }
    return saida.take(2).toList(growable: false);
  }

  Widget _botaoAgua({required IconData icone, required VoidCallback aoTocar}) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoTocar,
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF1B6BA8).withValues(alpha: 0.35),
              width: 1.1,
            ),
          ),
          child: Icon(icone, size: 22, color: const Color(0xFF1B6BA8)),
        ),
      ),
    );
  }

  Widget _linhaEscolha<T>({
    required String rotulo,
    required List<T> opcoes,
    required T? selecionado,
    required String Function(T) texto,
    required String Function(T) emoji,
    required Future<void> Function(T) aoEscolher,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            rotulo,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: AppColors.textoApagado,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: opcoes.map((T o) {
              final bool marcado = selecionado == o;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => aoEscolher(o),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      decoration: BoxDecoration(
                        color: marcado
                            ? _terracota.withValues(alpha: 0.16)
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _terracota
                              .withValues(alpha: marcado ? 0.60 : 0.22),
                          width: marcado ? 1.6 : 1,
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          Text(emoji(o), style: const TextStyle(fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(
                            texto(o),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10.5,
                              height: 1.1,
                              fontWeight:
                                  marcado ? FontWeight.w800 : FontWeight.w600,
                              color: marcado
                                  ? _terracotaEscuro
                                  : AppColors.textoSuave,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _resumo(String rotulo, int valor, IconData icone,
      {double? largura}) {
    return SizedBox(
      width: largura,
      child: Row(
        children: <Widget>[
          Icon(icone, size: 16, color: _terracotaEscuro),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              rotulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textoSuave),
            ),
          ),
          Text(
            '$valor/7',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontVariations: <FontVariation>[FontVariation('wght', 800)],
              fontSize: 14,
              color: _terracotaEscuro,
            ),
          ),
        ],
      ),
    );
  }

  Widget _parResumo(Widget a, Widget b) {
    return Row(
      children: <Widget>[
        Expanded(child: a),
        const SizedBox(width: 14),
        Expanded(child: b),
      ],
    );
  }

  Widget _bloco({required String titulo, required Widget filho}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.tinta(_terracota, 0.07),
            AppColors.tinta(_terracota, 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _terracota.withValues(alpha: 0.26),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: _terracota, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 700),
                    ],
                    fontSize: 14.5,
                    color: _terracotaEscuro,
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

  Widget _dica(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: _terracota,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.3,
                color: AppColors.texto,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaHistorico(RegistroBemEstar r) {
    final String data =
        '${r.dia.day.toString().padLeft(2, '0')}/${r.dia.month.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _terracota.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Text(
            r.humor?.emoji ?? '•',
            style: const TextStyle(fontSize: 17),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              r.resumo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: AppColors.texto),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            r.ehHoje ? 'hoje' : data,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textoApagado,
            ),
          ),
        ],
      ),
    );
  }
}

/// Check-up emocional — WHO-5.
///
/// Cinco perguntas, respostas de 0 a 5. A nota (soma × 4) vai para o
/// histórico do Bem-Estar, para ser levada ao profissional.
class CheckupEmocionalPage extends StatefulWidget {
  const CheckupEmocionalPage({super.key});

  @override
  State<CheckupEmocionalPage> createState() => _CheckupEmocionalPageState();
}

class _CheckupEmocionalPageState extends State<CheckupEmocionalPage> {
  static const Color _terracota = Color(0xFFB07D5A);
  static const Color _terracotaEscuro = Color(0xFF6D4C34);

  final List<int?> _respostas =
      List<int?>.filled(CheckupEmocional.perguntas.length, null);

  bool get _completo => _respostas.every((int? r) => r != null);

  void _salvar() {
    if (!_completo) return;
    Navigator.of(context).pop(
      CheckupEmocional(
        dia: DateTime.now(),
        respostas: _respostas.map((int? r) => r!).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
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
                      'Check-up emocional',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 700),
                        ],
                        fontSize: 22,
                        height: 1.1,
                        color: AppColors.texto,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _terracota.withValues(alpha: 0.25),
                        width: 1.1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Nas últimas duas semanas, com que frequência…',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.texto,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          CheckupEmocional.opcoes
                              .asMap()
                              .entries
                              .map((MapEntry<int, String> e) =>
                                  '${e.key} = ${e.value}')
                              .join(' · '),
                          style: const TextStyle(
                            fontSize: 10.5,
                            height: 1.35,
                            color: AppColors.textoApagado,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Instrumento WHO-5 (OMS). Não substitui avaliação '
                    'profissional.',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textoApagado,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...List<Widget>.generate(
                    CheckupEmocional.perguntas.length,
                    (int i) => _pergunta(i),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _completo ? _salvar : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _terracota,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        _terracota.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Salvar resultado',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pergunta(int indice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _terracota.withValues(alpha: 0.22),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${indice + 1}. ${CheckupEmocional.perguntas[indice]}',
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: AppColors.texto,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List<Widget>.generate(6, (int valor) {
              final bool marcado = _respostas[indice] == valor;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: valor == 5 ? 0 : 5),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _respostas[indice] = valor),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: marcado
                            ? _terracota
                            : _terracota.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _terracota
                              .withValues(alpha: marcado ? 0.9 : 0.25),
                          width: marcado ? 1.4 : 1,
                        ),
                      ),
                      child: Text(
                        '$valor',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: marcado ? Colors.white : _terracotaEscuro,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
