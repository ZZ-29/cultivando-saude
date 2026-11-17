/// Uma vitamina **ou** um suplemento alimentar do dia a dia.
///
/// Duas classes no mesmo lugar, porque a rotina é a mesma: uma dose, um
/// horário, um "tomei". A diferença é o que está escrito no rótulo — e o app
/// mostra essa diferença na hora de listar.
class Vitamina {
  const Vitamina({
    this.id,
    required this.nome,
    this.classe = ClasseVitamina.vitamina,
    this.dosagem = '',
    this.horario = '08:00',
    this.horarios,
    this.tomadas = const <DateTime>[],
    this.estoque,
  });

  final int? id;
  final String nome;

  /// Vitamina ou suplemento (proteína, creatina, ômega…).
  final ClasseVitamina classe;

  /// "1 comprimido", "30 g", "1 scoop".
  final String dosagem;

  /// Primeiro horário (compatibilidade com dados antigos).
  final String horario;

  /// Todos os horários do dia. Quando vazio, vale [horario].
  final List<String>? horarios;

  /// Tomadas registradas — a **hora** marca qual dose do dia foi feita.
  final List<DateTime> tomadas;

  /// Quantas doses ainda restam. `null` = não controla estoque.
  final int? estoque;

  /// Horários efetivos (nunca vazio).
  List<String> get horariosDoDia {
    final List<String> lista = horarios ?? const <String>[];
    if (lista.isNotEmpty) return lista;
    return <String>[horario];
  }

  bool get temVariosHorarios => horariosDoDia.length > 1;

  static bool _mesmoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Dose de um horário específico já foi tomada no dia?
  bool tomadaNoHorario(String hhmm, DateTime dia) {
    final int hora = int.tryParse(hhmm.split(':').first) ?? 8;
    for (final DateTime t in tomadas) {
      if (!_mesmoDia(t, dia)) continue;
      // Dado antigo (só a data): vale como dose do dia inteiro.
      final bool legado = t.hour == 0 && t.minute == 0 && t.second == 0;
      if (legado || t.hour == hora) return true;
    }
    return false;
  }

  /// Alguma dose tomada no dia.
  bool get tomadaHoje {
    final DateTime agora = DateTime.now();
    return tomadas.any((DateTime t) => _mesmoDia(t, agora));
  }

  /// Quantas das doses de hoje já foram feitas.
  int dosesTomadasHoje() {
    final DateTime agora = DateTime.now();
    return horariosDoDia
        .where((String h) => tomadaNoHorario(h, agora))
        .length;
  }

  /// Quantos dias dos últimos [dias] tiveram tomada (hoje incluso).
  int diasTomados(int dias, {DateTime? referencia}) {
    final DateTime agora = referencia ?? DateTime.now();
    final DateTime limite = DateTime(agora.year, agora.month, agora.day)
        .subtract(Duration(days: dias - 1));

    final Set<String> diasUnicos = <String>{};
    for (final DateTime t in tomadas) {
      if (t.isBefore(limite)) continue;
      diasUnicos.add('${t.year}-${t.month}-${t.day}');
    }
    return diasUnicos.length;
  }

  /// Estoque depois de uma tomada.
  int? get estoqueAposTomar =>
      estoque == null ? null : (estoque! > 0 ? estoque! - 1 : 0);

  bool get acabando => estoque != null && estoque! <= 5;

  Vitamina copiarCom({
    int? id,
    String? nome,
    ClasseVitamina? classe,
    String? dosagem,
    String? horario,
    List<String>? horarios,
    List<DateTime>? tomadas,
    int? estoque,
    bool limparEstoque = false,
  }) =>
      Vitamina(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        classe: classe ?? this.classe,
        dosagem: dosagem ?? this.dosagem,
        horario: horario ?? this.horario,
        horarios: horarios ?? this.horarios,
        tomadas: tomadas ?? this.tomadas,
        estoque: limparEstoque ? null : (estoque ?? this.estoque),
      );

  /// Registra a dose de um horário (com a hora do horário, não do relógio).
  Vitamina tomarNoHorario(String hhmm, {DateTime? dia}) {
    final DateTime base = dia ?? DateTime.now();
    final int hora = int.tryParse(hhmm.split(':').first) ?? 8;
    final int minuto = int.tryParse(hhmm.split(':').last) ?? 0;
    return copiarCom(
      tomadas: <DateTime>[
        ...tomadas,
        DateTime(base.year, base.month, base.day, hora, minuto),
      ],
      estoque: estoqueAposTomar,
      limparEstoque: false,
    );
  }

  /// Marca a tomada de agora e baixa o estoque.
  Vitamina tomarAgora() => copiarCom(
        tomadas: <DateTime>[...tomadas, DateTime.now()],
        estoque: estoqueAposTomar,
        limparEstoque: false,
      );

  /// Desfaz a última tomada de hoje (devolve o comprimido ao estoque).
  Vitamina desfazerHoje() {
    final DateTime agora = DateTime.now();
    final List<DateTime> restantes =
        tomadas.where((DateTime t) => !_mesmoDia(t, agora)).toList();

    return copiarCom(
      tomadas: restantes,
      estoque: estoque == null ? null : estoque! + 1,
      limparEstoque: false,
    );
  }

  Map<String, Object?> paraJson() => <String, Object?>{
        'nome': nome,
        'classe': classe.name,
        'dosagem': dosagem,
        'horario': horario,
        'horarios': horariosDoDia,
        'tomadas': tomadas.map((DateTime t) => t.toIso8601String()).toList(),
        'estoque': estoque,
      };

  factory Vitamina.doJson(Map<String, Object?> json) {
    final Object? cru = json['tomadas'];
    final List<DateTime> lista = <DateTime>[];
    if (cru is List) {
      for (final Object? item in cru) {
        if (item is String) {
          final DateTime? d = DateTime.tryParse(item);
          if (d != null) lista.add(d);
        }
      }
    }

    final Object? cruHorarios = json['horarios'];
    final List<String> horarios = cruHorarios is List
        ? cruHorarios.whereType<String>().toList(growable: false)
        : const <String>[];

    return Vitamina(
      nome: (json['nome'] as String?) ?? '',
      classe: ClasseVitamina.values.firstWhere(
        (ClasseVitamina c) => c.name == json['classe'],
        orElse: () => ClasseVitamina.vitamina,
      ),
      dosagem: (json['dosagem'] as String?) ?? '',
      horario: (json['horario'] as String?) ?? '08:00',
      horarios: horarios.isEmpty ? null : horarios,
      tomadas: lista,
      estoque: (json['estoque'] as num?)?.toInt(),
    );
  }
}

/// As duas classes que o card abriga.
enum ClasseVitamina { vitamina, suplemento }

extension ClasseVitaminaInfo on ClasseVitamina {
  String get rotulo => switch (this) {
        ClasseVitamina.vitamina => 'Vitamina',
        ClasseVitamina.suplemento => 'Suplemento',
      };

  String get plural => switch (this) {
        ClasseVitamina.vitamina => 'Vitaminas',
        ClasseVitamina.suplemento => 'Suplementos',
      };

  String get emoji => switch (this) {
        ClasseVitamina.vitamina => '💊',
        ClasseVitamina.suplemento => '🥤',
      };
}
