/// Uma pessoa cuidada pelo app.
///
/// O app nasceu para uma pessoa, mas cuidadoras acompanham várias. Em vez de
/// um celular por paciente (caro) ou nuvem (quebra a promessa de privacidade),
/// cada aparelho guarda **vários perfis** e cada registro sabe de quem é.
class Paciente {
  const Paciente({this.id, required this.nome});

  final int? id;
  final String nome;

  Paciente copiarCom({int? id}) => Paciente(id: id ?? this.id, nome: nome);

  bool get valido => nome.trim().isNotEmpty;

  Map<String, Object?> paraJson() => <String, Object?>{'nome': nome};

  factory Paciente.doJson(Map<String, Object?> json) =>
      Paciente(nome: (json['nome'] as String?) ?? '');
}
