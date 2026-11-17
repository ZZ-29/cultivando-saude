import 'package:flutter/material.dart';

import '../../../core/navigation/barra_inferior.dart';
import '../../../core/theme/app_colors.dart';
import '../data/reabilitacao_repositorio.dart';
import '../domain/exercicio.dart';

/// Reabilitação: os exercícios que **o fisioterapeuta ou o médico passou**.
///
/// O app é um caderno de lembrete, não um profissional: começa vazio, com o
/// convite para escrever o exercício combinado. Cada exercício guarda os
/// horários — que na fase Android viram alarme.
class ReabilitacaoPage extends StatefulWidget {
  const ReabilitacaoPage({super.key});

  @override
  State<ReabilitacaoPage> createState() => _ReabilitacaoPageState();
}

class _ReabilitacaoPageState extends State<ReabilitacaoPage> {
  static const Color _teal = Color(0xFF00897B);
  static const Color _tealEscuro = Color(0xFF00564C);

  List<Exercicio> _itens = <Exercicio>[];
  Set<int> _feitos = <int>{};
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
    final List<Exercicio> lista = await reabilitacaoRepo.listar();
    final Set<int> feitos = await reabilitacaoRepo.feitosNoDia(DateTime.now());
    if (!mounted) return;
    setState(() {
      _itens = lista;
      _feitos = feitos;
      _carregando = false;
    });
  }

  Future<void> _adicionar() async {
    final Exercicio? novo = await showModalBottomSheet<Exercicio>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext _) => const _FolhaExercicio(),
    );
    if (novo == null) return;
    await reabilitacaoRepo.salvar(novo);
    await _carregar();
  }

  Future<void> _editar(Exercicio e) async {
    final Exercicio? editado = await showModalBottomSheet<Exercicio>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext _) => _FolhaExercicio(inicial: e),
    );
    if (editado == null) return;
    await reabilitacaoRepo.salvar(editado);
    await _carregar();
  }

  Future<void> _remover(Exercicio e) async {
    if (e.id == null) return;
    await reabilitacaoRepo.remover(e.id!);
    await _carregar();
  }

  Future<void> _alternarFeito(Exercicio e) async {
    if (e.id == null) return;
    final bool feito = _feitos.contains(e.id);
    await reabilitacaoRepo.marcarFeito(e.id!, DateTime.now(), !feito);
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-reabilitacao',
        onPressed: _adicionar,
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Exercício',
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
                      'Reabilitação',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 700),
                        ],
                        fontSize: 24,
                        height: 1.1,
                        color: AppColors.texto,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 6),
              child: Text(
                'Escreva aqui os exercícios que seu fisioterapeuta ou médico '
                'passou. O app só lembra a hora e marca o que já foi feito.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.3,
                  color: AppColors.textoSuave,
                ),
              ),
            ),
            Expanded(
              child: _carregando
                  ? const Center(
                      child: CircularProgressIndicator(color: _teal))
                  : _itens.isEmpty
                      ? _vazio()
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                              16, 6, 16, respiroInferior),
                          itemCount: _itens.length,
                          separatorBuilder: (BuildContext _, int __) =>
                              const SizedBox(height: 9),
                          itemBuilder: (BuildContext context, int i) =>
                              _cartao(_itens[i]),
                        ),
            ),
          ],
        ),
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
                color: _teal.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _teal.withValues(alpha: 0.30),
                  width: 1.2,
                ),
              ),
              child: const Icon(Icons.accessibility_new_rounded,
                  color: _teal, size: 34),
            ),
            const SizedBox(height: 14),
            const Text(
              'Nenhum exercício cadastrado',
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
              'Toque em "Exercício" e escreva o que foi orientado, com o '
              'horário. Ex.: Elevação de perna — 3 x 10, às 08:00 e 15:00.',
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

  Widget _cartao(Exercicio e) {
    final bool feito = e.id != null && _feitos.contains(e.id);

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 10, 6, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: feito
              ? <Color>[
                  AppColors.tinta(const Color(0xFF2E9E4F), 0.10),
                  AppColors.tinta(const Color(0xFF2E9E4F), 0.18),
                ]
              : <Color>[
                  AppColors.tinta(_teal, 0.10),
                  AppColors.tinta(_teal, 0.20),
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (feito ? const Color(0xFF2E9E4F) : _teal)
              .withValues(alpha: 0.30),
          width: 1.1,
        ),
      ),
      child: Row(
        children: <Widget>[
          // Check do dia: toque marca como feito.
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _alternarFeito(e),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                feito
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 30,
                color: feito ? const Color(0xFF2E9E4F) : _teal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  e.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontVariations: const <FontVariation>[
                      FontVariation('wght', 800),
                    ],
                    fontSize: 15.5,
                    color: _tealEscuro,
                    decoration: feito ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (e.series.trim().isNotEmpty || e.temHorario)
                  Text(
                    <String>[
                      if (e.series.trim().isNotEmpty) e.series,
                      if (e.temHorario) 'às ${e.horarios.join(' · ')}',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textoSuave,
                    ),
                  ),
                if (e.orientacao.trim().isNotEmpty)
                  Text(
                    e.orientacao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.25,
                      color: AppColors.textoApagado,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar',
            onPressed: () => _editar(e),
            icon: const Icon(Icons.edit_outlined),
            color: _teal,
            iconSize: 18,
          ),
          IconButton(
            tooltip: 'Remover',
            onPressed: () => _remover(e),
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.textoApagado,
            iconSize: 18,
          ),
        ],
      ),
    );
  }
}

