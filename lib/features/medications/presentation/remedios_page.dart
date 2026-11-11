import 'package:flutter/material.dart';

import '../data/repositorio.dart';
import '../domain/medicamento.dart';
import 'formulario_remedio_page.dart';
import 'remedio_detalhe_page.dart';

/// Lista de remédios — a tela que abre em "Ver Remédios" no card.
///
/// Interface feia de propósito nesta fase: texto puro, foco na lógica.
class RemediosPage extends StatefulWidget {
  const RemediosPage({super.key});

  @override
  State<RemediosPage> createState() => _RemediosPageState();
}

class _RemediosPageState extends State<RemediosPage> {
  List<Medicamento> _itens = <Medicamento>[];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final List<Medicamento> lista = await medicamentosRepo.listar();
      if (!mounted) return;
      setState(() {
        _itens = lista;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() => _carregando = false);
      _avisar('Erro ao ler o banco: $erro');
    }
  }

  Future<void> _abrirCadastro() async {
    final bool? salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext _) => const FormularioRemedioPage(),
      ),
    );
    if (salvou == true) await _carregar();
  }

  Future<void> _abrirDetalhe(Medicamento med) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => RemedioDetalhePage(medicamento: med),
      ),
    );
    await _carregar();
  }

  Future<void> _remover(Medicamento med) async {
    final int? id = med.id;
    if (id == null) return;
    await medicamentosRepo.remover(id);
    await _carregar();
    _avisar('"${med.nome}" removido.');
  }

  void _avisar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Remédios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCadastro,
        icon: const Icon(Icons.add),
        label: const Text('Cadastrar'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                medicamentosRepo.descricao,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _itens.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum remédio cadastrado.\n'
                          'Toque em "Cadastrar".',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _itens.length,
                        separatorBuilder: (BuildContext _, int __) =>
                            const Divider(height: 1),
                        itemBuilder: (BuildContext context, int i) {
                          final Medicamento med = _itens[i];
                          return ListTile(
                            title: Text(
                              med.nome,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${_resumoDuracao(med)} · '
                              '${med.fases.isEmpty ? "sem fase" : med.fases.last.frequencia.resumo}'
                              '${med.fases.length > 1 ? " · ${med.fases.length} fases" : ""}',
                              style: const TextStyle(fontSize: 15),
                            ),
                            trailing: IconButton(
                              tooltip: 'Remover',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _remover(med),
                            ),
                            onTap: () => _abrirDetalhe(med),
                          );
                        },
                      ),
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
        return 'Temporário · ${med.diasTratamento ?? "?"} dias';
      case TipoDuracao.ciclo:
        return 'Ciclo ${med.cicloDias ?? 0}+${med.cicloPausa ?? 0}';
      case TipoDuracao.sos:
        return 'SOS';
    }
  }
}
