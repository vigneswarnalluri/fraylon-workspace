import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';

class FirebaseAnnouncementRepository implements AnnouncementRepository {
  final FirebaseFirestore _firestore;

  FirebaseAnnouncementRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('announcements');

  @override
  Stream<List<Announcement>> watchAnnouncements() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Announcement.fromMap(doc.data(), doc.id);
      }).toList();
    }).handleError((error) {
      if (error is FirebaseException) {
        throw Exception(_mapFirestoreError(error));
      }
      throw Exception('Announcement synchronization failed: ${error.toString()}');
    });
  }

  @override
  Future<List<Announcement>> getAnnouncements() async {
    try {
      final snapshot = await _collection
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        return Announcement.fromMap(doc.data(), doc.id);
      }).toList();
    } on FirebaseException catch (e) {
      throw Exception(_mapFirestoreError(e));
    } catch (e) {
      throw Exception('Failed to retrieve announcements: ${e.toString()}');
    }
  }

  @override
  Future<void> createAnnouncement(Announcement announcement) async {
    try {
      await _collection.doc(announcement.id).set(announcement.toMap());
    } on FirebaseException catch (e) {
      throw Exception(_mapFirestoreError(e));
    } catch (e) {
      throw Exception('Failed to publish announcement: ${e.toString()}');
    }
  }

  @override
  Future<void> updateAnnouncement(Announcement announcement) async {
    try {
      await _collection.doc(announcement.id).update(announcement.toMap());
    } on FirebaseException catch (e) {
      throw Exception(_mapFirestoreError(e));
    } catch (e) {
      throw Exception('Failed to update announcement: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAnnouncement(String id) async {
    try {
      await _collection.doc(id).delete();
    } on FirebaseException catch (e) {
      throw Exception(_mapFirestoreError(e));
    } catch (e) {
      throw Exception('Failed to delete announcement: ${e.toString()}');
    }
  }

  String _mapFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Write/read permission denied. Ensure you are authorized.';
      case 'unavailable':
        return 'Firestore database service is currently offline. Please check connection.';
      case 'not-found':
        return 'The requested announcement was not found.';
      default:
        return e.message ?? 'An unexpected database error occurred.';
    }
  }
}
