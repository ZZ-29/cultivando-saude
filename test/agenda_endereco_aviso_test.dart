// O aviso de 1h/30min precisa levar o ENDEREÇO — quem perde consulta é quem
// tem a hora e não tem o lugar.

import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/features/agenda/domain/aviso.dart';
import 'package:cultivando_saude/features/agenda/domain/compromisso.dart';

void main() {
  test('compromisso sem endereço é reconhecido como risco', () {
    final Compromisso semEndereco = Compromisso(
      titulo: 'Otorrino',
      tipo: TipoCompromisso.consulta,
      quando: DateTime(2026, 11, 20, 17),
      local: 'Clínica Otorrino',
    );
    expect(semEndereco.temEndereco, isFalse);

    final Compromisso comEndereco = Compromisso(
      titulo: 'Otorrino',
      tipo: TipoCompromisso.consulta,
      quando: DateTime(2026, 11, 20, 17),
      endereco: 'Rua das Acácias, 120 — Centro',
    );
    expect(comEndereco.temEndereco, isTrue);
  });

  test('os dois avisos existem para quem tem endereço ou não', () {
    final Compromisso c = Compromisso(
      titulo: 'Otorrino',
      tipo: TipoCompromisso.consulta,
      quando: DateTime.now().add(const Duration(hours: 3)),
      endereco: 'Rua das Acácias, 120 — Centro',
    );
    final List<Aviso> avisos = avisosFuturosDo(c);
    expect(avisos.length, 2);
    expect(avisos.first.minutosAntes, 60);
  });
}
