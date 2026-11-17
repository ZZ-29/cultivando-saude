import '../domain/checkup_emocional.dart';
import '../domain/registro_bem_estar.dart';

/// Armazenamento do bem-estar (Dart puro — sem plugin).
abstract class BemEstarRepo {
  Future<List<RegistroBemEstar>> listar();

  /// Grava ou atualiza o registro do dia.
  Future<void> salvar(RegistroBemEstar registro);

  Future<RegistroBemEstar?> deHoje();

  /// Últimos check-ups emocionais (mais recente primeiro).
  Future<List<CheckupEmocional>> checkups();
  Future<void> salvarCheckup(CheckupEmocional checkup);
}

class BemEstarMemoria implements BemEstarRepo {
  final Map<String, RegistroBemEstar> _porDia = <String, RegistroBemEstar>{};
  final List<CheckupEmocional> _checkups = <CheckupEmocional>[];
  int _proximoId = 1;

  static String _chave(DateTime d) => '${d.year}-${d.month}-${d.day}';

  @override
  Future<List<RegistroBemEstar>> listar() async {
    final List<RegistroBemEstar> lista = _porDia.values.toList();
    lista.sort((RegistroBemEstar a, RegistroBemEstar b) => b.dia.compareTo(a.dia));
    return lista;
  }

  @override
  Future<void> salvar(RegistroBemEstar registro) async {
    final String chave = _chave(registro.dia);
    final RegistroBemEstar? existente = _porDia[chave];
    _porDia[chave] = registro.copiarCom(id: existente?.id ?? _proximoId++);
  }

  @override
  Future<RegistroBemEstar?> deHoje() async =>
      _porDia[_chave(RegistroBemEstar.soData(DateTime.now()))];

  @override
  Future<List<CheckupEmocional>> checkups() async {
    final List<CheckupEmocional> lista = List<CheckupEmocional>.from(_checkups);
    lista.sort((CheckupEmocional a, CheckupEmocional b) => b.dia.compareTo(a.dia));
    return lista;
  }

  @override
  Future<void> salvarCheckup(CheckupEmocional checkup) async {
    _checkups.add(checkup);
  }
}

/// Repositório ativo nesta execução.
BemEstarRepo bemEstarRepo = BemEstarMemoria();

/// Troca a implementação (chamado uma vez, na inicialização).
void usarBemEstarRepo(BemEstarRepo novo) => bemEstarRepo = novo;

// --- Resumos -----------------------------------------------------------------

/// Quantos dias, nos últimos [dias], tiveram humor "bem".
int diasComBomHumor(List<RegistroBemEstar> lista, int dias,
        {DateTime? referencia}) =>
    _filtrar(lista, dias, referencia)
        .where((RegistroBemEstar r) => r.humor == Humor.bem)
        .length;

/// Quantos dias dormiram bem.
int diasDormiuBem(List<RegistroBemEstar> lista, int dias,
        {DateTime? referencia}) =>
    _filtrar(lista, dias, referencia)
        .where((RegistroBemEstar r) => r.sono == QualidadeSono.bem)
        .length;

/// Quantos dias tiveram alguma dor.
int diasComDor(List<RegistroBemEstar> lista, int dias,
        {DateTime? referencia}) =>
    _filtrar(lista, dias, referencia)
        .where((RegistroBemEstar r) => r.dor?.teveDor ?? false)
        .length;

/// Quantos dias conversaram com alguém (pessoalmente ou por telefone).
int diasConversou(List<RegistroBemEstar> lista, int dias,
        {DateTime? referencia}) =>
    _filtrar(lista, dias, referencia)
        .where((RegistroBemEstar r) =>
            r.convivio != null && r.convivio != Convivio.ninguem)
        .length;

/// Quantos dias beberam pelo menos [meta] copos de água.
int diasBebeuAgua(List<RegistroBemEstar> lista, int dias, {int meta = 6, DateTime? referencia}) =>
    _filtrar(lista, dias, referencia)
        .where((RegistroBemEstar r) => r.agua >= meta)
        .length;

List<RegistroBemEstar> _filtrar(List<RegistroBemEstar> lista, int dias,
    DateTime? referencia) {
  final DateTime agora = referencia ?? DateTime.now();
  final DateTime limite = DateTime(agora.year, agora.month, agora.day)
      .subtract(Duration(days: dias - 1));
  return lista
      .where((RegistroBemEstar r) => !r.dia.isBefore(limite))
      .toList(growable: false);
}
