import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/domain/reminder.dart';
import 'package:reminder_app/features/reminders/presentation/reminder_view_models.dart';

void main() {
  group('ReminderUiText.trackingModeLabel', () {
    test('maps countdown to fixed time', () {
      expect(
        ReminderUiText.trackingModeLabel(ReminderTrackingMode.countdown),
        '固定時間',
      );
    });

    test('maps accumulation to start date', () {
      expect(
        ReminderUiText.trackingModeLabel(ReminderTrackingMode.accumulation),
        '從某天開始',
      );
    });
  });
}
