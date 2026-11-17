// Multi-perfil: trocar de pessoa isola os dados.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cultivando_saude/features/patients/data/paciente_atual.dart';
import 'package:cultivando_saude/features/patients/data/pacientes_repositorio.dart';
import 'package:cultivando_saude/features/patients/domain/paciente.dart';
import 'package:cultivando_saude/features/profile/data/perfil_repositorio.dart';
import 'package:cultivando_saude/features/profile/domain/perfil.dart';

void main() {
  setUp(() {
    usarPacientesRepo(PacientesMemoria());
    pacienteAtualId = null;
    usarPerfilRepo(PerfilMemoria());
  });

  test('o primeiro paciente existe e é "Eu"', () async {
    await garantirPacienteAtual();
    expect(pacienteIdAtual, 1);
    expect(nomePacienteAtual, 'Eu');
  });

  test('cada paciente tem seu próprio perfil', () async {
    await garantirPacienteAtual();
    await perfilRepo.salvar(const Perfil(nome: 'Eu', peso: 80));

    final Paciente maria =
        await pacientesRepo.salvar(const Paciente(nome: 'Dona Maria'));
    trocarPaciente(maria);
    expect(pacienteIdAtual, 2);

    // Perfil da segunda pessoa começa vazio
    final Perfil daMaria = await perfilRepo.ler();
    expect(daMaria.nome, '');

    await perfilRepo.salvar(const Perfil(nome: 'Dona Maria', peso: 62));

    // Voltar para o primeiro devolve o perfil dele
    final Paciente eu = (await pacientesRepo.listar()).first;
    trocarPaciente(eu);
    final Perfil deVolta = await perfilRepo.ler();
    expect(deVolta.nome, 'Eu');
    expect(deVolta.peso, 80);
  });

  test('o sufixo do banco muda com o paciente', () async {
    await garantirPacienteAtual();
    expect(sufixoPaciente(), '_p1');

    final Paciente outro =
        await pacientesRepo.salvar(const Paciente(nome: 'Outro'));
    trocarPaciente(outro);
    expect(sufixoPaciente(), '_p2');
  });
}
