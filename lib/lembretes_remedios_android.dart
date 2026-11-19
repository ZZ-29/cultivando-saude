import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'features/medications/data/alarmes_remedios.dart';
import 'features/medications/data/lembretes_remedios.dart';

/// Alarmes das doses de remédio no **Android**.
///
/// Cada horário de cada remédio vira uma notificação que **repete**:
///   • todo dia, no horário;
///   • nos dias da semana escolhidos (frequência "dias da semana");
///   • no dia do mês (frequência mensal).
///
/// **Plano B, igual ao da pressão:** pede permissão de notificação e de alarme
/// exato; se o sistema negar o exato, reagenda em modo inexato — pode atrasar
/// alguns minutos, mas toca. E ao abrir o app tudo é reagendado.
class LembretesRemediosAndroid implements LembretesRemedios {
  LembretesRemediosAndroid();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _pronto = false;

  /// Ids já agendados, para cancelar quando a lista mudar.
  final Set<int> _agendados = <int>{};

  @override
  bool get disponivel => true;

  Future<void> _iniciar() async {
    if (_pronto) return;
    tzdata.initializeTimeZones();
    try {
      final TimezoneInfo zona = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zona.identifier));
    } catch (_) {
      // mantém a zona padrão do pacote
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
    try {
      await android?.requestExactAlarmsPermission();
    } catch (_) {/* aparelhos antigos não têm */}

    _pronto = true;
  }

  static const NotificationDetails _detalhes = NotificationDetails(
    android: AndroidNotificationDetails(
      'remedios_doses',
      'Doses de remédio',
      channelDescription: 'Avisos nos horários das doses de cada remédio.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
      styleInformation: BigTextStyleInformation(''),
    ),
  );

  @override
  Future<bool> sincronizar(List<AlarmeDose> alarmes) async {
    await _iniciar();
    await desligar();
    if (alarmes.isEmpty) return true;

    bool exato = true;
    for (final AlarmeDose al in alarmes) {
      final DateTimeComponents? repeticao = _repeticao(al);
      final tz.TZDateTime quando = _proxima(al);

      final String corpo = <String>[
        '${al.nome}${al.dosagem.isEmpty ? '' : ' · ${al.dosagem}'}',
        'Toque em TOMEI no app depois de tomar.',
      ].join('\n');

      Future<void> agendar(AndroidScheduleMode modo) => _plugin.zonedSchedule(
            id: al.id,
            title: 'Hora do remédio — ${al.hhmm}',
            body: corpo,
            scheduledDate: quando,
            notificationDetails: _detalhes,
            androidScheduleMode: modo,
            matchDateTimeComponents: repeticao,
            payload: 'remedio:${al.medicamentoId}',
          );

      try {
        await agendar(AndroidScheduleMode.exactAllowWhileIdle);
      } catch (_) {
        exato = false;
        await agendar(AndroidScheduleMode.inexactAllowWhileIdle);
      }
      _agendados.add(al.id);
    }
    return exato;
  }

  /// Como a notificação se repete.
  DateTimeComponents? _repeticao(AlarmeDose al) {
    if (al.diaMes != null) return DateTimeComponents.dayOfMonthAndTime;
    if (al.diasSemana.length == 1) return DateTimeComponents.dayOfWeekAndTime;
    return DateTimeComponents.time;
  }

  /// Próxima ocorrência válida do alarme.
  tz.TZDateTime _proxima(AlarmeDose al) {
    final List<String> partes = al.hhmm.split(':');
    final int hora = int.tryParse(partes.first) ?? 8;
    final int minuto = partes.length > 1 ? (int.tryParse(partes[1]) ?? 0) : 0;

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
    // Dias da semana: avança até cair num dia ativo.
    if (al.diasSemana.isNotEmpty) {
      int guarda = 0;
      while (!al.diasSemana.contains(quando.weekday) && guarda < 8) {
        quando = quando.add(const Duration(days: 1));
        guarda++;
      }
    }
    return quando;
  }


  /// Agenda um alarme de teste para daqui a [segundos] segundos.
  ///
  /// Devolve `null` se agendou e a mensagem de erro se falhou — é o que permite
  /// a pessoa (e eu) ver **por que** o alarme não toca, em vez de adivinhar.
  @override
  Future<String?> testar({int segundos = 60}) async {
    try {
      await _iniciar();
      final tz.TZDateTime quando =
          tz.TZDateTime.now(tz.local).add(Duration(seconds: segundos));
      await _plugin.zonedSchedule(
        id: 9900,
        title: 'Teste do alarme — deu certo!',
        body: 'É assim que o aviso do remédio vai aparecer.',
        scheduledDate: quando,
        notificationDetails: _detalhes,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      return null;
    } catch (erro) {
      // Segunda tentativa, com alarme inexato (Android sem permissão exata).
      try {
        await _plugin.zonedSchedule(
          id: 9900,
          title: 'Teste do alarme — deu certo!',
          body: 'É assim que o aviso do remédio vai aparecer.',
          scheduledDate: tz.TZDateTime.now(tz.local)
              .add(Duration(seconds: segundos)),
          notificationDetails: _detalhes,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        return null;
      } catch (erro2) {
        return 'não foi possível agendar: $erro2';
      }
    }
  }

  @override
  Future<bool> notificacoesPermitidas() async {
    await _iniciar();
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final bool? ativas = await android?.areNotificationsEnabled();
    return ativas ?? true;
  }

  @override
  Future<void> desligar() async {

    await _iniciar();
    for (final int id in _agendados) {
      await _plugin.cancel(id: id);
    }
    _agendados.clear();
  }
}
