import 'package:workmanager/workmanager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logging/logger_service.dart';
import 'notification_service.dart';

// Background task callback — runs in an isolate so must be self-contained.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Boot a minimal DB + service stack without full Riverpod context.
    // The ProviderContainer gives us full service graph with DI.
    final container = ProviderContainer();
    try {
      final notificationService = container.read(notificationServiceProvider);

      switch (task) {
        case 'dailyDigestTask':
          await notificationService.sendDailyDigest();
          break;
        case 'weeklyReviewTask':
          await notificationService.sendWeeklyReview();
          break;
        case 'priceCheckTask':
          await notificationService.checkPriceAlerts();
          break;
        case 'systematicPlanCheckTask':
          await notificationService.checkSystematicPlanReminders();
          break;
        case 'dailyRemindersTask':
          await notificationService.checkFdMaturityReminders();
          await notificationService.checkInsurancePremiumReminders();
          await notificationService.checkRentDueReminders();
          await notificationService.checkNewsAlerts();
          break;
      }
    } catch (e, st) {
      logger.e('Background task "$task" failed', e, st);
    } finally {
      container.dispose();
    }
    return Future.value(true);
  });
}
