import 'dart:convert';

/// Configurações simples do app, em pares chave/valor.
///
/// Serve para preferências que não são dados de saúde: hoje, os lembretes da
/// pressão (ligado/desligado e horários). Fica separado do banco dos módulos
/// porque não muda com o paciente — é ajuste do aparelho.
abstract class ConfigRepo {
  Future<String?> ler(String chave);
  Future<void> salvar(String chave, String valor);
  Future<void> remover(String chave);
}

class ConfigMemoria implements ConfigRepo {
  final Map<String, String> _valores = <String, String>{};

  @override
  Future<String?> ler(String chave) async => _valores[chave];

  @override
  Future<void> salvar(String chave, String valor) async =>
      _valores[chave] = valor;

  @override
  Future<void> remover(String chave) async => _valores.remove(chave);
}

/// Repositório ativo nesta execução.
ConfigRepo configRepo = ConfigMemoria();

/// Troca a implementação (chamado uma vez, na inicialização).
void usarConfigRepo(ConfigRepo novo) => configRepo = novo;

/// Chaves usadas pelo app.
abstract final class ChavesConfig {
  static const String lembretesPressao = 'lembretes_pressao_ligados';
  static const String horariosPressao = 'lembretes_pressao_horarios';
}

/// Lê a lista de horários salva (JSON).
///
/// Fica aqui, e não no banco, porque a tela usa o mesmo código na prévia
/// (memória) e no Android (SQLite).
Future<List<String>> lerHorariosSalvos(ConfigRepo repo, String chave) async {
  final String? cru = await repo.ler(chave);
  if (cru == null || cru.isEmpty) return const <String>[];
  try {
    final Object? json = jsonDecode(cru);
    if (json is List) return json.whereType<String>().toList(growable: false);
  } catch (_) {
    // valor antigo/corrompido: cai na lista vazia
  }
  return const <String>[];
}
