/// Modelo do módulo de remédios — as regras do "Hermes" traduzidas para Dart.
///
/// Este arquivo não depende de Flutter nem de banco: é só o domínio.
library;

/// Por quanto tempo o tratamento dura.
enum TipoDuracao {
  /// Sem data de fim.
  continuo,

  /// Com data de fim (dias).
  temporario,

  /// Ex.: 21 dias tomando + 7 de pausa.
  ciclo,

  /// Só quando precisar — não agenda dose.
  sos,
}

/// Como as doses se repetem.
enum TipoFrequencia {
  umaAoDia,
  variasAoDia,
  intervaloHoras,
  diasSemana,
  semanal,
  mensal,
  sos,
}

String tipoDuracaoId(TipoDuracao t) => switch (t) {
      TipoDuracao.continuo => 'continuo',
      TipoDuracao.temporario => 'temporario',
      TipoDuracao.ciclo => 'ciclo',
      TipoDuracao.sos => 'sos',
    };

TipoDuracao tipoDuracaoDe(String? id) => switch (id) {
      'temporario' => TipoDuracao.temporario,
      'ciclo' => TipoDuracao.ciclo,
      'sos' => TipoDuracao.sos,
      _ => TipoDuracao.continuo,
    };

String tipoFrequenciaId(TipoFrequencia t) => switch (t) {
      TipoFrequencia.umaAoDia => 'uma',
      TipoFrequencia.variasAoDia => 'varias',
      TipoFrequencia.intervaloHoras => 'intervalo',
      TipoFrequencia.diasSemana => 'dias',
      TipoFrequencia.semanal => 'semanal',
      TipoFrequencia.mensal => 'mensal',
      TipoFrequencia.sos => 'sos',
    };

TipoFrequencia tipoFrequenciaDe(String? id) => switch (id) {
      'varias' => TipoFrequencia.variasAoDia,
      'intervalo' => TipoFrequencia.intervaloHoras,
      'dias' => TipoFrequencia.diasSemana,
      'semanal' => TipoFrequencia.semanal,
      'mensal' => TipoFrequencia.mensal,
      'sos' => TipoFrequencia.sos,
      _ => TipoFrequencia.umaAoDia,
    };

/// Configuração de frequência de uma fase.
class Frequencia {
  const Frequencia({
    required this.tipo,
    this.horarios = const <String>[],
    this.intervaloHoras,
    this.primeiraDose = '08:00',
    this.diasSemana = const <int>[],
    this.diaSemana,
    this.diaMes,
  });

  final TipoFrequencia tipo;

  /// Horários no formato "HH:MM".
  final List<String> horarios;

  /// Só para [TipoFrequencia.intervaloHoras] (1 a 24).
  final int? intervaloHoras;

  /// Só para [TipoFrequencia.intervaloHoras] — primeira dose do ciclo.
  final String primeiraDose;

  /// Só para [TipoFrequencia.diasSemana]. 1 = segunda … 7 = domingo.
  final List<int> diasSemana;

  /// Só para [TipoFrequencia.semanal].
  final int? diaSemana;

  /// Só para [TipoFrequencia.mensal].
  final int? diaMes;

  /// Texto curto para a lista.
  String get resumo => switch (tipo) {
        TipoFrequencia.umaAoDia => '1x ao dia',
        TipoFrequencia.variasAoDia => '${horarios.length}x ao dia',
        TipoFrequencia.intervaloHoras =>
          'de ${intervaloHoras ?? 8} em ${intervaloHoras ?? 8}h',
        TipoFrequencia.diasSemana => 'dias específicos',
        TipoFrequencia.semanal => '1x por semana',
        TipoFrequencia.mensal => '1x por mês',
        TipoFrequencia.sos => 'SOS',
      };

  Map<String, Object?> paraJson() => <String, Object?>{
        'tipo': tipoFrequenciaId(tipo),
        'horarios': horarios,
        'intervalo': intervaloHoras,
        'primeira': primeiraDose,
        'dias': diasSemana,
        'diaSemana': diaSemana,
        'diaMes': diaMes,
      };

  factory Frequencia.doJson(Map<String, Object?> j) => Frequencia(
        tipo: tipoFrequenciaDe(j['tipo'] as String?),
        horarios: _listaTexto(j['horarios']),
        intervaloHoras: (j['intervalo'] as num?)?.toInt(),
        primeiraDose: (j['primeira'] as String?) ?? '08:00',
        diasSemana: _listaInt(j['dias']),
        diaSemana: (j['diaSemana'] as num?)?.toInt(),
        diaMes: (j['diaMes'] as num?)?.toInt(),
      );
}