class _FolhaExercicio extends StatefulWidget {
  const _FolhaExercicio({this.inicial});

  final Exercicio? inicial;

  @override
  State<_FolhaExercicio> createState() => _FolhaExercicioState();
}

class _FolhaExercicioState extends State<_FolhaExercicio> {
  static const Color _teal = Color(0xFF00897B);
  static const Color _tealEscuro = Color(0xFF00564C);

  late final TextEditingController _nome =
      TextEditingController(text: widget.inicial?.nome ?? '');
  late final TextEditingController _series =
      TextEditingController(text: widget.inicial?.series ?? '');
  late final TextEditingController _orientacao =
      TextEditingController(text: widget.inicial?.orientacao ?? '');

  late List<String> _horarios =
      List<String>.from(widget.inicial?.horarios ?? const <String>[]);
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _series.dispose();
    _orientacao.dispose();
    super.dispose();
  }

  Future<void> _escolherHorario() async {
    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Horário do exercício',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (BuildContext context, Widget? filho) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: filho ?? const SizedBox.shrink(),
        );
      },
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
      setState(() => _erro = 'Escreva o nome do exercício.');
      return;
    }
    Navigator.of(context).pop(
      Exercicio(
        id: widget.inicial?.id,
        nome: nome,
        series: _series.text.trim(),
        orientacao: _orientacao.text.trim(),
        horarios: _horarios,
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
                    widget.inicial == null
                        ? 'Novo exercício'
                        : 'Editar exercício',
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
            const SizedBox(height: 4),
            TextField(
              controller: _nome,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 16),
              decoration: _decoracao('Exercício', 'Ex.: Elevação de perna'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _series,
              style: const TextStyle(fontSize: 16),
              decoration: _decoracao('Séries e repetições', 'Ex.: 3 x 10'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _orientacao,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              style: const TextStyle(fontSize: 15),
              decoration: _decoracao(
                'Como fazer (o que o profissional explicou)',
                'Ex.: deitado, perna esticada, subir devagar',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Horário do lembrete',
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
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    backgroundColor: AppColors.card,
                    side: BorderSide(
                      color: _teal.withValues(alpha: 0.35),
                    ),
                    onDeleted: () => setState(() {
                      final List<String> copia = List<String>.from(_horarios)
                        ..remove(h);
                      _horarios = copia;
                    }),
                    deleteIconColor: _tealEscuro,
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.alarm_add_rounded, size: 16),
                  label: const Text(
                    'Adicionar',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  backgroundColor: _teal.withValues(alpha: 0.12),
                  side: BorderSide(color: _teal.withValues(alpha: 0.35)),
                  onPressed: _escolherHorario,
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Estes horários viram alarme no app Android.',
              style: TextStyle(fontSize: 11, color: AppColors.textoApagado),
            ),
            if (_erro != null) ...<Widget>[
              const SizedBox(height: 8),
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
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Salvar exercício',
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
            color: _teal.withValues(alpha: 0.30),
            width: 1.1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _teal, width: 1.5),
        ),
      );
}
