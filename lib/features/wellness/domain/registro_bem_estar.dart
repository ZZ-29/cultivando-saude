/// Registro diário de bem-estar.
///
/// Quatro toques, não formulário: sono, humor, dor e convivência — os quatro
/// pontos que a literatura em geriatria aponta como os que mais pesam na vida
/// de quem tem 70+. Mais os copos de água do dia (idoso sente menos sede).
class RegistroBemEstar {
  const RegistroBemEstar({
    this.id,
    required this.dia,
    this.humor,
    this.sono,
    this.horasSono,
    this.dor,
    this.convivio,
    this.agua = 0,
  });

  final int? id;

  /// Dia (sem hora).
  final DateTime dia;
  final Humor? humor;
  final QualidadeSono? sono;
  final double? horasSono;
  final Dor? dor;
  final Convivio? convivio;

  /// Copos de água no dia.
  final int agua;

  static DateTime soData(DateTime d) => DateTime(d.year, d.month, d.day);

  bool get ehHoje {
    final DateTime hoje = soData(DateTime.now());
    return dia.year == hoje.year && dia.month == hoje.month && dia.day == hoje.day;
  }

  /// Algum registro já foi feito neste dia.
  bool get temAlgo =>
      humor != null ||
      sono != null ||
      dor != null ||
      convivio != null ||
      agua > 0 ||
      horasSono != null;

  RegistroBemEstar copiarCom({
    int? id,
    Humor? humor,
    QualidadeSono? sono,
    double? horasSono,
    Dor? dor,
    Convivio? convivio,
    int? agua,
  }) =>
      RegistroBemEstar(
        id: id ?? this.id,
        dia: dia,
        humor: humor ?? this.humor,
        sono: sono ?? this.sono,
        horasSono: horasSono ?? this.horasSono,
        dor: dor ?? this.dor,
        convivio: convivio ?? this.convivio,
        agua: agua ?? this.agua,
      );

  /// Linha de resumo do dia: "bem · dormiu bem · sem dor".
  String get resumo {
    final List<String> partes = <String>[
      if (humor != null) humor!.rotulo.toLowerCase(),
      if (sono != null) sono!.frase,
      if (dor != null) dor!.frase,
      if (convivio != null) convivio!.frase,
      if (agua > 0) '$agua ${agua == 1 ? 'copo' : 'copos'} de água',
    ];
    return partes.isEmpty ? 'sem registro' : partes.join(' · ');
  }

  Map<String, Object?> paraJson() => <String, Object?>{
        'dia': dia.toIso8601String(),
        'humor': humor?.name,
        'sono': sono?.name,
        'horas_sono': horasSono,
        'dor': dor?.name,
        'convivio': convivio?.name,
        'agua': agua,
      };

  factory RegistroBemEstar.doJson(Map<String, Object?> json) {
    T? ler<T extends Enum>(List<T> valores, Object? bruto) {
      for (final T v in valores) {
        if (v.name == bruto) return v;
      }
      return null;
    }

    return RegistroBemEstar(
      dia: DateTime.tryParse((json['dia'] as String?) ?? '') ?? DateTime.now(),
      humor: ler<Humor>(Humor.values, json['humor']),
      sono: ler<QualidadeSono>(QualidadeSono.values, json['sono']),
      horasSono: (json['horas_sono'] as num?)?.toDouble(),
      dor: ler<Dor>(Dor.values, json['dor']),
      convivio: ler<Convivio>(Convivio.values, json['convivio']),
      agua: (json['agua'] as num?)?.toInt() ?? 0,
    );
  }
}

enum Humor { bem, maisOuMenos, mal }

extension HumorInfo on Humor {
  String get rotulo => switch (this) {
        Humor.bem => 'Bem',
        Humor.maisOuMenos => 'Mais ou menos',
        Humor.mal => 'Mal',
      };

  String get emoji => switch (this) {
        Humor.bem => '🙂',
        Humor.maisOuMenos => '😐',
        Humor.mal => '🙁',
      };
}

/// Como foi a noite — mais útil que a contagem de horas.
enum QualidadeSono { bem, maisOuMenos, mal }

extension QualidadeSonoInfo on QualidadeSono {
  String get rotulo => switch (this) {
        QualidadeSono.bem => 'Dormi bem',
        QualidadeSono.maisOuMenos => 'Mais ou menos',
        QualidadeSono.mal => 'Dormi mal',
      };

  String get frase => switch (this) {
        QualidadeSono.bem => 'dormiu bem',
        QualidadeSono.maisOuMenos => 'sono irregular',
        QualidadeSono.mal => 'dormiu mal',
      };

  String get emoji => switch (this) {
        QualidadeSono.bem => '😴',
        QualidadeSono.maisOuMenos => '😐',
        QualidadeSono.mal => '😖',
      };
}

enum Dor { nenhuma, leve, forte }

extension DorInfo on Dor {
  String get rotulo => switch (this) {
        Dor.nenhuma => 'Sem dor',
        Dor.leve => 'Leve',
        Dor.forte => 'Forte',
      };

  String get frase => switch (this) {
        Dor.nenhuma => 'sem dor',
        Dor.leve => 'dor leve',
        Dor.forte => 'dor forte',
      };

  String get emoji => switch (this) {
        Dor.nenhuma => '✅',
        Dor.leve => '😕',
        Dor.forte => '😣',
      };

  bool get teveDor => this != Dor.nenhuma;
}

enum Convivio { pessoalmente, telefone, ninguem }

extension ConvivioInfo on Convivio {
  String get rotulo => switch (this) {
        Convivio.pessoalmente => 'Pessoalmente',
        Convivio.telefone => 'Por telefone',
        Convivio.ninguem => 'Não falei',
      };

  String get frase => switch (this) {
        Convivio.pessoalmente => 'conversou pessoalmente',
        Convivio.telefone => 'conversou por telefone',
        Convivio.ninguem => 'não conversou',
      };

  String get emoji => switch (this) {
        Convivio.pessoalmente => '🤝',
        Convivio.telefone => '📞',
        Convivio.ninguem => '🫥',
      };
}
