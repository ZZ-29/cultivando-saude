import 'package:flutter/material.dart';

import '../../../core/navigation/barra_inferior.dart';
import '../../../core/theme/app_colors.dart';
import '../../medications/domain/periodos.dart';
import '../data/vitaminas_repositorio.dart';
import '../domain/vitamina.dart';

/// Vitaminas **e suplementos** — mesmo modelo do card de Remédios.
///
/// O dia vem antes da lista: doses agrupadas por período (madrugada, manhã,
/// tarde, noite), contador "X de Y tomadas" em cada período e o período atual
/// já aberto. Cada linha mostra a classe (💊 vitamina / 🥤 suplemento), o
/// horário, a dosagem, o estoque e o botão **TOMEI**.
class VitaminasPage extends StatefulWidget {
  const VitaminasPage({super.key});

  @override
  State<VitaminasPage> createState() => _VitaminasPageState();
}

/// Uma dose do dia (vitamina + horário).
class _Dose {
  const _Dose({
    required this.item,
    required this.horario,
    required this.tomada,
  });

  final Vitamina item;
  final String horario;
  final bool tomada;

  PeriodoDia get periodo => periodoDaHora(int.tryParse(horario.split(':').first) ?? 8);
}

class _VitaminasPageState extends State<VitaminasPage> {
  static const Color _verde = Color(0xFF2E9E4F);
  static const Color _verdeEscuro = Color(0xFF1B6B33);
  static const Color _lilas = Color(0xFF8E6FD8);

