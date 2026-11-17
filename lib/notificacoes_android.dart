import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'features/agenda/domain/aviso.dart';
import 'features/agenda/domain/compromisso.dart';
import 'features/agenda/data/notificacoes.dart';

/// Avisos de compromisso no **Android**, via `flutter_local_notifications`.
///
/// Dois alarmes por compromisso: **1 hora antes** e **30 minutos antes**,
/// com som e vibração, mesmo com a tela apagada.
///
/// Detalhes que importam num app para 70+:
///   • alarme **exato** (`exactAllowWhileIdle`) — não "por volta de";
///   • o texto diz o que é, a hora e onde: "Consulta às 15:00 — em 1 hora";
///   • ao remover ou editar o compromisso, os avisos antigos são cancelados.
class NotificacoesAndroid implements NotificacoesCompromissos {
  NotificacoesAndroid();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _pronto = false;

  @override
  bool get disponivel => true;

  Future<void> _iniciar() async {
    if (_pronto) return;

    tzdata.initializeTimeZones();
    try {
      final TimezoneInfo zona = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zona.identifier));
    } catch (_) {
      // Sem a zona do aparelho, cai no fuso do sistema pelo `tz.local`.
    }

    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: android),
    );

    // Android 13+: permissão de notificação.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _pronto = true;
  }

  static NotificationDetails get _detalhes => const NotificationDetails(
        android: AndroidNotificationDetails(
          'agenda_compromissos',
          'Agenda de consultas e exames',
          channelDescription:
              'Avisos de consultas e exames, 1 hora e 30 minutos antes.',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.reminder,
          styleInformation: BigTextStyleInformation(''),
        ),
      );

  @override
  Future<void> agendar(Compromisso compromisso) async {
    final int? id = compromisso.id;
    if (id == null) return;
    await _iniciar();
    await cancelar(compromisso);

    final String hora =
        '${compromisso.quando.hour.toString().padLeft(2, '0')}:'
        '${compromisso.quando.minute.toString().padLeft(2, '0')}';

    for (final Aviso aviso in avisosFuturosDo(compromisso)) {
      final String quando = aviso.minutosAntes >= 60
          ? 'em 1 hora'
          : 'em 30 minutos';
      final String titulo = compromisso.tipo == TipoCompromisso.exame
          ? 'Exame $quando'
          : 'Consulta $quando';

      // O corpo leva o **endereço**: o aviso tem que servir para sair de casa
      // já sabendo para onde ir. Quem perde consulta é quem tem a hora e não
      // tem o lugar.
      final String corpo = <String>[
        '${compromisso.titulo} — às $hora',
        if (compromisso.local.trim().isNotEmpty) compromisso.local.trim(),
        if (compromisso.temEndereco) '📍 ${compromisso.endereco.trim()}',
      ].join('\n');

      await _plugin.zonedSchedule(
        id: idAviso(id, aviso.minutosAntes),
        title: titulo,
        body: corpo,
        scheduledDate: tz.TZDateTime.from(aviso.quando, tz.local),
        notificationDetails: _detalhes,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'compromisso:$id',
      );
    }
  }

  @override
  Future<void> cancelar(Compromisso compromisso) async {
    final int? id = compromisso.id;
    if (id == null) return;
    await _iniciar();
    for (final int minutos in <int>[60, 30]) {
      await _plugin.cancel(id: idAviso(id, minutos));
    }
  }
}
