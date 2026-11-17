import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../medications/data/captura_prescricao.dart';
import '../data/exames_repositorio.dart';
import '../domain/exame.dart';

/// Exames: lista com data, quem pediu e foto do resultado.
///
/// A foto usa a mesma captura da receita (`capturaPrescricao`): no Android ela
/// abre a câmera; na prévia avisa que o recurso é do app instalado.
class ExamesPage extends StatefulWidget {
  const ExamesPage({required this.categoria, super.key});

  /// Qual familia de exames esta tela mostra.
  final CategoriaExame categoria;

  @override
  State<ExamesPage> createState() => _ExamesPageState();
}

class _ExamesPageState extends State<ExamesPage> {
  static const Color _indigo = Color(0xFF5E35B1);
  static const Color _indigoEscuro = Color(0xFF3F2380);

  List<Exame> _itens = <Exame>[];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final List<Exame> todos = await examesRepo.listar();
    // Cada card mostra só a sua família de exames.
    final List<Exame> lista = todos
        .where((Exame e) => e.categoria == widget.categoria)
        .toList(growable: false);
    if (!mounted) return;
    setState(() {
      _itens = lista;
      _carregando = false;
    });
  }

  Future<void> _adicionar() async {
    final Exame? novo = await showModalBottomSheet<Exame>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext _) => _FolhaExame(categoria: widget.categoria),
    );
    if (novo == null) return;
    await examesRepo.salvar(novo);
    await _carregar();
  }

  Future<void> _remover(Exame e) async {
    if (e.id == null) return;
    await examesRepo.remover(e.id!);
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-exames',
        onPressed: _adicionar,
        backgroundColor: _indigo,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Exame',
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
                  Expanded(
                    child: Text(
                      widget.categoria.titulo,
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
                  ? const Center(child: CircularProgressIndicator(color: _indigo))
                  : _itens.isEmpty
                      ? _vazio()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
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
                color: _indigo.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _indigo.withValues(alpha: 0.30),
                  width: 1.2,
                ),
              ),
              child: const Icon(Icons.science_rounded,
                  color: _indigo, size: 34),
            ),
            const SizedBox(height: 14),
            const Text(
              'Nada guardado ainda',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontVariations: <FontVariation>[FontVariation('wght', 700)],
                fontSize: 20,
                color: AppColors.texto,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.categoria.dica,
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

  Widget _cartao(Exame e) {
    final String data =
        '${e.quando.day.toString().padLeft(2, '0')}/${e.quando.month.toString().padLeft(2, '0')}/${e.quando.year}';

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 10, 6, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.tinta(_indigo, 0.10),
            AppColors.tinta(_indigo, 0.20),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _indigo.withValues(alpha: 0.28),
          width: 1.1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _indigo,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.science_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  e.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 800),
                    ],
                    fontSize: 15.5,
                    color: _indigoEscuro,
                  ),
                ),
                Text(
                  <String>[
                    data,
                    if (e.temMedico) 'pedido por ${e.medico}',
                    if (e.local.trim().isNotEmpty) e.local,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.25,
                    color: AppColors.textoSuave,
                  ),
                ),
              ],
            ),
          ),
          if (e.temFoto)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(Icons.photo_camera_rounded,
                  size: 16, color: _indigo.withValues(alpha: 0.8)),
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

class _FolhaExame extends StatefulWidget {
  const _FolhaExame({required this.categoria});

  final CategoriaExame categoria;

  @override
  State<_FolhaExame> createState() => _FolhaExameState();
}

class _FolhaExameState extends State<_FolhaExame> {
  static const Color _indigo = Color(0xFF5E35B1);

  final TextEditingController _nome = TextEditingController();
  final TextEditingController _local = TextEditingController();
  final TextEditingController _medico = TextEditingController();
  String? _foto;
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _local.dispose();
    _medico.dispose();
    super.dispose();
  }

  Future<void> _anexarFoto() async {
    if (!capturaPrescricao.disponivel) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A foto do exame entra na próxima versão do app. Por enquanto, '
            'guarde o nome e quem pediu.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    final String? caminho = await capturaPrescricao.capturar();
    if (caminho == null || !mounted) return;
    setState(() => _foto = caminho);
  }

  void _salvar() {
    final String nome = _nome.text.trim();
    if (nome.isEmpty) {
      setState(() => _erro = 'Escreva o nome do exame.');
      return;
    }
    Navigator.of(context).pop(
      Exame(
        nome: nome,
        quando: DateTime.now(),
        local: _local.text.trim(),
        medico: _medico.text.trim(),
        foto: _foto,
        categoria: widget.categoria,
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
                const Expanded(
                  child: Text(
                    'Novo exame',
                    style: TextStyle(
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
              decoration: _decoracao('Nome do exame', widget.categoria.exemplo),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _medico,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 16),
              decoration: _decoracao(
                  'Médico que pediu (opcional)', 'Ex.: Dr. Carlos Lima'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _local,
              style: const TextStyle(fontSize: 16),
              decoration: _decoracao(
                  'Laboratório ou clínica (opcional)', 'Ex.: Lab Central'),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _anexarFoto,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.card,
                  foregroundColor: _indigo,
                  side: BorderSide(
                    color: _indigo.withValues(alpha: 0.35),
                    width: 1.1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(
                  _foto == null
                      ? Icons.photo_camera_rounded
                      : Icons.check_circle_rounded,
                  size: 19,
                ),
                label: Text(
                  _foto == null
                      ? 'Tirar foto do resultado'
                      : 'Foto anexada · trocar',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
                  backgroundColor: _indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Salvar exame',
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
            color: _indigo.withValues(alpha: 0.30),
            width: 1.1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _indigo, width: 1.5),
        ),
      );
}
