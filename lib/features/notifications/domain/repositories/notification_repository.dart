import '../models/app_notification.dart';

abstract class NotificationRepository {
  Stream<List<AppNotification>> watchNotifications();
  Future<List<AppNotification>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
  Future<void> createNotification(AppNotification notification);
  Future<void> clearAll();
}
