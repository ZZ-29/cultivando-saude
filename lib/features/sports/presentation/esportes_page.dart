import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../profile/data/perfil_repositorio.dart';
import '../../profile/domain/perfil.dart';
import '../data/atividades_repositorio.dart';
import '../domain/atividade.dart';
import 'atividade_ao_vivo_page.dart';

/// Esportes: registrar caminhada/corrida e ver o total da semana.
///
/// A meta semanal (150 minutos) vem da recomendação geral de atividade física
/// para adultos — não é prescrição individual.
class EsportesPage extends StatefulWidget {
  const EsportesPage({super.key});

  @override
  State<EsportesPage> createState() => _EsportesPageState();
}

class _EsportesPageState extends State<EsportesPage> {
  static const Color _laranja = Color(0xFFFB8C00);
  static const Color _laranjaEscuro = Color(0xFFA85A00);
  static const int _metaSemanal = 150;

  List<Atividade> _itens = <Atividade>[];
  bool _carregando = true;
  double? _peso;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final List<Atividade> lista = await atividadesRepo.listar();
      final Perfil perfil = await perfilRepo.ler();
      if (!mounted) return;
      setState(() {
        _itens = lista;
        _peso = perfil.peso;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  Future<void> _registrar() async {
    final Atividade? nova = await showModalBottomSheet<Atividade>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext _) => const _FormularioAtividade(),
    );
    if (nova == null) return;
    await atividadesRepo.salvar(nova);
    await _carregar();
  }

  /// Modo ao vivo: cronômetro + aviso de água. Salva ao encerrar.
  Future<void> _iniciarAoVivo() async {
    final Atividade? feita = await Navigator.of(context).push<Atividade>(
      MaterialPageRoute<Atividade>(
        builder: (BuildContext _) => AtividadeAoVivoPage(
          tipo: TipoAtividade.caminhada,
          intensidade: Intensidade.moderada,
          pesoKg: _peso,
        ),
      ),
    );
    if (feita == null) return;

    await atividadesRepo.salvar(feita);
    await _carregar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Atividade salva: ${feita.minutos} min'
            '${feita.calorias(_peso) == null ? '' : ' · ${feita.calorias(_peso)!.round()} kcal'}'),
      ),
    );
  }

  Future<void> _remover(Atividade a) async {
    final int? id = a.id;
    if (id == null) return;
    await atividadesRepo.remover(id);
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final int semana = minutosNosUltimos(_itens, 7);
    final double? kcal = caloriasNosUltimos(_itens, 7, _peso);
    final int dias = diasAtivos(_itens, 7);
    final double progresso = (semana / _metaSemanal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.fundo,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-esportes',
        onPressed: _registrar,
        backgroundColor: _laranja,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Registrar',
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
                      'Esportes',
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
                      child: CircularProgressIndicator(color: _laranja))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                      children: <Widget>[
                        _resumoSemana(semana, progresso, kcal, dias),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 60,
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _iniciarAoVivo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _laranja,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded, size: 26),
                            label: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  'INICIAR CAMINHADA',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontVariations: <FontVariation>[
                                      FontVariation('wght', 800),
                                    ],
                                    fontSize: 16,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                Text(
                                  'cronômetro e aviso para beber água',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_itens.isEmpty)
                          _vazio()
                        else ...<Widget>[
                          const Text(
                            'Últimas atividades',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textoSuave,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._itens.take(20).map(_cartao),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumoSemana(int minutos, double progresso, double? kcal, int dias) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.tinta(_laranja, 0.12),
            AppColors.tinta(_laranja, 0.22),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _laranja.withValues(alpha: 0.28),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Nesta semana',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontVariations: const <FontVariation>[
                FontVariation('wght', 700),
              ],
              fontSize: 13,
              color: _laranjaEscuro,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '$minutos',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontVariations: <FontVariation>[
                    FontVariation('wght', 800),
                  ],
                  fontSize: 34,
                  height: 1.0,
                  color: _laranjaEscuro,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'de $_metaSemanal min',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: _laranjaEscuro.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 8,
              backgroundColor: AppColors.card,
              valueColor: const AlwaysStoppedAnimation<Color>(_laranja),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              _miniDado(
                icone: Icons.local_fire_department_rounded,
                valor: kcal == null ? '—' : '${kcal.round()}',
                rotulo: kcal == null ? 'informe o peso' : 'kcal',
              ),
              const SizedBox(width: 14),
              _miniDado(
                icone: Icons.event_available_rounded,
                valor: '$dias',
                rotulo: dias == 1 ? 'dia ativo' : 'dias ativos',
              ),
            ],
          ),
          if (kcal != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Calorias estimadas (Compendium of Physical Activities) '
                'com seu peso de ${_peso!.toStringAsFixed(_peso! % 1 == 0 ? 0 : 1)} kg.',
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.25,
                  color: _laranjaEscuro.withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _miniDado({
    required IconData icone,
    required String valor,
    required String rotulo,
  }) {
    return Expanded(
      child: Row(
        children: <Widget>[
          Icon(icone, size: 17, color: _laranjaEscuro),
          const SizedBox(width: 5),
          Flexible(
            child: RichText(
              maxLines: 2,
              text: TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: valor,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 800),
                      ],
                      fontSize: 15,
                      color: _laranjaEscuro,
                    ),
                  ),
                  TextSpan(
                    text: ' $rotulo',
                    style: TextStyle(
                      fontSize: 11,
                      color: _laranjaEscuro.withValues(alpha: 0.8),
                    ),
                  ),
                ],
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _laranja.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _laranja.withValues(alpha: 0.30),
                  width: 1.2,
                ),
              ),
              child: const Icon(Icons.directions_run_rounded,
                  color: _laranja, size: 34),
            ),
            const SizedBox(height: 14),
            const Text(
              'Nenhuma atividade ainda',
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
              'Toque em Registrar para anotar uma caminhada.',
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

  Widget _cartao(Atividade a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.fromLTRB(13, 10, 6, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.tinta(_laranja, 0.11),
            AppColors.tinta(_laranja, 0.20),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _laranja.withValues(alpha: 0.28),
          width: 1.1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _laranja,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              a.tipo == TipoAtividade.corrida
                  ? Icons.directions_run_rounded
                  : Icons.directions_walk_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${a.tipo.rotulo} · ${a.intensidade.rotulo.toLowerCase()} · '
                  '${a.minutos} min',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 800),
                    ],
                    fontSize: 15,
                    height: 1.15,
                    color: _laranjaEscuro,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  <String>[
                    _quando(a.quando),
                    if (a.calorias(_peso) != null)
                      '${a.calorias(_peso)!.round()} kcal',
                  ].join(' · '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textoSuave,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remover',
            onPressed: () => _remover(a),
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.textoApagado,
            iconSize: 18,
          ),
        ],
      ),
    );
  }

  static String _quando(DateTime d) {
    final String hora =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final DateTime agora = DateTime.now();
    if (d.year == agora.year && d.month == agora.month && d.day == agora.day) {
      return 'Hoje · $hora';
    }
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')} · $hora';
  }
}

