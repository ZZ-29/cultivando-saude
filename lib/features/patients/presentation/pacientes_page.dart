import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/paciente_atual.dart';
import '../data/pacientes_repositorio.dart';
import '../domain/paciente.dart';

/// Pacientes: quem está sendo cuidado neste celular.
///
/// Uma cuidadora pode ter várias pessoas; uma família pode ter um celular
/// compartilhado. Cada pessoa tem seus próprios dados (um banco por paciente).
class PacientesPage extends StatefulWidget {
  const PacientesPage({super.key});

  @override
  State<PacientesPage> createState() => _PacientesPageState();
}

class _PacientesPageState extends State<PacientesPage> {
  static const Color _lilas = Color(0xFF8E6FD8);
  static const Color _lilasEscuro = Color(0xFF5B3FA8);

  List<Paciente> _itens = <Paciente>[];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final List<Paciente> lista = await pacientesRepo.listar();
    if (!mounted) return;
    setState(() {
      _itens = lista;
      _carregando = false;
    });
  }

  Future<void> _adicionar() async {
    final String? nome = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext _) => const _FolhaNome(),
    );
    if (nome == null) return;

    final Paciente novo = await pacientesRepo.salvar(Paciente(nome: nome));
    await _carregar();
    if (!mounted) return;
    trocarPaciente(novo);
    Navigator.of(context).pop(true);
  }

  Future<void> _selecionar(Paciente p) async {
    trocarPaciente(p);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _remover(Paciente p) async {
    if (p.id == null) return;
    if (_itens.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mantenha pelo menos uma pessoa cadastrada.'),
        ),
      );
      return;
    }
    await pacientesRepo.remover(p.id!);
    if (p.id == pacienteIdAtual) {
      final List<Paciente> restantes = await pacientesRepo.listar();
      if (restantes.isNotEmpty) trocarPaciente(restantes.first);
    }
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
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
                  IconButton(
                    tooltip: 'Voltar',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.texto,
                  ),
                  const SizedBox(width: 2),
                  const Expanded(
                    child: Text(
                      'Quem está cuidando',
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
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 8),
              child: Text(
                'Cada pessoa tem seus próprios remédios, exames e medidas. '
                'Tudo fica neste celular.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.3,
                  color: AppColors.textoSuave,
                ),
              ),
            ),
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator(color: _lilas))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: _itens.length,
                      separatorBuilder: (BuildContext _, int __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (BuildContext context, int i) =>
                          _cartao(_itens[i]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _adicionar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _lilas,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 21),
                  label: const Text(
                    'Adicionar pessoa',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 800),
                      ],
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartao(Paciente p) {
    final bool atual = p.id == pacienteIdAtual;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.tinta(_lilas, atual ? 0.16 : 0.08),
            AppColors.tinta(_lilas, atual ? 0.26 : 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _lilas.withValues(alpha: atual ? 0.45 : 0.22),
          width: atual ? 1.5 : 1.1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: atual ? null : () => _selecionar(p),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 10, 6, 10),
            child: Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _lilas,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 19),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    p.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 800),
                      ],
                      fontSize: 16,
                      color: _lilasEscuro,
                    ),
                  ),
                ),
                if (atual)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _lilas,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Text(
                      'EM USO',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                IconButton(
                  tooltip: 'Remover',
                  onPressed: () => _remover(p),
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppColors.textoApagado,
                  iconSize: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FolhaNome extends StatefulWidget {
  const _FolhaNome();

  @override
  State<_FolhaNome> createState() => _FolhaNomeState();
}

class _FolhaNomeState extends State<_FolhaNome> {
  static const Color _lilas = Color(0xFF8E6FD8);

  final TextEditingController _nome = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  void _salvar() {
    final String nome = _nome.text.trim();
    if (nome.isEmpty) {
      setState(() => _erro = 'Escreva o nome da pessoa.');
      return;
    }
    Navigator.of(context).pop(nome);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Nova pessoa',
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
          const SizedBox(height: 6),
          TextField(
            controller: _nome,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 16),
            onSubmitted: (_) => _salvar(),
            decoration: InputDecoration(
              labelText: 'Nome',
              hintText: 'Ex.: Dona Maria',
              filled: true,
              fillColor: AppColors.fundo,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _lilas.withValues(alpha: 0.30),
                  width: 1.1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _lilas, width: 1.8),
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
                backgroundColor: _lilas,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Salvar pessoa',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