  List<Vitamina> _itens = <Vitamina>[];
  final Set<PeriodoDia> _abertos = <PeriodoDia>{};
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
      final List<Vitamina> lista = await vitaminasRepo.listar();
      if (!mounted) return;
      setState(() {
        _itens = lista;
        if (_abertos.isEmpty) {
          _abertos.add(periodoDaHora(DateTime.now().hour));
        }
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  List<_Dose> get _dosesDeHoje {
    final DateTime hoje = DateTime.now();
    final List<_Dose> saida = <_Dose>[];
    for (final Vitamina v in _itens) {
      for (final String h in v.horariosDoDia) {
        saida.add(
          _Dose(item: v, horario: h, tomada: v.tomadaNoHorario(h, hoje)),
        );
      }
    }
    saida.sort((_Dose a, _Dose b) {
      final int porHora = a.horario.compareTo(b.horario);
      return porHora != 0
          ? porHora
          : a.item.nome.toLowerCase().compareTo(b.item.nome.toLowerCase());
    });
    return saida;
  }

  Future<void> _tomar(_Dose d) async {
    final int? id = d.item.id;
    if (id == null) return;
    await vitaminasRepo.salvar(d.item.tomarNoHorario(d.horario));
    await _carregar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${d.item.nome} · ${d.horario} registrado.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _desfazer(_Dose d) async {
    final int? id = d.item.id;
    if (id == null) return;
    final DateTime hoje = DateTime.now();
    final int hora = int.tryParse(d.horario.split(':').first) ?? 8;
    final List<DateTime> restantes = d.item.tomadas
        .where((DateTime t) =>
            !(t.year == hoje.year &&
                t.month == hoje.month &&
                t.day == hoje.day &&
                t.hour == hora))
        .toList();
    await vitaminasRepo.salvar(
      d.item.copiarCom(
        tomadas: restantes,
        estoque: d.item.estoque == null ? null : d.item.estoque! + 1,
      ),
    );
    await _carregar();
  }

  Future<void> _adicionar() async {
    final Vitamina? nova = await showModalBottomSheet<Vitamina>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext _) => const _FolhaVitamina(),
    );
    if (nova == null) return;
    await vitaminasRepo.salvar(nova);
    await _carregar();
  }

  Future<void> _editar(Vitamina v) async {
    final Vitamina? editada = await showModalBottomSheet<Vitamina>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext _) => _FolhaVitamina(inicial: v),
    );
    if (editada == null) return;
    await vitaminasRepo.salvar(editada);
    await _carregar();
  }

  Future<void> _remover(Vitamina v) async {
    if (v.id == null) return;
    await vitaminasRepo.remover(v.id!);
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final List<_Dose> doses = _carregando ? <_Dose>[] : _dosesDeHoje;
    final int tomadas = doses.where((_Dose d) => d.tomada).length;
    final int qtdVitaminas = _itens
        .where((Vitamina v) => v.classe == ClasseVitamina.vitamina)
        .length;
    final int qtdSuplementos = _itens
        .where((Vitamina v) => v.classe == ClasseVitamina.suplemento)
        .length;

    return Scaffold(
      backgroundColor: AppColors.fundo,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-vitaminas',
        onPressed: _adicionar,
        backgroundColor: _verde,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Adicionar',
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
            if (qtdVitaminas > 0 || qtdSuplementos > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
                child: Text(
                  <String>[
                    if (qtdVitaminas > 0)
                      '$qtdVitaminas ${qtdVitaminas == 1 ? 'vitamina' : 'vitaminas'}',
                    if (qtdSuplementos > 0)
                      '$qtdSuplementos ${qtdSuplementos == 1 ? 'suplemento' : 'suplementos'}',
                  ].join(' · '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textoApagado,
                  ),
                ),
              ),
            Expanded(
              child: _carregando
                  ? const Center(
                      child: CircularProgressIndicator(color: _verde))
                  : _itens.isEmpty
                      ? _vazio()
                      : ListView(
                          padding:
                              EdgeInsets.fromLTRB(16, 4, 16, respiroInferior),
                          children: <Widget>[
                            ...PeriodoDia.values.map(
                              (PeriodoDia p) => _periodo(p, doses),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: Text(
                                '🌸 $tomadas de ${doses.length} tomadas hoje 🌸',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: _verdeEscuro.withValues(alpha: 0.8),
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
              'Vitaminas e suplementos',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontVariations: <FontVariation>[FontVariation('wght', 700)],
                fontSize: 21,
                height: 1.1,
                color: AppColors.texto,
              ),
            ),
          ),
          if (total > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: _verde.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _verde.withValues(alpha: 0.30)),
              ),
              child: Text(
                '$tomadas/$total',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontVariations: <FontVariation>[FontVariation('wght', 800)],
                  fontSize: 12.5,
                  color: _verdeEscuro,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _periodo(PeriodoDia p, List<_Dose> todas) {
    final List<_Dose> doPeriodo =
        todas.where((_Dose d) => d.periodo == p).toList();
    if (doPeriodo.isEmpty) return const SizedBox.shrink();

    final int tomadas = doPeriodo.where((_Dose d) => d.tomada).length;
    final bool aberto = _abertos.contains(p);
    final bool atual = periodoDaHora(DateTime.now().hour) == p;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.tinta(_verde, atual ? 0.13 : 0.07),
            AppColors.tinta(_verde, atual ? 0.22 : 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _verde.withValues(alpha: atual ? 0.38 : 0.22),
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
                            color: _verdeEscuro,
                          ),
                        ),
                        Text(
                          '$tomadas de ${doPeriodo.length} tomadas · ${p.faixa}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: _verdeEscuro.withValues(alpha: 0.75),
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
                        color: _verde,
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
                    color: _verdeEscuro,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          if (aberto)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(children: doPeriodo.map(_linha).toList()),
            ),
        ],
      ),
    );
  }

  Widget _linha(_Dose d) {
    final Vitamina v = d.item;
    final bool suplemento = v.classe == ClasseVitamina.suplemento;
    final Color corClasse = suplemento ? _lilas : _verde;

    final List<String> detalhe = <String>[
      if (v.dosagem.trim().isNotEmpty) v.dosagem,
      if (v.horariosDoDia.length > 1) '${v.horariosDoDia.length}x ao dia',
      '${v.diasTomados(7)} de 7 dias',
      if (v.estoque != null) 'restam ${v.estoque}',
    ];

    return Container(
      margin: const EdgeInsets.only(top: 7),
      padding: const EdgeInsets.fromLTRB(10, 9, 7, 9),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (d.tomada ? _verde : corClasse).withValues(alpha: 0.30),
          width: 1.1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Text(v.classe.emoji, style: const TextStyle(fontSize: 17)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  v.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontVariations: const <FontVariation>[
                      FontVariation('wght', 800),
                    ],
                    fontSize: 15,
                    height: 1.15,
                    color: AppColors.texto,
                    decoration: d.tomada ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  '${d.horario} · ${detalhe.join(' · ')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    color: AppColors.textoSuave,
                  ),
                ),
              ],
            ),
          ),
          if (d.tomada)
            IconButton(
              tooltip: 'Desfazer',
              onPressed: () => _desfazer(d),
              icon: const Icon(Icons.check_circle_rounded, size: 24),
              color: _verde,
              visualDensity: VisualDensity.compact,
            )
          else
            SizedBox(
              height: 38,
              child: ElevatedButton(
                onPressed: () => _tomar(d),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verde,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Text(
                  'TOMEI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          PopupMenuButton<String>(
            tooltip: 'Opções',
            iconSize: 17,
            padding: EdgeInsets.zero,
            color: AppColors.card,
            onSelected: (String op) {
              if (op == 'editar') {
                _editar(v);
              } else {
                _remover(v);
              }
            },
            itemBuilder: (BuildContext _) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'editar',
                child: Text('Editar', style: TextStyle(fontSize: 14)),
              ),
              PopupMenuItem<String>(
                value: 'remover',
                child: Text('Remover', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _verde.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _verde.withValues(alpha: 0.30),
                  width: 1.2,
                ),
              ),
              child: const Icon(Icons.spa_rounded, color: _verde, size: 34),
            ),
            const SizedBox(height: 14),
            const Text(
              'Nada cadastrado ainda',
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
              'Aqui entram as vitaminas e os suplementos (proteína, creatina, '
              'ômega). Toque em Adicionar e escolha a classe.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: AppColors.textoSuave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolhaVitamina extends StatefulWidget {
  const _FolhaVitamina({this.inicial});

  final Vitamina? inicial;

  @override
  State<_FolhaVitamina> createState() => _FolhaVitaminaState();
}

class _FolhaVitaminaState extends State<_FolhaVitamina> {
  static const Color _verde = Color(0xFF2E9E4F);

  late final TextEditingController _nome =
      TextEditingController(text: widget.inicial?.nome ?? '');
  late final TextEditingController _dosagem =
      TextEditingController(text: widget.inicial?.dosagem ?? '');
  late final TextEditingController _estoque = TextEditingController(
    text: widget.inicial?.estoque == null
        ? ''
        : widget.inicial!.estoque.toString(),
  );

  late ClasseVitamina _classe =
      widget.inicial?.classe ?? ClasseVitamina.vitamina;
  late List<String> _horarios =
      List<String>.from(widget.inicial?.horariosDoDia ?? <String>['08:00']);
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _dosagem.dispose();
    _estoque.dispose();
    super.dispose();
  }

  Future<void> _escolherHorario() async {
    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Horário da dose',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (BuildContext context, Widget? filho) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: filho ?? const SizedBox.shrink(),
      ),
    );
    if (hora == null) return;
    final String texto =
        '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
    if (_horarios.contains(texto)) return;
    setState(() => _horarios = <String>[..._horarios, texto]..sort());
  }

  void _salvar() {
    final String nome = _nome.text.trim();
    if (nome.isEmpty) {
      setState(() => _erro = 'Escreva o nome.');
      return;
    }
    if (_horarios.isEmpty) {
      setState(() => _erro = 'Escolha pelo menos um horário.');
      return;
    }
    Navigator.of(context).pop(
      Vitamina(
        id: widget.inicial?.id,
        nome: nome,
        classe: _classe,
        dosagem: _dosagem.text.trim(),
        horario: _horarios.first,
        horarios: _horarios,
        tomadas: widget.inicial?.tomadas ?? const <DateTime>[],
        estoque: int.tryParse(_estoque.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.inicial == null ? 'Novo item' : 'Editar item',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 700),
                      ],
                      fontSize: 21,
                      color: AppColors.texto,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(context).pop(null),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textoSuave,
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'O que é?',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontVariations: <FontVariation>[FontVariation('wght', 700)],
                fontSize: 13.5,
                color: AppColors.texto,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: ClasseVitamina.values.map((ClasseVitamina c) {
                final bool marcado = _classe == c;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: c == ClasseVitamina.vitamina ? 8 : 0,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _classe = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: marcado
                              ? _verde.withValues(alpha: 0.14)
                              : AppColors.fundo,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _verde
                                .withValues(alpha: marcado ? 0.55 : 0.22),
                            width: marcado ? 1.6 : 1.1,
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Text(c.emoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                c.rotulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: marcado
                                      ? const Color(0xFF1B6B33)
                                      : AppColors.textoSuave,
                                ),
                              ),
                            ),
                            if (marcado)
                              const Icon(Icons.check_rounded,
                                  size: 15, color: Color(0xFF1B6B33)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nome,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 16),
              decoration: _decoracao(
                _classe == ClasseVitamina.vitamina
                    ? 'Nome da vitamina'
                    : 'Nome do suplemento',
                _classe == ClasseVitamina.vitamina
                    ? 'Ex.: Vitamina D'
                    : 'Ex.: Proteína whey',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dosagem,
              style: const TextStyle(fontSize: 16),
              decoration: _decoracao(
                'Dose (opcional)',
                _classe == ClasseVitamina.vitamina
                    ? 'Ex.: 1 comprimido'
                    : 'Ex.: 30 g',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Horários',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontVariations: <FontVariation>[FontVariation('wght', 700)],
                fontSize: 13.5,
                color: AppColors.texto,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                ..._horarios.map(
                  (String h) => InputChip(
                    label: Text(
                      h,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    backgroundColor: AppColors.card,
                    side: BorderSide(color: _verde.withValues(alpha: 0.35)),
                    onDeleted: () => setState(() {
                      final List<String> copia = List<String>.from(_horarios)
                        ..remove(h);
                      _horarios = copia;
                    }),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.alarm_add_rounded, size: 16),
                  label: const Text(
                    'Adicionar',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  backgroundColor: _verde.withValues(alpha: 0.12),
                  side: BorderSide(color: _verde.withValues(alpha: 0.35)),
                  onPressed: _escolherHorario,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _estoque,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 16),
              decoration: _decoracao(
                'Estoque (opcional)',
                'Quantas doses ainda tem',
              ),
            ),
            if (_erro != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _erro!,
                style:
                    const TextStyle(fontSize: 13, color: Color(0xFFB71C1C)),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verde,
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
      ),
    );
  }

  InputDecoration _decoracao(String rotulo, String dica) => InputDecoration(
        labelText: rotulo,
        hintText: dica,
        filled: true,
        fillColor: AppColors.fundo,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _verde.withValues(alpha: 0.30),
            width: 1.1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _verde, width: 1.5),
        ),
      );
}
