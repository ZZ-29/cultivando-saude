import '../domain/medicamento.dart';

/// Um alarme de dose a agendar no celular.
///
/// Separa **o que** avisar (remédio e horário) de **como** (notificação do
/// sistema). Assim a regra fica testável sem plugin.
class AlarmeDose {
  const AlarmeDose({
    required this.medicamentoId,
    required this.nome,
    required this.hhmm,
    this.dosagem = '',
    this.diasSemana = const <int>[],
    this.diaMes,
    this.indice = 0,
  });

  final int medicamentoId;
  final String nome;
  final String dosagem;

  /// "HH:MM"
  final String hhmm;

  /// Dias da semana (1 = segunda … 7 = domingo). Vazio = todos os dias.
  final List<int> diasSemana;

  /// Dia do mês, para frequência mensal. `null` = não é mensal.
  final int? diaMes;

  final int indice;

  /// Identificador da notificação: único por remédio + horário.
  int get id => medicamentoId * 100 + indice;

  String get chave => '$medicamentoId|$hhmm';
}

/// Calcula os alarmes de uma lista de remédios.
///
/// Regras (espelham o motor do app):
///   • SOS não gera alarme — "só quando precisar";
///   • tratamento concluído não gera alarme;
///   • cada horário da fase atual vira um alarme diário;
///   • frequência por dias da semana gera alarme só naqueles dias;
///   • mensal gera alarme no dia do mês.
///
/// Teto de [limite] alarmes: melhor avisar os principais do que encher o
/// celular de notificações.
List<AlarmeDose> alarmesDe(
  List<Medicamento> medicamentos, {
  int limite = 50,
}) {
  final List<AlarmeDose> saida = <AlarmeDose>[];

  for (final Medicamento med in medicamentos) {
    final int? id = med.id;
    if (id == null) continue;
    if (med.duracao == TipoDuracao.sos) continue;
    if (med.fases.isEmpty) continue;

    final Fase fase = med.fases.last;
    final Frequencia freq = fase.frequencia;

    // Uma lista de horários, venha ela de quais horários ou de intervalo.
    final List<String> horarios = _horariosDa(freq);
    if (horarios.isEmpty) continue;

    for (int i = 0; i < horarios.length; i++) {
      saida.add(
        AlarmeDose(
          medicamentoId: id,
          nome: med.nome,
          dosagem: med.dosagem,
          hhmm: horarios[i],
          diasSemana: freq.tipo == TipoFrequencia.diasSemana
              ? freq.diasSemana
              : const <int>[],
          diaMes: freq.tipo == TipoFrequencia.mensal ? freq.diaMes : null,
          indice: i,
        ),
      );
      if (saida.length >= limite) return saida;
    }
  }

  return saida;
}

/// Horários de uma frequência, em ordem crescente.
List<String> _horariosDa(Frequencia freq) {
  switch (freq.tipo) {
    case TipoFrequencia.sos:
      return const <String>[];
    case TipoFrequencia.intervaloHoras:
      return _horariosPorIntervalo(
        freq.primeiraDose,
        freq.intervaloHoras ?? 8,
      );
    case TipoFrequencia.mensal:
    case TipoFrequencia.semanal:
    case TipoFrequencia.diasSemana:
    case TipoFrequencia.umaAoDia:
    case TipoFrequencia.variasAoDia:
      final List<String> lista = List<String>.from(freq.horarios);
      if (lista.isEmpty) lista.add(freq.primeiraDose);
      lista.sort();
      return lista;
  }
}

/// "20:00" a cada 12h → 08:00 e 20:00 (o dia tem os dois horários).
List<String> _horariosPorIntervalo(String primeira, int intervalo) {
  final int inicio = _minutosDe(primeira);
  final int passo = (intervalo <= 0 ? 8 : intervalo) * 60;
  final Set<int> minutos = <int>{};

  // Para a frente, dentro do dia.
  for (int m = inicio; m < 24 * 60; m += passo) {
    minutos.add(m);
  }
  // Para trás: a dose da madrugada vem do horário da noite anterior.
  for (int m = inicio - passo; m >= 0; m -= passo) {
    minutos.add(m);
  }

  final List<String> saida = minutos.map(_hhmm).toList()..sort();
  return saida;
}

int _minutosDe(String hhmm) {
  final List<String> p = hhmm.split(':');
  final int h = int.tryParse(p.first) ?? 8;
  final int m = p.length > 1 ? (int.tryParse(p[1]) ?? 0) : 0;
  return (h * 60 + m).clamp(0, 24 * 60 - 1);
}

String _hhmm(int minutos) {
  final int m = minutos % (24 * 60);
  final int h = m ~/ 60;
  final int min = m % 60;
  return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
}
