/// Uma medida de pressão arterial.
///
/// Guarda os dois números (sistólica/diastólica), o pulso opcional e o momento.
/// A classificação é **calculada**, não guardada — se a referência médica
/// mudar, o histórico inteiro se reclassifica sozinho.
class Medicao {
  const Medicao({
    this.id,
    required this.sistolica,
    required this.diastolica,
    this.pulso,
    required this.quando,
  });

  final int? id;
  final int sistolica;
  final int diastolica;
  final int? pulso;
  final DateTime quando;

  Medicao copiarCom({int? id}) => Medicao(
        id: id ?? this.id,
        sistolica: sistolica,
        diastolica: diastolica,
        pulso: pulso,
        quando: quando,
      );

  /// Classificação por faixas — **não é invenção do app**.
  ///
  /// **Fonte:** Diretrizes Brasileiras de Hipertensão Arterial – 2020
  /// (SBC/SBH/SBN), classificação da PA medida no consultório em adultos:
  ///
  ///   Normal ......... abaixo de 120/80
  ///   No limite ...... 120–139 / 80–89  (pré-hipertensão)
  ///   Atenção ........ 140–159 / 90–99  (hipertensão estágio 1)
  ///   Alerta ......... 160/100 ou mais  (estágios 2 e 3 reunidos)
  ///
  /// Crise hipertensiva (180/120 ou mais): Ministério da Saúde, Linhas de
  /// Cuidado de HAS — ver [criseHipertensiva].
  ///
  /// Vale o **maior** dos dois números: 118 por 95 já é atenção.
  ClassificacaoPressao get classificacao {
    if (sistolica >= 160 || diastolica >= 100) {
      return ClassificacaoPressao.alerta;
    }
    if (sistolica >= 140 || diastolica >= 90) {
      return ClassificacaoPressao.atencao;
    }
    if (sistolica >= 120 || diastolica >= 80) {
      return ClassificacaoPressao.limite;
    }
    return ClassificacaoPressao.normal;
  }

  /// Crise hipertensiva: 180/120 ou mais. Aqui a orientação é procurar
  /// atendimento **agora**, não "marcar consulta".
  bool get criseHipertensiva => sistolica >= 180 || diastolica >= 120;

  Map<String, Object?> paraJson() => <String, Object?>{
        'sistolica': sistolica,
        'diastolica': diastolica,
        'pulso': pulso,
        'quando': quando.toIso8601String(),
      };

  factory Medicao.doJson(Map<String, Object?> json) => Medicao(
        sistolica: (json['sistolica'] as num?)?.toInt() ?? 0,
        diastolica: (json['diastolica'] as num?)?.toInt() ?? 0,
        pulso: (json['pulso'] as num?)?.toInt(),
        quando: DateTime.tryParse((json['quando'] as String?) ?? '') ??
            DateTime.now(),
      );
}

enum ClassificacaoPressao { normal, limite, atencao, alerta }

extension ClassificacaoTexto on ClassificacaoPressao {
  String get rotulo => switch (this) {
        ClassificacaoPressao.normal => 'Normal',
        ClassificacaoPressao.limite => 'No limite',
        ClassificacaoPressao.atencao => 'Atenção',
        ClassificacaoPressao.alerta => 'Alerta',
      };

  /// Faixa, para a legenda da tela.
  String get faixa => switch (this) {
        ClassificacaoPressao.normal => 'abaixo de 120 por 80',
        ClassificacaoPressao.limite => '120 a 139 por 80 a 89',
        ClassificacaoPressao.atencao => '140 a 159 por 90 a 99',
        ClassificacaoPressao.alerta => '160 por 100 ou mais',
      };

  /// O que a referência médica manda fazer — **nada além disso**.
  ///
  /// Sem conselho de hábito (sal, exercício, dieta): o app classifica e, quando
  /// a diretriz indica avaliação médica, diz isso. O resto é conversa de
  /// consulta, não de aplicativo.
  String get orientacao => switch (this) {
        ClassificacaoPressao.normal => '',
        ClassificacaoPressao.limite => '',
        ClassificacaoPressao.atencao => '',
        ClassificacaoPressao.alerta => 'Procure atendimento médico.',
      };
}
