import '../models/announcement.dart';

abstract class AnnouncementRepository {
  Stream<List<Announcement>> watchAnnouncements();
  Future<List<Announcement>> getAnnouncements();
  Future<void> createAnnouncement(Announcement announcement);
  Future<void> updateAnnouncement(Announcement announcement);
  Future<void> deleteAnnouncement(String id);
}
