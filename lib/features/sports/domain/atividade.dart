/// Uma atividade física registrada.
///
/// Guarda também a **intensidade**, porque "30 min de caminhada" não diz
/// esforço: leve e forte diferem quase 2× no gasto energético.
class Atividade {
  const Atividade({
    this.id,
    required this.tipo,
    required this.minutos,
    required this.quando,
    this.intensidade = Intensidade.moderada,
  });

  final int? id;
  final TipoAtividade tipo;
  final int minutos;
  final DateTime quando;
  final Intensidade intensidade;

  Atividade copiarCom({int? id}) => Atividade(
        id: id ?? this.id,
        tipo: tipo,
        minutos: minutos,
        quando: quando,
        intensidade: intensidade,
      );

  /// Gasto estimado em kcal, pela fórmula do Compendium:
  ///
  ///     kcal = MET × 3,5 × peso(kg) ÷ 200 × minutos
  ///
  /// `null` quando o peso não foi informado — melhor esconder do que chutar.
  double? calorias(double? pesoKg) {
    if (pesoKg == null || pesoKg <= 0) return null;
    return metDe(tipo, intensidade) * 3.5 * pesoKg / 200 * minutos;
  }

  Map<String, Object?> paraJson() => <String, Object?>{
        'tipo': tipo.name,
        'minutos': minutos,
        'quando': quando.toIso8601String(),
        'intensidade': intensidade.name,
      };

  factory Atividade.doJson(Map<String, Object?> json) => Atividade(
        tipo: TipoAtividade.values.firstWhere(
          (TipoAtividade t) => t.name == json['tipo'],
          orElse: () => TipoAtividade.outro,
        ),
        minutos: (json['minutos'] as num?)?.toInt() ?? 0,
        quando: DateTime.tryParse((json['quando'] as String?) ?? '') ??
            DateTime.now(),
        intensidade: Intensidade.values.firstWhere(
          (Intensidade i) => i.name == json['intensidade'],
          orElse: () => Intensidade.moderada,
        ),
      );
}

enum TipoAtividade { caminhada, corrida, outro }

enum Intensidade { leve, moderada, forte }

extension TipoAtividadeTexto on TipoAtividade {
  String get rotulo => switch (this) {
        TipoAtividade.caminhada => 'Caminhada',
        TipoAtividade.corrida => 'Corrida',
        TipoAtividade.outro => 'Outro',
      };

  String get emoji => switch (this) {
        TipoAtividade.caminhada => '🚶',
        TipoAtividade.corrida => '🏃',
        TipoAtividade.outro => '🤸',
      };
}

extension IntensidadeTexto on Intensidade {
  String get rotulo => switch (this) {
        Intensidade.leve => 'Leve',
        Intensidade.moderada => 'Moderada',
        Intensidade.forte => 'Forte',
      };

  String get descricao => switch (this) {
        Intensidade.leve => 'dá para conversar cantando',
        Intensidade.moderada => 'dá para conversar, sem cantar',
        Intensidade.forte => 'conversa fica difícil',
      };
}

/// METs do **Compendium of Physical Activities** (Ainsworth et al.), faixas
/// moderadas para adultos e idosos. Valores arredondados de propósito: o
/// objetivo é orientação, não precisão de laboratório.
double metDe(TipoAtividade tipo, Intensidade intensidade) {
  switch (tipo) {
    case TipoAtividade.caminhada:
      return switch (intensidade) {
        Intensidade.leve => 2.8, // ~4 km/h, passo tranquilo
        Intensidade.moderada => 3.8, // ~5,6 km/h
        Intensidade.forte => 5.0, // ~6,4 km/h, passo firme
      };
    case TipoAtividade.corrida:
      return switch (intensidade) {
        Intensidade.leve => 8.3, // ~8 km/h (trote)
        Intensidade.moderada => 9.8, // ~10 km/h
        Intensidade.forte => 11.5, // ~12 km/h
      };
    case TipoAtividade.outro:
      return switch (intensidade) {
        Intensidade.leve => 3.0, // alongamento, hidroginástica leve
        Intensidade.moderada => 4.5, // musculação leve, dança
        Intensidade.forte => 6.0, // esforço contínuo
      };
  }
}

/// Total de minutos nos últimos [dias] dias (hoje incluso).
int minutosNosUltimos(List<Atividade> lista, int dias, {DateTime? referencia}) {
  final DateTime agora = referencia ?? DateTime.now();
  final DateTime limite = DateTime(agora.year, agora.month, agora.day)
      .subtract(Duration(days: dias - 1));

  int total = 0;
  for (final Atividade a in lista) {
    if (!a.quando.isBefore(limite)) total += a.minutos;
  }
  return total;
}

/// Soma de calorias dos últimos [dias] dias; `null` se não há peso.
double? caloriasNosUltimos(
  List<Atividade> lista,
  int dias,
  double? pesoKg, {
  DateTime? referencia,
}) {
  if (pesoKg == null || pesoKg <= 0) return null;

  final DateTime agora = referencia ?? DateTime.now();
  final DateTime limite = DateTime(agora.year, agora.month, agora.day)
      .subtract(Duration(days: dias - 1));

  double total = 0;
  for (final Atividade a in lista) {
    if (a.quando.isBefore(limite)) continue;
    total += a.calorias(pesoKg) ?? 0;
  }
  return total;
}

/// Quantos dias distintos tiveram atividade nos últimos [dias].
int diasAtivos(List<Atividade> lista, int dias, {DateTime? referencia}) {
  final DateTime agora = referencia ?? DateTime.now();
  final DateTime limite = DateTime(agora.year, agora.month, agora.day)
      .subtract(Duration(days: dias - 1));

  final Set<String> chaves = <String>{};
  for (final Atividade a in lista) {
    if (a.quando.isBefore(limite)) continue;
    chaves.add('${a.quando.year}-${a.quando.month}-${a.quando.day}');
  }
  return chaves.length;
}