class _FormularioAtividade extends StatefulWidget {
  const _FormularioAtividade();

  @override
  State<_FormularioAtividade> createState() => _FormularioAtividadeState();
}

class _FormularioAtividadeState extends State<_FormularioAtividade> {
  static const Color _laranja = Color(0xFFFB8C00);
  static const Color _laranjaEscuro = Color(0xFFA85A00);

  final TextEditingController _minutos = TextEditingController(text: '30');
  TipoAtividade _tipo = TipoAtividade.caminhada;
  Intensidade _intensidade = Intensidade.moderada;
  String? _erro;

  @override
  void dispose() {
    _minutos.dispose();
    super.dispose();
  }

  void _salvar() {
    final int? min = int.tryParse(_minutos.text.trim());
    if (min == null || min < 1 || min > 600) {
      setState(() => _erro = 'Minutos inválidos.');
      return;
    }
    Navigator.of(context).pop(
      Atividade(
        tipo: _tipo,
        minutos: min,
        quando: DateTime.now(),
        intensidade: _intensidade,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Nova atividade',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontVariations: <FontVariation>[FontVariation('wght', 700)],
              fontSize: 21,
              color: AppColors.texto,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: TipoAtividade.values.map((TipoAtividade t) {
              final bool marcado = _tipo == t;
              return ChoiceChip(
                label: Text(t.rotulo),
                selected: marcado,
                labelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: marcado ? Colors.white : const Color(0xFFA85A00),
                ),
                selectedColor: _laranja,
                backgroundColor: AppColors.card,
                side: BorderSide(color: _laranja.withValues(alpha: 0.30)),
                onSelected: (bool _) => setState(() => _tipo = t),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
          Text(
            'Como foi o esforço?',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontVariations: const <FontVariation>[
                FontVariation('wght', 700),
              ],
              fontSize: 13.5,
              color: _laranjaEscuro,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: Intensidade.values.map((Intensidade i) {
              final bool marcado = _intensidade == i;
              return ChoiceChip(
                label: Text(i.rotulo),
                selected: marcado,
                labelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: marcado ? Colors.white : const Color(0xFFA85A00),
                ),
                selectedColor: _laranja,
                backgroundColor: AppColors.card,
                side: BorderSide(color: _laranja.withValues(alpha: 0.30)),
                onSelected: (bool _) => setState(() => _intensidade = i),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 3),
          Text(
            _intensidade.descricao,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textoSuave),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _minutos,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              labelText: 'Minutos',
              filled: true,
              fillColor: AppColors.fundo,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _laranja.withValues(alpha: 0.30),
                  width: 1.1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _laranja, width: 1.8),
              ),
            ),
          ),
          if (_erro != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              _erro!,
              style: const TextStyle(fontSize: 13, color: Color(0xFFB71C1C)),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _salvar,
              style: ElevatedButton.styleFrom(
                backgroundColor: _laranja,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Salvar',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
