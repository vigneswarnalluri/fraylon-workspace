import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';

class MockAnnouncementRepository implements AnnouncementRepository {
  final _controller = StreamController<List<Announcement>>.broadcast();
  static const _announcementsKey = 'mock_announcements_data';
  List<Announcement> _announcements = [];

  MockAnnouncementRepository() {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_announcementsKey);
      if (jsonStr != null) {
        final List decoded = jsonDecode(jsonStr);
        _announcements = decoded
            .map((x) => Announcement.fromMap(x, x['id'] ?? ''))
            .toList();
      } else {
        _announcements = _getSeedAnnouncements();
        await _save();
      }
    } catch (_) {
      _announcements = _getSeedAnnouncements();
    }
    _controller.add(_announcements);
  }

  List<Announcement> _getSeedAnnouncements() {
    final now = DateTime.now();
    return [
      Announcement(
        id: 'a1',
        title: 'Fraylon Workspace Enterprise Rollout',
        description: 'Welcome to the new enterprise workspace portal! Explore tasks, calendar events, and real-time announcement filters designed to keep Fraylon teams synchronized.',
        author: 'Platform Admin',
        createdAt: now.subtract(const Duration(hours: 2)),
        priority: 'Info',
      ),
      Announcement(
        id: 'a2',
        title: 'Scheduled Database Maintenance',
        description: 'We will perform database indexing and system optimizations on Saturday from 2 AM to 4 AM EST. Live Firebase data sync may experience brief interruptions.',
        author: 'Infrastructure Team',
        createdAt: now.subtract(const Duration(days: 1)),
        priority: 'Alert',
      ),
      Announcement(
        id: 'a3',
        title: 'New Brand Identity Guidelines',
        description: 'Please refer to the updated brand book in our design systems repository for guidelines on styling corporate cards with left accent borders and premium typography colors.',
        author: 'Creative Design Lead',
        createdAt: now.subtract(const Duration(days: 2)),
        priority: 'Notice',
      ),
      Announcement(
        id: 'a4',
        title: 'Urgent Action Required: Multi-Factor Authentication',
        description: 'To maintain security standards, all users must configure Multi-Factor Authentication (MFA) in their Workspace settings page by Friday. Accounts without MFA will lose access.',
        author: 'Security Operations',
        createdAt: now.subtract(const Duration(days: 3)),
        priority: 'Urgent',
      ),
    ];
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _announcements.map((x) => x.toMap()).toList();
      await prefs.setString(_announcementsKey, jsonEncode(list));
    } catch (_) {}
  }

  @override
  Stream<List<Announcement>> watchAnnouncements() => _controller.stream;

  @override
  Future<List<Announcement>> getAnnouncements() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _announcements;
  }

  @override
  Future<void> createAnnouncement(Announcement announcement) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _announcements = [announcement, ..._announcements];
    await _save();
    _controller.add(_announcements);
  }

  @override
  Future<void> updateAnnouncement(Announcement announcement) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _announcements = _announcements
        .map((x) => x.id == announcement.id ? announcement : x)
        .toList();
    await _save();
    _controller.add(_announcements);
  }

  @override
  Future<void> deleteAnnouncement(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _announcements = _announcements.where((x) => x.id != id).toList();
    await _save();
    _controller.add(_announcements);
  }
}
