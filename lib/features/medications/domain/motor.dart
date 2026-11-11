import 'medicamento.dart';

/// Motor de cálculo do tratamento — as regras do "Hermes" em Dart puro.
///
/// Tudo aqui é função pura: recebe datas e devolve ocorrências. Sem banco, sem
/// widget, sem plugin — por isso dá para testar com `flutter test`.
///
/// Regras herdadas do app anterior:
///   • intervalo entre a última dose de uma fase e a primeira da próxima
///     depende da frequência NOVA (1x/dia = 24h, semanal = 7 dias, mensal =
///     30 dias, de X em X horas = X horas, múltiplas = 1440/n);
///   • ciclo alterna dias tomando e dias de pausa a partir do início;
///   • se o horário calculado cair entre 00:00 e 05:59, o app sugere 06:00
///     (a pessoa decide) — não mexe no sono sem avisar.

/// Uma dose prevista.
class Ocorrencia {
  const Ocorrencia({
    required this.quando,
    required this.faseIndex,
  });

  final DateTime quando;
  final int faseIndex;

  /// Chave estável usada para registrar que a dose foi tomada.
  String get chave => '${isoDia(quando)}|${hhmm(quando)}';

  Ocorrencia copiarCom({int? faseIndex}) =>
      Ocorrencia(quando: quando, faseIndex: faseIndex ?? this.faseIndex);
}

/// Estado de uma dose segundo o Hermes.
enum EstadoDose {
  /// Já registrada como tomada.
  tomado,

  /// O horário passou e não foi registrada.
  atrasado,

  /// Ainda vai acontecer.
  agendado,

  /// Não é dose de hoje (pausa do ciclo, outro dia da semana, fase futura…).
  suspenso,
}

/// Resultado do cálculo da primeira dose de uma fase nova.
class CalculoNovaFase {
  const CalculoNovaFase({
    required this.inicio,
    required this.caiuDeMadrugada,
    this.sugestao,
  });

  final DateTime inicio;

  /// true quando o horário calculado está entre 00:00 e 05:59.
  final bool caiuDeMadrugada;

  /// Versão com 06:00, para oferecer à pessoa.
  final DateTime? sugestao;

  /// O horário sugerido, no formato "HH:MM".
  String? get sugestaoHora =>
      sugestao == null ? null : hhmm(sugestao!);
}

abstract final class MotorRemedios {
  /// Horário "de madrugada" conforme a regra do app: 00:00 até 05:59.
  static bool ehMadrugada(DateTime quando) => quando.hour < 6;

  /// Todas as doses previstas para um dia.
  ///
  /// Já aplica: janela de cada fase, ciclo (pausa), dias da semana e o
  /// intervalo em horas (que rola de um dia para o outro).
  static List<Ocorrencia> ocorrenciasDoDia(Medicamento med, DateTime dia) {
    final DateTime alvo = DateTime(dia.year, dia.month, dia.day);

    // SOS não tem dose prevista.
    if (med.duracao == TipoDuracao.sos) return const <Ocorrencia>[];

    final List<Ocorrencia> saida = <Ocorrencia>[];

    for (int i = 0; i < med.fases.length; i++) {
      final Fase fase = med.fases[i];
      if (!fase.contemDia(alvo)) continue;

      // Ciclo: dia de pausa não tem dose.
      if (!_diaAtivoNoCiclo(med, alvo)) continue;

      for (final DateTime quando in _horariosDaFaseNoDia(fase, alvo)) {
        saida.add(Ocorrencia(quando: quando, faseIndex: i));
      }
    }

    saida.sort((Ocorrencia a, Ocorrencia b) => a.quando.compareTo(b.quando));
    return saida;
  }

  /// Estado da dose considerando o que já foi registrado.
  static EstadoDose estadoDe(
    Ocorrencia ocorrencia,
    DateTime agora,
    Set<String> tomadas,
  ) {
    if (tomadas.contains(ocorrencia.chave)) return EstadoDose.tomado;
    return ocorrencia.quando.isAfter(agora)
        ? EstadoDose.agendado
        : EstadoDose.atrasado;
  }