/// Uma fase do tratamento: frequência e duração próprias.
class Fase {
  const Fase({
    required this.frequencia,
    required this.inicio,
    this.duracaoDias,
  });

  final Frequencia frequencia;

  /// Primeiro dia da fase.
  final DateTime inicio;

  /// null = sem data de fim.
  final int? duracaoDias;

  bool contemDia(DateTime dia) {
    final int delta = _soData(dia).difference(_soData(inicio)).inDays;
    if (delta < 0) return false;
    if (duracaoDias == null) return true;
    return delta < duracaoDias!;
  }

  Map<String, Object?> paraJson() => <String, Object?>{
        'freq': frequencia.paraJson(),
        'inicio': inicio.toIso8601String(),
        'duracao': duracaoDias,
      };

  factory Fase.doJson(Map<String, Object?> j) {
    final Object? freqBruta = j['freq'];
    final Map<String, Object?> freqJson = freqBruta is Map
        ? freqBruta.cast<String, Object?>()
        : <String, Object?>{};

    return Fase(
      frequencia: Frequencia.doJson(freqJson),
      inicio: DateTime.tryParse((j['inicio'] as String?) ?? '') ??
          DateTime.now(),
      duracaoDias: (j['duracao'] as num?)?.toInt(),
    );
  }
}

/// O tratamento completo.
class Medicamento {
  const Medicamento({
    this.id,
    required this.nome,
    this.dosagem = '',
    required this.duracao,
    this.diasTratamento,
    this.cicloDias,
    this.cicloPausa,
    required this.fases,
    required this.criadoEm,
  });

  final int? id;
  final String nome;
  final String dosagem;
  final TipoDuracao duracao;

  /// Só para [TipoDuracao.temporario].
  final int? diasTratamento;

  /// Só para [TipoDuracao.ciclo].
  final int? cicloDias;
  final int? cicloPausa;

  final List<Fase> fases;
  final DateTime criadoEm;

  bool get temFases => fases.isNotEmpty;

  /// Data em que o tratamento começou (início da primeira fase).
  DateTime get inicio => fases.isEmpty ? criadoEm : fases.first.inicio;

  Map<String, Object?> paraJson() => <String, Object?>{
        'id': id,
        'nome': nome,
        'dosagem': dosagem,
        'duracao': tipoDuracaoId(duracao),
        'diasTratamento': diasTratamento,
        'cicloDias': cicloDias,
        'cicloPausa': cicloPausa,
        'fases': fases.map((Fase f) => f.paraJson()).toList(),
        'criadoEm': criadoEm.toIso8601String(),
      };

  factory Medicamento.doJson(Map<String, Object?> j) {
    final List<Fase> fases = <Fase>[];
    final Object? lista = j['fases'];
    if (lista is List) {
      for (final Object? item in lista) {
        if (item is Map<Object?, Object?>) {
          fases.add(Fase.doJson(item.cast<String, Object?>()));
        }
      }
    }

    return Medicamento(
      id: (j['id'] as num?)?.toInt(),
      nome: (j['nome'] as String?) ?? '',
      dosagem: (j['dosagem'] as String?) ?? '',
      duracao: tipoDuracaoDe(j['duracao'] as String?),
      diasTratamento: (j['diasTratamento'] as num?)?.toInt(),
      cicloDias: (j['cicloDias'] as num?)?.toInt(),
      cicloPausa: (j['cicloPausa'] as num?)?.toInt(),
      fases: fases,
      criadoEm: DateTime.tryParse((j['criadoEm'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  Medicamento copiarCom({int? id, List<Fase>? fases}) => Medicamento(
        id: id ?? this.id,
        nome: nome,
        dosagem: dosagem,
        duracao: duracao,
        diasTratamento: diasTratamento,
        cicloDias: cicloDias,
        cicloPausa: cicloPausa,
        fases: fases ?? this.fases,
        criadoEm: criadoEm,
      );
}

// --- utilidades internas ----------------------------------------------------

/// Data "pura" em UTC: diferenças de dias não sofrem com fuso nem horário de
/// verão (que já causou cálculo errado de ciclo em app de calendário).
DateTime _soData(DateTime d) => DateTime.utc(d.year, d.month, d.day);

List<String> _listaTexto(Object? cru) {
  if (cru is List) return cru.whereType<String>().toList(growable: false);
  return const <String>[];
}

List<int> _listaInt(Object? cru) {
  if (cru is List) {
    return cru.whereType<num>().map((num n) => n.toInt()).toList(growable: false);
  }
  return const <int>[];
}
