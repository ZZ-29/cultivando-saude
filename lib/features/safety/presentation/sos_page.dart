import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../data/contatos_repositorio.dart';
import '../domain/contato.dart';
import 'seguranca_page.dart';

/// Tela de EMERGÊNCIA — os contatos da família em tamanho grande.
///
/// O objetivo é ser usada sob estresse: número grande, nome claro, e um toque
/// copia o número para o discador. Ligar direto depende do `url_launcher`, que
/// é plugin — entra na fase Android junto com as notificações.
class SosPage extends StatefulWidget {
  const SosPage({super.key});

  @override
  State<SosPage> createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> {
  static const Color _vermelho = Color(0xFFD50000);
  static const Color _vermelhoEscuro = Color(0xFFB71C1C);

  List<Contato> _contatos = <Contato>[];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final List<Contato> lista = await contatosRepo.listar();
      if (!mounted) return;
      setState(() {
        _contatos = lista;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  Future<void> _copiar(Contato c) async {
    await Clipboard.setData(ClipboardData(text: c.telefone));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Número de ${c.nome} copiado. Cole no discador.'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _abrirSeguranca() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => const SegurancaPage(),
      ),
    );
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
                      'Emergência',
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
                      child: CircularProgressIndicator(color: _vermelho))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                      children: <Widget>[
                        Text(
                          'Toque no número para copiar. Depois é só colar no '
                          'discador do seu telefone.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: AppColors.textoSuave,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_contatos.isEmpty)
                          _vazio()
                        else
                          ..._contatos.map(_cartao),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _abrirSeguranca,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.card,
                              foregroundColor: _vermelhoEscuro,
                              side: BorderSide(
                                color: _vermelho.withValues(alpha: 0.40),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.manage_accounts_rounded,
                                size: 20),
                            label: const Text(
                              'Gerenciar contatos',
                              style: TextStyle(
                                fontSize: 15,
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
    );
  }

  Widget _vazio() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.tinta(_vermelho, 0.10),
            AppColors.tinta(_vermelho, 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _vermelho.withValues(alpha: 0.30),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.person_add_alt_1_rounded,
                  color: _vermelhoEscuro, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nenhum contato cadastrado',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontVariations: const <FontVariation>[
                      FontVariation('wght', 800),
                    ],
                    fontSize: 15,
                    color: _vermelhoEscuro,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Cadastre dois ou três números de família em "Gerenciar '
            'contatos" — em uma emergência, um só pode não bastar.',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColors.textoSuave,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartao(Contato c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _vermelho.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                AppColors.tinta(_vermelho, 0.10),
                AppColors.tinta(_vermelho, 0.20),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _vermelho.withValues(alpha: 0.30),
              width: 1.2,
            ),
          ),
          child: InkWell(
            onTap: () => _copiar(c),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          c.parentesco.isEmpty
                              ? c.nome
                              : '${c.nome} · ${c.parentesco}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontVariations: <FontVariation>[
                              FontVariation('wght', 700),
                            ],
                            fontSize: 15,
                            color: _vermelhoEscuro,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: _vermelho.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    telefoneFormatado(c.telefone),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 800),
                      ],
                      fontSize: 26,
                      height: 1.1,
                      letterSpacing: -0.5,
                      color: AppColors.texto,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
