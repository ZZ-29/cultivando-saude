/// Um exame (ou resultado) guardado pela pessoa.
///
/// Guarda também **quem pediu** (médico) e o **local/laboratório**, porque é
/// o que a pessoa precisa quando leva o exame a outro profissional — a foto do
/// resultado fica junto, quando houver.
class Exame {
  const Exame({
    this.id,
    required this.nome,
    required this.quando,
    this.local = '',
    this.medico = '',
    this.foto,
  });

  final int? id;
  final String nome;
  final DateTime quando;
  final String local;
  final String medico;

  /// Caminho da foto do resultado (null = sem foto).
  final String? foto;

  bool get temFoto => (foto ?? '').trim().isNotEmpty;
  bool get temMedico => medico.trim().isNotEmpty;

  Exame copiarCom({int? id}) => Exame(
        id: id ?? this.id,
        nome: nome,
        quando: quando,
        local: local,
        medico: medico,
        foto: foto,
      );

  Map<String, Object?> paraJson() => <String, Object?>{
        'nome': nome,
        'quando': quando.toIso8601String(),
        'local': local,
        'medico': medico,
        'foto': foto,
      };

  factory Exame.doJson(Map<String, Object?> json) => Exame(
        nome: (json['nome'] as String?) ?? '',
        quando: DateTime.tryParse((json['quando'] as String?) ?? '') ??
            DateTime.now(),
        local: (json['local'] as String?) ?? '',
        medico: (json['medico'] as String?) ?? '',
        foto: json['foto'] as String?,
      );
}
