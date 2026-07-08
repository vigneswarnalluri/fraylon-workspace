import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

class FirebaseNotificationRepository implements NotificationRepository {
  final FirebaseFirestore _firestore;

  FirebaseNotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('notifications');

  @override
  Stream<List<AppNotification>> watchNotifications() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppNotification.fromMap(doc.data(), doc.id);
      }).toList();
    }).handleError((error) {
      if (error is FirebaseException) {
        throw Exception(_mapFirestoreError(error));
      }
      throw Exception('Notification synchronization failed: ${error.toString()}');
    });
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    try {
      final snapshot = await _collection
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        return AppNotification.fromMap(doc.data(), doc.id);
      }).toList();
    } on FirebaseException catch (e) {
      throw Exception(_mapFirestoreError(e));
    } catch (e) {
      throw Exception('Failed to retrieve notifications: ${e.toString()}');
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await _collection.doc(id).update({'isRead': true});
    } on FirebaseException catch (e) {
      throw Exception(_mapFirestoreError(e));
    } catch (e) {
      throw Exception('Failed to update read status: ${e.toString()}');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final snapshot = await _collection.where('isRead', isEqualTo: false).get();
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw Exception(_mapFirestoreError(e));
    } catch (e) {
      throw Exception('Failed to mark all read: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      await _collection.doc(id).delete();
    } on FirebaseException catch (e) {
      throw Exception(_mapFirestoreError(e));
    } catch (e) {
      throw Exception('Failed to delete notification: ${e.toString()}');
    }
  }

  @override
  Future<void> createNotification(AppNotification notification) async {
    try {
      await _collection.doc(notification.id).set(notification.toMap());
    } on FirebaseException catch (e) {
      throw Exception(_mapFirestoreError(e));
    } catch (e) {
      throw Exception('Failed to create notification: ${e.toString()}');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      final snapshot = await _collection.get();
      if (snapshot.docs.isEmpty) return; // Nothing to clear
      
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw Exception(_mapFirestoreError(e));
    } catch (e) {
      throw Exception('Failed to clear notifications: ${e.toString()}');
    }
  }

  String _mapFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Write/read permission denied. Ensure you are authorized.';
      case 'unavailable':
        return 'Firestore database service is currently offline. Please check connection.';
      case 'not-found':
        return 'The requested notification was not found.';
      default:
        return e.message ?? 'An unexpected database error occurred.';
    }
  }
}
