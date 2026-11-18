import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'features/pressure/data/lembretes_pressao.dart';

/// Lembretes da pressão no **Android**: repetem todos os dias nos horários
/// combinados (manhã, tarde, noite).
///
/// **Plano B para os alarmes:** este é o ponto frágil do Android. O sistema
/// pode negar o alarme exato (Android 12+, "Alarmes e lembretes" desligado) ou
/// atrasar avisos por economia de bateria. A estratégia aqui é:
///
///   1. pedir a permissão de notificação;
///   2. pedir a permissão de alarme exato;
///   3. agendar com alarme **exato**; se o sistema recusar, reagendar com
///      alarme **inexato** — pode chegar alguns minutos depois, mas chega.
///
/// Além disso, o app reagenda tudo ao abrir (ver `main.dart`): se o celular
/// reiniciar ou matar o processo, o lembrete volta.
class LembretesPressaoAndroid implements LembretesPressao {
  LembretesPressaoAndroid();

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
      // Sem a zona do aparelho, fica a padrão do pacote timezone.
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    // Sem esta permissão, o alarme exato é negado e caímos no inexato.
    try {
      await android?.requestExactAlarmsPermission();
    } catch (_) {/* aparelhos antigos não têm essa permissão */}

    _pronto = true;
  }

  static const NotificationDetails _detalhes = NotificationDetails(
    android: AndroidNotificationDetails(
      'pressao_lembretes',
      'Lembretes de pressão',
      channelDescription: 'Avisos para medir a pressão de manhã, à tarde e à noite.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
      styleInformation: BigTextStyleInformation(''),
    ),
  );

  @override
  Future<bool> ligar(List<String> horarios) async {
    await _iniciar();
    await desligar();
    if (horarios.isEmpty) return false;

    bool exato = true;
    for (final String hhmm in horarios) {
      final List<String> partes = hhmm.split(':');
      final int hora = int.tryParse(partes.first) ?? 8;
      final int minuto = partes.length > 1 ? (int.tryParse(partes[1]) ?? 0) : 0;

      try {
        await _plugin.zonedSchedule(
          id: idLembretePressao(hhmm),
          title: 'Hora de medir a pressão',
          body: '${periodoDoHorario(hhmm)} — meça, anote no app e envie ao '
              'médico pelo WhatsApp.',
          scheduledDate: _proxima(hora, minuto),
          notificationDetails: _detalhes,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {
        // Plano B: mesmo sem alarme exato, o aviso é agendado.
        exato = false;
        await _plugin.zonedSchedule(
          id: idLembretePressao(hhmm),
          title: 'Hora de medir a pressão',
          body: '${periodoDoHorario(hhmm)} — meça, anote no app e envie ao '
              'médico pelo WhatsApp.',
          scheduledDate: _proxima(hora, minuto),
          notificationDetails: _detalhes,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
    return exato;
  }

  /// Próxima ocorrência de `hora:minuto` (hoje, se ainda não passou).
  tz.TZDateTime _proxima(int hora, int minuto) {
    final tz.TZDateTime agora = tz.TZDateTime.now(tz.local);
    tz.TZDateTime quando = tz.TZDateTime(
      tz.local,
      agora.year,
      agora.month,
      agora.day,
      hora,
      minuto,
    );
    if (!quando.isAfter(agora)) {
      quando = quando.add(const Duration(days: 1));
    }
    return quando;
  }

  @override
  Future<void> desligar() async {
    await _iniciar();
    for (final String hhmm in horariosPadraoPressao) {
      await _plugin.cancel(id: idLembretePressao(hhmm));
    }
    // Cancela também os que ficaram de horários fora do padrão.
    for (int i = 0; i < 3; i++) {
      await _plugin.cancel(id: 9100 + i);
    }
  }
}
