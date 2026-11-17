// Formatação de telefone dos contatos de emergência.

import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/features/safety/domain/contato.dart';

void main() {
  test('formata celular de 11 dígitos', () {
    expect(telefoneFormatado('21999998888'), '(21) 99999-8888');
    expect(telefoneFormatado('(21) 99999-8888'), '(21) 99999-8888');
  });

  test('formata fixo de 10 dígitos', () {
    expect(telefoneFormatado('2133334444'), '(21) 3333-4444');
  });

  test('formata com DDI 55', () {
    expect(telefoneFormatado('5521999998888'), '+55 (21) 99999-8888');
  });

  test('soDigitos limpa qualquer máscara', () {
    expect(soDigitos('(21) 9 9999-8888'), '21999998888');
    expect(soDigitos('+55 21 99999-8888'), '5521999998888');
  });
}
