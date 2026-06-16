import 'package:alarm/alarm.dart';

class AlarmService {
  static Future<void> setMedicineAlarm({
    required int id,
    required String medicineName,
    required DateTime dateTime,
  }) async {
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: 'assets/alarm.wav',
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      notificationSettings: NotificationSettings(
        title: 'Medicine Reminder',
        body: 'Time to take $medicineName',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
  }

  // Stop current alarm
  static Future<void> stopAlarm(int id) async {
    await Alarm.stop(id);
  }

  // Stop every alarm
  static Future<void> stopAllAlarms() async {
    await Alarm.stopAll();
  }

  // Snooze alarm for 5 minutes
  static Future<void> snoozeAlarm({
    required int id,
    required String medicineName,
  }) async {
    await Alarm.stop(id);

    await setMedicineAlarm(
      id: id,
      medicineName: medicineName,
      dateTime: DateTime.now().add(const Duration(minutes: 5)),
    );
  }
}
