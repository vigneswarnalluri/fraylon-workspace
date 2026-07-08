import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  final _controller = StreamController<List<AppNotification>>.broadcast();
  static const _notificationsKey = 'mock_notifications_data';
  List<AppNotification> _notifications = [];

  MockNotificationRepository() {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_notificationsKey);
      if (jsonStr != null) {
        final List decoded = jsonDecode(jsonStr);
        _notifications = decoded
            .map((x) => AppNotification.fromMap(x, x['id'] ?? ''))
            .toList();
      } else {
        _notifications = _getSeedNotifications();
        await _save();
      }
    } catch (_) {
      _notifications = _getSeedNotifications();
    }
    _controller.add(_notifications);
  }

  List<AppNotification> _getSeedNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'n1',
        title: 'Security Alert: Firewall Rule Updates',
        message: 'Firewall rules for organization subnet Fraylon-Corp-US were updated at 08:30 UTC. Verify authorization log.',
        category: 'System',
        priority: 'Urgent',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: 'n2',
        title: 'New Task Assigned',
        message: 'You were assigned the task: "Upgrade Flutter engine release version". Due tomorrow, 5 PM.',
        category: 'Task',
        priority: 'High',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      AppNotification(
        id: 'n3',
        title: 'New Announcement Published',
        message: 'Creative Design Lead posted: "New Brand Identity Guidelines". Left accent border card configurations are now live.',
        category: 'Announcement',
        priority: 'Medium',
        isRead: false,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      AppNotification(
        id: 'n4',
        title: 'Workspace Build Successful',
        message: 'Fraylon Workspace Enterprise build configuration compilation and test cases passed successfully.',
        category: 'System',
        priority: 'Low',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      AppNotification(
        id: 'n5',
        title: 'Task Review Requested',
        message: 'Alex requested review on task: "Refactor enterprise organisation switcher".',
        category: 'Task',
        priority: 'High',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _notifications.map((x) => x.toMap()).toList();
      await prefs.setString(_notificationsKey, jsonEncode(list));
    } catch (_) {}
  }

  @override
  Stream<List<AppNotification>> watchNotifications() => _controller.stream;

  @override
  Future<List<AppNotification>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _notifications;
  }

  @override
  Future<void> markAsRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _notifications = _notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    await _save();
    _controller.add(_notifications);
  }

  @override
  Future<void> markAllAsRead() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    await _save();
    _controller.add(_notifications);
  }

  @override
  Future<void> deleteNotification(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _notifications = _notifications.where((n) => n.id != id).toList();
    await _save();
    _controller.add(_notifications);
  }

  @override
  Future<void> createNotification(AppNotification notification) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _notifications = [notification, ..._notifications];
    await _save();
    _controller.add(_notifications);
  }

  @override
  Future<void> clearAll() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _notifications = [];
    await _save();
    _controller.add(_notifications);
  }
}