  /// Última dose prevista da última fase do tratamento.
  ///
  /// Fase sem data de fim usa um horizonte de 370 dias (mesmo limite do app
  /// anterior) — não faz sentido calcular "até o infinito".
  static DateTime? ultimaDose(Medicamento med) {
    if (med.fases.isEmpty) return null;

    final int indice = med.fases.length - 1;
    final Fase fase = med.fases[indice];

    final int limiteDias = fase.duracaoDias == null ? 370 : fase.duracaoDias!;
    final int passos = limiteDias > 400 ? 400 : limiteDias;

    DateTime cursor = DateTime(
      fase.inicio.year,
      fase.inicio.month,
      fase.inicio.day,
    );
    DateTime? ultima;

    for (int i = 0; i < passos; i++) {
      for (final Ocorrencia o in ocorrenciasDoDia(med, cursor)) {
        if (o.faseIndex != indice) continue;
        if (ultima == null || o.quando.isAfter(ultima)) {
          ultima = o.quando;
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return ultima;
  }

  /// Primeira dose da fase nova = última dose da fase anterior + intervalo
  /// da frequência nova (regra do Hermes).
  ///
  /// Se não houver fase anterior, começa hoje no primeiro horário.
  static CalculoNovaFase calcularNovaFase(Medicamento med, Frequencia nova) {
    final DateTime? anterior = ultimaDose(med);

    DateTime inicio;
    if (anterior == null) {
      final String hora =
          nova.horarios.isNotEmpty ? nova.horarios.first : nova.primeiraDose;
      inicio = _comHora(DateTime.now(), hora);
    } else {
      inicio = anterior.add(Duration(minutes: intervaloDaFrequencia(nova)));
    }

    if (!ehMadrugada(inicio)) {
      return CalculoNovaFase(inicio: inicio, caiuDeMadrugada: false);
    }

    final DateTime sugestao = DateTime(
      inicio.year,
      inicio.month,
      inicio.day,
      6,
      0,
    );
    return CalculoNovaFase(
      inicio: inicio,
      caiuDeMadrugada: true,
      sugestao: sugestao,
    );
  }

  /// Intervalo, em minutos, entre a última dose de uma fase e a primeira da
  /// próxima — igual à tabela do app anterior.
  static int intervaloDaFrequencia(Frequencia f) {
    switch (f.tipo) {
      case TipoFrequencia.intervaloHoras:
        return (f.intervaloHoras ?? 8) * 60;
      case TipoFrequencia.variasAoDia:
        final int n = f.horarios.isEmpty ? 2 : f.horarios.length;
        return (1440 / (n < 2 ? 2 : n)).round();
      case TipoFrequencia.umaAoDia:
        return 1440;
      case TipoFrequencia.diasSemana:
        return 1440;
      case TipoFrequencia.semanal:
        return 7 * 1440;
      case TipoFrequencia.mensal:
        return 30 * 1440;
      case TipoFrequencia.sos:
        return 1440;
    }
  }

  /// Resumo legível de uma fase, para a tela.
  static String descreverFase(Fase fase) {
    final String freq = fase.frequencia.resumo;
    final String dur = fase.duracaoDias == null
        ? 'sem data de fim'
        : '${fase.duracaoDias} dias';
    return '$freq · $dur · início ${ddmmyyyy(fase.inicio)}';
  }

  // ---------------------------------------------------------------------
  // Interno
  // ---------------------------------------------------------------------

  static bool _diaAtivoNoCiclo(Medicamento med, DateTime dia) {
    if (med.duracao != TipoDuracao.ciclo) return true;

    final int dias = med.cicloDias ?? 21;
    final int pausa = med.cicloPausa ?? 7;
    if (pausa <= 0) return true;

    final int total = dias + pausa;
    final DateTime inicio = DateTime.utc(
      med.inicio.year,
      med.inicio.month,
      med.inicio.day,
    );
    final int delta = DateTime.utc(dia.year, dia.month, dia.day)
        .difference(inicio)
        .inDays;
    if (delta < 0) return false;

    return delta % total < dias;
  }

  /// Horários de uma fase num dia específico.
  static List<DateTime> _horariosDaFaseNoDia(Fase fase, DateTime dia) {
    final Frequencia f = fase.frequencia;

    switch (f.tipo) {
      case TipoFrequencia.sos:
        return const <DateTime>[];

      case TipoFrequencia.intervaloHoras:
        return _intervaloNoDia(fase, dia);

      case TipoFrequencia.umaAoDia:
        if (f.horarios.isEmpty) return const <DateTime>[];
        return <DateTime>[_comHora(dia, f.horarios.first)];

      case TipoFrequencia.variasAoDia:
        return f.horarios
            .map((String h) => _comHora(dia, h))
            .toList(growable: false);

      case TipoFrequencia.diasSemana:
        if (!f.diasSemana.contains(dia.weekday)) return const <DateTime>[];
        return f.horarios
            .map((String h) => _comHora(dia, h))
            .toList(growable: false);

      case TipoFrequencia.semanal:
        if (f.diaSemana != dia.weekday) return const <DateTime>[];
        if (f.horarios.isEmpty) return const <DateTime>[];
        return <DateTime>[_comHora(dia, f.horarios.first)];

      case TipoFrequencia.mensal:
        if (f.diaMes != dia.day) return const <DateTime>[];
        if (f.horarios.isEmpty) return const <DateTime>[];
        return <DateTime>[_comHora(dia, f.horarios.first)];
    }
  }

  /// Doses "de X em X horas" que caem neste dia.
  ///
  /// A sequência nasce no início da fase + primeira dose e rola sem parar:
  /// 08:00, 16:00, 00:00, 08:00… por isso uma dose das 00:00 pertence ao dia
  /// seguinte, e não ao primeiro.
  static List<DateTime> _intervaloNoDia(Fase fase, DateTime dia) {
    final int passo = (fase.frequencia.intervaloHoras ?? 8) * 60;
    final DateTime base = _comHora(fase.inicio, fase.frequencia.primeiraDose);

    // Janela do dia consultado.
    final DateTime inicioDia = DateTime(dia.year, dia.month, dia.day);
    final DateTime fimDia = inicioDia.add(const Duration(days: 1));

    // Primeiro múltiplo do passo dentro do dia.
    int minutosDesdeBase = inicioDia.difference(base).inMinutes;
    if (minutosDesdeBase < 0) {
      minutosDesdeBase = 0;
    } else {
      final int resto = minutosDesdeBase % passo;
      if (resto != 0) minutosDesdeBase += passo - resto;
    }

    final List<DateTime> saida = <DateTime>[];
    DateTime quando = base.add(Duration(minutes: minutosDesdeBase));
    // Trava de segurança: no máximo 200 doses por dia.
    for (int i = 0; i < 200 && quando.isBefore(fimDia); i++) {
      if (!quando.isBefore(inicioDia)) saida.add(quando);
      quando = quando.add(Duration(minutes: passo));
    }
    return saida;
  }

  static DateTime _comHora(DateTime dia, String hhmm) {
    final List<String> partes = hhmm.split(':');
    final int hora = partes.isNotEmpty ? (int.tryParse(partes[0]) ?? 8) : 8;
    final int minuto = partes.length > 1 ? (int.tryParse(partes[1]) ?? 0) : 0;
    return DateTime(dia.year, dia.month, dia.day, hora, minuto);
  }
}

// --- formatação (sem pacote de idioma) -------------------------------------

String dois(int n) => n.toString().padLeft(2, '0');

String hhmm(DateTime d) => '${dois(d.hour)}:${dois(d.minute)}';

String isoDia(DateTime d) => '${d.year}-${dois(d.month)}-${dois(d.day)}';

String ddmmyyyy(DateTime d) => '${dois(d.day)}/${dois(d.month)}/${d.year}';
